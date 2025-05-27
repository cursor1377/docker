# 使用 Alpine 作为基础镜像
FROM --platform=${TARGETPLATFORM} alpine:latest
LABEL maintainer="V2Fly Community <dev@v2fly.org>"

# 设置工作目录，v2ray.sh 会在此目录操作
WORKDIR /tmp
ARG WORKDIR=/tmp # v2ray.sh 脚本可能会使用此变量
ARG TARGETPLATFORM
ARG TAG=v5.15.0 # <--- 在这里添加一个默认的 V2Ray 版本号

# 复制脚本和 V2Ray 配置文件到工作目录
# config.json 将由 v2ray.sh 移动到 /etc/v2ray/
COPY config.json "${WORKDIR}"/config.json
COPY v2ray.sh "${WORKDIR}"/v2ray.sh

# 以 root 用户执行以下操作：
# 1. 安装必要的包 (ca-certificates)
# 2. 创建 V2Ray 需要的目录结构
# 3. 创建日志文件的软链接到标准输出/错误
# 4. 给 v2ray.sh 添加执行权限
# 5. 执行 v2ray.sh 脚本以下载和安装 V2Ray
#    v2ray.sh 会将 v2ray 执行文件放到 /usr/bin/，配置文件到 /etc/v2ray/ 等
RUN set -ex \
    && apk add --no-cache ca-certificates \
    && mkdir -p /etc/v2ray /usr/local/share/v2ray /var/log/v2ray \
    && ln -sf /dev/stdout /var/log/v2ray/access.log \
    && ln -sf /dev/stderr /var/log/v2ray/error.log \
    && chmod +x "${WORKDIR}"/v2ray.sh \
    && "${WORKDIR}"/v2ray.sh "${TARGETPLATFORM}" "${TAG}" # TAG 将会是 v5.15.0

# 创建一个非 root 用户，UID 在 Choreo 推荐的范围内 (10000-20000)
# 这里我们使用 choreo 官方示例中的 UID 10014 和用户名 choreo
# 您也可以选择自己的用户名和该范围内的 UID
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid 10014 \
    "choreo"

# 将 V2Ray 相关目录和文件的所有权更改为新创建的非 root 用户
# 这些文件和目录是由上面的 RUN 指令（以 root 身份运行 v2ray.sh）创建的
RUN chown -R choreo:choreo /etc/v2ray \
    && chown -R choreo:choreo /usr/local/share/v2ray \
    && chown -R choreo:choreo /var/log/v2ray \
    && chown choreo:choreo /usr/bin/v2ray
# v2ray.sh 内部已经对 /usr/bin/v2ray 做了 chmod +x

# 切换到非 root 用户来运行后续指令和容器的入口点
USER choreo
# 或者使用 UID: USER 10014

# 设置 V2Ray 程序的入口点
ENTRYPOINT ["/usr/bin/v2ray"]
