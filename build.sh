#!/bin/bash -e

for i in "$@"
    do
        case $i in
        --arch=*)
            ARCH="${i#*=}"
        ;;
        --version=*)
            VERSION="${i#*=}"
        ;;
        --tagversion=*)
            TAG_VERSION="${i#*=}"
        ;;
        --qemuarch=*)
            QEMU_ARCH="${i#*=}"
        ;;
        --dockerarchbase=*)
            DOCKER_ARCH_BASE="${i#*=}"
        ;;
        --qemuversion=*)
            QEMU_VER="${i#*=}"
        ;;
        --repo=*)
            DOCKER_REPO="${i#*=}"
        ;;
        *)
        # unknown option
        ;;
    esac
done

# install qemu-user-static
if [ -n "${QEMU_ARCH}" ]; then
    if [ ! -f x86_64_qemu-${QEMU_ARCH}-static.tar.gz ]; then
        wget -N https://github.com/multiarch/qemu-user-static/releases/download/${QEMU_VER}/x86_64_qemu-${QEMU_ARCH}-static.tar.gz
    fi
    tar -xvf x86_64_qemu-${QEMU_ARCH}-static.tar.gz -C $ROOTFS/usr/bin/
fi

docker build --build-arg imagearch="${DOCKER_ARCH_BASE}" --build-arg dispatch_version="${VERSION}" -t "${DOCKER_REPO}:${ARCH}-${TAG_VERSION}" ./