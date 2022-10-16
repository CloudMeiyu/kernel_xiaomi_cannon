#!/bin/sh

# Setup the build environment
if command -v apt &> /dev/null; then
    git clone --depth=1 https://github.com/akhilnarang/scripts environment
    cd environment && bash setup/android_build_env.sh && cd ..
else
    echo "apt is not present in your system"
    echo "The needed packages must be installed manually"
fi

# Clone proton clang from its repo
git clone --depth=1 https://github.com/kdrag0n/proton-clang.git proton-clang

# Clone AnyKernel3
git clone --depth=1 -b cannon https://github.com/Couchpotato-sauce/AnyKernel3 AnyKernel3

# Export the PATH variable
export PATH="$(pwd)/proton-clang/bin:$PATH"

# Remove out/ directory
rm -r out/arch/arm64/boot/

# Compile the kernel
build_clang() {
    make -j"$(nproc --all)" \
	O=out \
    CC="clang" \
    CXX="clang++" \
    AR="llvm-ar" \
    AS="llvm-as" \
    NM="llvm-nm" \
    LD="ld.lld" \
    STRIP="llvm-strip" \
    OBJCOPY="llvm-objcopy" \
    OBJDUMP="llvm-objdump"\
    OBJSIZE="llvm-size" \
    READELF="llvm-readelf" \
	CROSS_COMPILE=aarch64-linux-gnu- \
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

export ARCH=arm64
make O=out cannon_user_defconfig
build_clang

# Zip up the kernel
zip_kernelimage() {
    rm -rf AnyKernel3/Image.gz
    cp out/arch/arm64/boot/Image.gz AnyKernel3
    rm -rf AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3
    KERNEL_NAME=Sleepy-"${BUILD_TIME}"
    zip -r9 "$KERNEL_NAME".zip ./*
    cd ..
}

FILE="$(pwd)/out/arch/arm64/boot/Image.gz"
if [ -f "$FILE" ]; then
    zip_kernelimage
    KERN_FINAL="$(pwd)/AnyKernel3/"$KERNEL_NAME".zip"
    echo "The kernel has successfully been compiled and can be found in $KERN_FINAL"
else
    echo "The kernel has failed to compile. Please check the terminal output for further details."
    exit 1
fi
