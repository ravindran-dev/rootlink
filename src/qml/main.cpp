#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QScreen>
#include <QClipboard>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMimeData>
#include <QObject>
#include <QProcess>
#include <QUrl>
#include <QVariant>

class FileOps : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

    Q_INVOKABLE bool copyToClipboard(const QVariantList &paths, bool cut)
    {
        QClipboard *clipboard = QGuiApplication::clipboard();
        if (!clipboard) {
            return false;
        }

        QList<QUrl> urls;
        QStringList uriLines;

        for (const QVariant &pathValue : paths) {
            const QString path = localPath(pathValue.toString());
            if (path.isEmpty()) {
                continue;
            }

            const QUrl url = QUrl::fromLocalFile(path);
            urls.append(url);
            uriLines.append(url.toString());
        }

        if (urls.isEmpty()) {
            return false;
        }

        auto *mimeData = new QMimeData();
        mimeData->setUrls(urls);
        mimeData->setText(uriLines.join(QLatin1Char('\n')));

        QStringList gnomeLines;
        gnomeLines.append(cut ? QStringLiteral("cut") : QStringLiteral("copy"));
        gnomeLines.append(uriLines);
        mimeData->setData(
            QStringLiteral("x-special/gnome-copied-files"),
            gnomeLines.join(QLatin1Char('\n')).toUtf8()
        );

        clipboard->setMimeData(mimeData);
        return true;
    }

    Q_INVOKABLE QStringList clipboardFilePaths() const
    {
        QStringList paths;
        const QClipboard *clipboard = QGuiApplication::clipboard();
        if (!clipboard) {
            return paths;
        }

        const QMimeData *mimeData = clipboard->mimeData();
        if (!mimeData) {
            return paths;
        }

        if (mimeData->hasFormat(QStringLiteral("x-special/gnome-copied-files"))) {
            const QString data = QString::fromUtf8(
                mimeData->data(QStringLiteral("x-special/gnome-copied-files"))
            );
            const QStringList lines = data.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            for (int i = 1; i < lines.size(); ++i) {
                const QString path = localPath(lines.at(i).trimmed());
                if (!path.isEmpty()) {
                    paths.append(path);
                }
            }
            if (!paths.isEmpty()) {
                return paths;
            }
        }

        if (mimeData->hasUrls()) {
            const QList<QUrl> urls = mimeData->urls();
            for (const QUrl &url : urls) {
                if (url.isLocalFile()) {
                    paths.append(url.toLocalFile());
                }
            }
            if (!paths.isEmpty()) {
                return paths;
            }
        }

        const QStringList textLines = mimeData->text().split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : textLines) {
            const QString path = localPath(line.trimmed());
            if (!path.isEmpty() && QFileInfo::exists(path)) {
                paths.append(path);
            }
        }

        return paths;
    }

    Q_INVOKABLE QString clipboardMode() const
    {
        const QClipboard *clipboard = QGuiApplication::clipboard();
        if (!clipboard) {
            return QStringLiteral("copy");
        }

        const QMimeData *mimeData = clipboard->mimeData();
        if (!mimeData) {
            return QStringLiteral("copy");
        }

        if (!mimeData->hasFormat(QStringLiteral("x-special/gnome-copied-files"))) {
            return QStringLiteral("copy");
        }

        const QString data = QString::fromUtf8(
            mimeData->data(QStringLiteral("x-special/gnome-copied-files"))
        );
        const QString firstLine = data.section(QLatin1Char('\n'), 0, 0).trimmed();
        return firstLine == QStringLiteral("cut")
            ? QStringLiteral("cut")
            : QStringLiteral("copy");
    }

    Q_INVOKABLE bool hasClipboardFiles() const
    {
        return !clipboardFilePaths().isEmpty();
    }

    Q_INVOKABLE QString uniquePath(const QString &parentPath, const QString &fileName)
    {
        const QString localParentPath = localPath(parentPath);
        if (localParentPath.isEmpty() || fileName.isEmpty() || fileName.contains('/')) {
            return QString();
        }

        QDir parent(localParentPath);
        QString candidate = parent.absoluteFilePath(fileName);
        if (!QFileInfo::exists(candidate)) {
            return candidate;
        }

        const QFileInfo info(fileName);
        const QString base = info.completeBaseName().isEmpty()
            ? fileName
            : info.completeBaseName();
        const QString suffix = info.suffix();

        for (int index = 2; index < 10000; ++index) {
            const QString numberedName = suffix.isEmpty()
                ? QStringLiteral("%1 copy %2").arg(base).arg(index)
                : QStringLiteral("%1 copy %2.%3").arg(base).arg(index).arg(suffix);
            candidate = parent.absoluteFilePath(numberedName);
            if (!QFileInfo::exists(candidate)) {
                return candidate;
            }
        }

        return QString();
    }

    Q_INVOKABLE bool copyItem(const QString &sourcePath, const QString &targetPath)
    {
        const QString localSourcePath = localPath(sourcePath);
        const QString localTargetPath = localPath(targetPath);
        if (localSourcePath.isEmpty() || localTargetPath.isEmpty() || localSourcePath == localTargetPath) {
            return false;
        }

        const QFileInfo sourceInfo(localSourcePath);
        if (!sourceInfo.exists()) {
            return false;
        }

        if (sourceInfo.isDir()) {
            return copyDirectory(localSourcePath, localTargetPath);
        }

        QDir().mkpath(QFileInfo(localTargetPath).absolutePath());
        return QFile::copy(localSourcePath, localTargetPath);
    }

    Q_INVOKABLE bool moveItem(const QString &sourcePath, const QString &targetPath)
    {
        const QString localSourcePath = localPath(sourcePath);
        const QString localTargetPath = localPath(targetPath);
        if (localSourcePath.isEmpty() || localTargetPath.isEmpty() || localSourcePath == localTargetPath) {
            return false;
        }

        QDir().mkpath(QFileInfo(localTargetPath).absolutePath());
        if (QDir().rename(localSourcePath, localTargetPath)) {
            return true;
        }

        if (!copyItem(localSourcePath, localTargetPath)) {
            return false;
        }

        const QFileInfo sourceInfo(localSourcePath);
        return sourceInfo.isDir()
            ? QDir(localSourcePath).removeRecursively()
            : QFile::remove(localSourcePath);
    }

    Q_INVOKABLE bool renameItem(const QString &path, const QString &newName)
    {
        if (path.isEmpty() || newName.isEmpty() || newName.contains('/')) {
            return false;
        }

        const QFileInfo info(path);
        const QString target = info.dir().absoluteFilePath(newName);
        return QDir().rename(path, target);
    }

    Q_INVOKABLE bool createFolder(const QString &parentPath, const QString &name)
    {
        if (parentPath.isEmpty() || name.isEmpty() || name.contains('/')) {
            return false;
        }

        QDir dir(parentPath);
        return dir.mkpath(name);
    }

    Q_INVOKABLE bool moveToTrash(const QString &path)
    {
        if (path.isEmpty()) {
            return false;
        }

        const int code = QProcess::execute(QStringLiteral("gio"), {
            QStringLiteral("trash"),
            path
        });
        return code == 0;
    }

private:
    QString localPath(const QString &path) const
    {
        const QUrl url(path);
        return url.isLocalFile() ? url.toLocalFile() : path;
    }

    bool copyDirectory(const QString &sourcePath, const QString &targetPath)
    {
        QDir sourceDir(sourcePath);
        if (!sourceDir.exists()) {
            return false;
        }

        QDir targetDir(targetPath);
        if (!targetDir.exists() && !QDir().mkpath(targetPath)) {
            return false;
        }

        const QFileInfoList entries = sourceDir.entryInfoList(
            QDir::NoDotAndDotDot | QDir::AllEntries | QDir::Hidden | QDir::System
        );

        for (const QFileInfo &entry : entries) {
            const QString sourceEntryPath = entry.absoluteFilePath();
            const QString targetEntryPath = targetDir.absoluteFilePath(entry.fileName());

            if (entry.isDir()) {
                if (!copyDirectory(sourceEntryPath, targetEntryPath)) {
                    return false;
                }
            } else if (!QFile::copy(sourceEntryPath, targetEntryPath)) {
                return false;
            }
        }

        return true;
    }
};

int main(int argc, char *argv[])
{
    // Prefer Wayland by default, while still allowing callers/tests to override it.
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "wayland");
    }

    QGuiApplication app(argc, argv);

    // Set application metadata
    app.setApplicationName("Rootlink");
    app.setApplicationVersion("1.0.0");
    app.setApplicationDisplayName("File Manager");
    app.setWindowIcon(QIcon(":/icons/rootlink.svg"));

    // Create QML engine
    QQmlApplicationEngine engine;

    // Set context properties that can be accessed from QML
    QQmlContext *rootContext = engine.rootContext();
    const QString defaultHomePath = QStringLiteral("/home/ravi");
    const QString initialPath = argc > 1
        ? QDir::cleanPath(QString::fromLocal8Bit(argv[1]))
        : defaultHomePath;
    rootContext->setContextProperty("initialPath", initialPath);
    rootContext->setContextProperty("homePath", defaultHomePath);
    rootContext->setContextProperty("userName", QString::fromLocal8Bit(qgetenv("USER")));
    FileOps fileOps;
    rootContext->setContextProperty("fileOps", &fileOps);
    
    // Add filesystem bridge
    // rootContext->setContextProperty("fileSystemBridge", ...);
    
    // Add theme bridge
    // rootContext->setContextProperty("themeBridge", ...);

    // Load main QML file
    engine.addImportPath(":/qml");
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));

    engine.load(url);
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        return -1;
    }

    return app.exec();
}

#include "main.moc"
