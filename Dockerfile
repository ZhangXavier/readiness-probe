FROM alpine

# 安装必要的工具：
# - bash: wait-for-it.sh 脚本需要 bash 环境运行
# - ca-certificates: 提供 SSL/TLS 证书，如果目标服务使用 HTTPS 则需要
# - curl: 用于进行 HTTP 请求检查目标服务的健康状态
RUN apk add --no-cache bash ca-certificates curl

# 设置工作目录，后续操作都在此目录下进行
WORKDIR /app

ENV WAIT_FOR_IT_VERSION "81b1373f17855a4dc21156cfe1694c31d7d1792e"
ENV WAIT_FOR_IT_SHA256 "b7a04f38de1e51e7455ecf63151c8c7e405bd2d45a2d4e16f6419db737a125d6"

RUN set -x \
    && curl -fL "https://raw.githubusercontent.com/vishnubob/wait-for-it/${WAIT_FOR_IT_VERSION}/wait-for-it.sh" -o /usr/local/bin/wait-for-it.sh \
    && echo "${WAIT_FOR_IT_SHA256} /usr/local/bin/wait-for-it.sh" | sha256sum -c - \
    && chmod +x /usr/local/bin/wait-for-it.sh

# 复制通用的健康检查脚本到容器内部
COPY check_service_ready.sh /app/check_service_ready.sh
# 确保健康检查脚本是可执行的
RUN chmod +x /app/check_service_ready.sh

# 定义容器启动后执行的默认命令。
# 容器本身只作为健康检查的“探针”，不需要运行特定应用。
CMD ["sleep", "infinity"]
