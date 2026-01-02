# 阶段1：构建阶段
FROM golang:1.21-alpine AS builder

# 传入构建参数（和YAML中的端口/环境保持一致）
ARG APP_ENV=dev
ARG APP_NAME=go-mqtt-adapter
ARG CONTAINER_PORT=50002
ARG BINARY_NAME=${APP_NAME}-${APP_ENV}

WORKDIR /app
# 先下载依赖（利用缓存）
COPY src/go.mod src/go.sum* ./
RUN go mod download

# 复制源码并构建（注入环境和版本信息）
COPY src/ .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
  -ldflags="-s -w -X main.env=${APP_ENV} -X main.version=${APP_VERSION:-unknown}" \
  -o ${BINARY_NAME} main.go

# 阶段2：运行阶段（轻量级镜像）
FROM alpine:latest

# 安装基础依赖（证书、时区）
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Shanghai

# 传入构建参数到运行时
ARG APP_ENV=dev
ARG APP_NAME=go-mqtt-adapter
ARG CONTAINER_PORT=50002
ARG BINARY_NAME=${APP_NAME}-${APP_ENV}
ENV APP_ENV=${APP_ENV}
ENV BINARY_NAME=${BINARY_NAME}
ENV CONTAINER_PORT=${CONTAINER_PORT}

# 核心：在容器内创建deployer用户（和宿主机用户名一致）
RUN addgroup -S deployer && adduser -S deployer -G deployer \
  # 创建应用目录并赋予deployer权限
  && mkdir -p /app /var/log/${APP_NAME} \
  && chown -R deployer:deployer /app /var/log/${APP_NAME}

# 声明端口（和YAML中的容器端口一致）
EXPOSE ${CONTAINER_PORT}

# 切换工作目录
WORKDIR /app
# 从构建阶段复制二进制文件，并修改权限
COPY --from=builder /app/${BINARY_NAME} ./
RUN chmod +x ./${BINARY_NAME}

# 切换到deployer用户（非root）
USER deployer:deployer

# 启动应用（日志输出到指定目录）
CMD ["/bin/sh", "-c", "./${BINARY_NAME} > /var/log/${BINARY_NAME}.log 2>&1"]
