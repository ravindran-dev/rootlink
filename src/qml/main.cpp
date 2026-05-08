#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QScreen>
#include <QDir>
#include <QFileInfo>
#include <QObject>
#include <QProcess>

class FileOps : public QObject
{
    Q_OBJECT

public:
    using QObject::QObject;

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
    const QString initialPath = argc > 1
        ? QDir::cleanPath(QString::fromLocal8Bit(argv[1]))
        : QDir::homePath();
    rootContext->setContextProperty("initialPath", initialPath);
    rootContext->setContextProperty("homePath", QDir::homePath());
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
