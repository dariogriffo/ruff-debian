ruff_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$ruff_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <ruff_version> <build_version> [architecture]"
    echo "Example: $0 0.8.11 1 arm64"
    echo "Example: $0 0.8.11 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armel, armhf, ppc64el, s390x, riscv64, i386, all"
    exit 1
fi

# Function to map Debian architecture to ruff release name
get_ruff_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "ruff-x86_64-unknown-linux-musl"
            ;;
        "arm64")
            echo "ruff-aarch64-unknown-linux-musl"
            ;;
        "armel")
            echo "ruff-arm-unknown-linux-musleabihf"
            ;;
        "armhf")
            echo "ruff-armv7-unknown-linux-musleabihf"
            ;;
        "ppc64el")
            echo "ruff-powerpc64le-unknown-linux-gnu"
            ;;
        "s390x")
            echo "ruff-s390x-unknown-linux-gnu"
            ;;
        "riscv64")
            echo "ruff-riscv64gc-unknown-linux-gnu"
            ;;
        "i386")
            echo "ruff-i686-unknown-linux-musl"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local ruff_release
    
    ruff_release=$(get_ruff_release "$build_arch")
    if [ -z "$ruff_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, armel, armhf, ppc64el, s390x, riscv64, i386"
        return 1
    fi
    
    echo "Building for architecture: $build_arch using $ruff_release"
    
    # Clean up any previous builds for this architecture
    rm -rf "$ruff_release" || true
    rm -f "${ruff_release}.tar.gz" || true
    
    # Download and extract ruff binary for this architecture
    if ! wget "https://github.com/astral-sh/ruff/releases/download/${ruff_VERSION}/${ruff_release}.tar.gz"; then
        echo "❌ Failed to download ruff binary for $build_arch"
        return 1
    fi
    
    if ! tar -xf "${ruff_release}.tar.gz"; then
        echo "❌ Failed to extract ruff binary for $build_arch"
        return 1
    fi
    
    rm -f "${ruff_release}.tar.gz"
    
    # Build packages for appropriate Debian distributions
    # riscv64 is only supported in trixie (v13) and later, not in bookworm (v12)
    if [ "$build_arch" = "riscv64" ]; then
        declare -a arr=("trixie" "forky" "sid")
    else
        declare -a arr=("bookworm" "trixie" "forky" "sid")
    fi
    
    for dist in "${arr[@]}"; do
        FULL_VERSION="$ruff_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"
        
        if ! docker build . -t "ruff-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg ruff_VERSION="$ruff_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg RUFF_RELEASE="$ruff_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi
        
        id="$(docker create "ruff-$dist-$build_arch")"
        if ! docker cp "$id:/ruff_$FULL_VERSION.deb" - > "./ruff_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi
        
        if ! tar -xf "./ruff_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done
    
    # Clean up extracted directory
    rm -rf "$ruff_release" || true
    
    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building ruff $ruff_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""
    
    # All supported architectures
    ARCHITECTURES=("amd64" "arm64" "armel" "armhf" "ppc64el" "s390x" "riscv64" "i386")
    
    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="
        
        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi
        
        echo ""
    done
    
    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la ruff_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi