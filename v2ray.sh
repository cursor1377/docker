#!/bin/sh

# Set ARG
PLATFORM=$1
TAG=$2
if [ -z "$PLATFORM" ]; then
    ARCH="64"
else
    case "$PLATFORM" in
        linux/386)
            ARCH="32"
            ;;
        linux/amd64)
            ARCH="64"
            ;;
        linux/arm/v6)
            ARCH="arm32-v6"
            ;;
        linux/arm/v7)
            ARCH="arm32-v7a"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="arm64-v8a"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1

# Download files
V2RAY_FILE="v2ray-linux-${ARCH}.zip"
DGST_FILE="v2ray-linux-${ARCH}.zip.dgst"
echo "Downloading binary file: ${V2RAY_FILE}"
echo "Downloading binary file: ${DGST_FILE}"

wget -O ${PWD}/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${V2RAY_FILE} # Removed > /dev/null 2>&1 for better debug
wget -O ${PWD}/v2ray.zip.dgst https://github.com/v2fly/v2ray-core/releases/download/${TAG}/${DGST_FILE} # Removed > /dev/null 2>&1 for better debug

if [ $? -ne 0 ]; then
    echo "Error: Failed to download binary file: ${V2RAY_FILE} ${DGST_FILE}" && exit 1
fi
echo "Download binary file: ${V2RAY_FILE} ${DGST_FILE} completed"

# Check SHA512
V2RAY_ZIP_HASH=$(sha512sum v2ray.zip | cut -f1 -d' ')
V2RAY_ZIP_DGST_HASH=$(cat v2ray.zip.dgst | grep -e 'SHA512' -e 'SHA2-512' | head -n1 | cut -f2 -d' ')

if [ "${V2RAY_ZIP_HASH}" = "${V2RAY_ZIP_DGST_HASH}" ]; then
    echo " Check passed" && rm -fv v2ray.zip.dgst
else
    echo "V2RAY_ZIP_HASH: ${V2RAY_ZIP_HASH}"
    echo "V2RAY_ZIP_DGST_HASH: ${V2RAY_ZIP_DGST_HASH}"
    echo " Check have not passed yet " && exit 1
fi

# Prepare
echo "Prepare to use"
unzip v2ray.zip && chmod +x v2ray
mv v2ray /usr/bin/
mv geosite.dat geoip.dat /usr/local/share/v2ray/
mv config.json /etc/v2ray/config.json # This moves the config.json copied to WORKDIR by Dockerfile

# 移除之前为 Choreo 添加的 USER/GROUP 创建和 CHOWN 命令，这些已移至 Dockerfile
# V2RAY_USER_UID=10001 ... (删除这些行)
# addgroup ... (删除这些行)
# adduser ... (删除这些行)
# chown ... (删除这些行)

# Clean
rm -rf ${PWD}/*
echo "Done"
