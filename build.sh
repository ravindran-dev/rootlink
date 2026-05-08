#!/bin/bash
# Rootlink build script

set -e

echo "🔨 Building Rootlink File Manager..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

if ! command -v cargo &> /dev/null; then
    echo -e "${RED}❌ Rust/Cargo not found. Please install Rust:${NC}"
    echo "https://rustup.rs/"
    exit 1
fi

if ! command -v cmake &> /dev/null; then
    echo -e "${RED}❌ CMake not found. Please install CMake.${NC}"
    exit 1
fi

if ! pkg-config --exists Qt6Core; then
    echo -e "${RED}❌ Qt6 not found. Please install Qt6 development files.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites found${NC}"

# Create build directory
echo -e "${YELLOW}📁 Creating build directory...${NC}"
mkdir -p build
cd build

# Configure CMake
echo -e "${YELLOW}🔧 Configuring CMake...${NC}"
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..

# Build
echo -e "${YELLOW}⚙️  Building...${NC}"
cmake --build . --config Release

echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "${YELLOW}📍 Output: ./build/rootlink${NC}"
echo -e "${YELLOW}🚀 Run with: ./build/rootlink${NC}"
echo -e "${YELLOW}🖥️  Install launcher with: ./install-local.sh${NC}"
