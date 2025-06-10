#!/bin/bash

# --- 必填环境变量 ---
# TARGET_URL: 目标服务的完整 URL (例如: http://gitea.example.com:3000)
# TARGET_HOST: 目标服务的主机名或 IP (例如: gitea.example.com 或 172.17.0.1)
# TARGET_PORT: 目标服务的端口 (例如: 3000 或 80)
# CHECK_TYPE: 检查类型，可以是 'TCP' 或 'HTTP'
# --- 可选环境变量 ---
# HTTP_PATH: 如果 CHECK_TYPE 是 HTTP，指定要检查的路径 (默认: /)

# 校验核心环境变量
if [ -z "$TARGET_URL" ] || [ -z "$TARGET_HOST" ] || [ -z "$TARGET_PORT" ] || [ -z "$CHECK_TYPE" ]; then
    echo "Error: Missing required environment variables. Please set TARGET_URL, TARGET_HOST, TARGET_PORT, and CHECK_TYPE."
    exit 1
fi

# 设置 HTTP 检查路径，如果未指定则默认为根路径
HTTP_PATH=${HTTP_PATH:-/}

echo "Starting generic service readiness check:"
echo "  Target URL: $TARGET_URL"
echo "  Target Host: $TARGET_HOST"
echo "  Target Port: $TARGET_PORT"
echo "  Check Type: $CHECK_TYPE"
if [ "$CHECK_TYPE" == "HTTP" ]; then
    echo "  HTTP Path: $HTTP_PATH"
fi

# 确保 wait-for-it.sh 可执行且存在
if [ ! -f "/usr/local/bin/wait-for-it.sh" ]; then
    echo "Error: wait-for-it.sh not found at /usr/local/bin/wait-for-it.sh"
    exit 1
fi

# --- 执行检查逻辑 ---

# 1. 总是先使用 wait-for-it.sh 检查 TCP 端口连通性
echo "Attempting to reach TCP port: $TARGET_HOST:$TARGET_PORT"
if ! /usr/local/bin/wait-for-it.sh "$TARGET_HOST:$TARGET_PORT" --timeout=30 --strict -- echo "Target service TCP port is open."; then
    echo "TCP port check failed for $TARGET_HOST:$TARGET_PORT."
    exit 1 # 健康检查失败
fi

# 2. 根据 CHECK_TYPE 执行后续检查
if [ "$CHECK_TYPE" == "HTTP" ]; then
    echo "TCP port is open. Now checking HTTP readiness at ${TARGET_URL}${HTTP_PATH}"
    # 使用 curl 检查 HTTP 状态码
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --retry 5 --retry-delay 3 "${TARGET_URL}${HTTP_PATH}")

    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
        echo "Service is healthy (HTTP $HTTP_CODE)."
        exit 0 # 健康检查通过
    else
        echo "Service is not healthy (HTTP $HTTP_CODE). Retrying next healthcheck interval..."
        exit 1 # 健康检查失败
    fi
elif [ "$CHECK_TYPE" == "TCP" ]; then
    echo "Service is healthy (TCP port is open)."
    exit 0 # 仅 TCP 检查通过即认为健康
else
    echo "Error: Unsupported CHECK_TYPE '$CHECK_TYPE'. Must be 'TCP' or 'HTTP'."
    exit 1
fi
