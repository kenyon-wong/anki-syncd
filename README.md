# Anki 同步服务器 Docker 镜像

基于 Rust 实现的 Anki 自托管同步服务器 Docker 镜像，支持最新版本的 Anki 客户端。

## 功能特点

- 基于官方 Rust 实现的同步服务器
- 多用户支持
- 多架构支持（`linux/amd64` + `linux/arm64`，CI 原生构建并合并 manifest）
- 自动构建最新版本
- 自动跟踪 Anki 上游版本（定时检查并自动 PR 更新）
- 优化的系统参数配置
- 日志轮转支持

## 快速开始

1. 克隆仓库：
   ```bash
   git clone https://github.com/kenyon-wong/anki-syncd.git
   cd anki-syncd
   ```

2. 配置用户：
   ```bash
   # 从示例文件复制一份实际配置文件
   cp envs/user.example.env envs/user.env

   # 编辑 envs/user.env，修改用户名和密码
   # 格式：SYNC_USERn=username:password
   ```

3. 启动服务：
   ```bash
   docker compose up -d
   ```

## 配置说明

### 环境变量

项目根目录的 `.env` 文件提供 Docker Compose 变量插值：

- `ANKI_VERSION`: Anki 版本号（版本唯一源，自动检查和 CI 构建均从此读取，控制镜像构建版本）

在 `envs/pub.env` 中可以配置以下运行时参数：

- `TZ`: 时区设置 (默认: Asia/Shanghai)
- `SYNC_BASE`: 同步文件存储路径 (默认: /opt/anki.d/sync.d)
- `SYNC_HOST`: 监听地址 (默认: 0.0.0.0)
- `SYNC_PORT`: 监听端口 (默认: 8080)
- `MAX_SYNC_PAYLOAD_MEGS`: 最大同步负载大小 (默认: 100MB)

### 用户认证

在 `envs/user.env` 中配置用户名和密码（从 `envs/user.example.env` 复制而来）：

```env
SYNC_USER1=user1:password1
SYNC_USER2=user2:password2
```

⚠️ 安全提示：请务必修改默认密码！

## 数据持久化

数据默认存储在 `./data.d/sync.d` 目录，可以通过修改 `docker-compose.yml` 中的 volumes 配置来更改：

```yaml
volumes:
  - "./data.d/sync.d:${SYNC_BASE:-/opt/anki.d/sync.d}"
```

## 日志管理

服务使用 JSON 日志驱动，支持日志轮转：
- 单个日志文件最大 10MB
- 保留最近 3 个日志文件
- 自动压缩旧日志

## 故障排除

1. 如果无法连接服务器：
   - 检查防火墙设置
   - 确认 8080 端口是否开放
   - 验证用户名密码是否正确

2. 同步失败：
   - 检查磁盘空间
   - 查看服务器日志
   - 确认 MAX_SYNC_PAYLOAD_MEGS 设置是否足够

## 部署方式

Anki 同步服务器默认监听 HTTP 连接。根据使用场景选择合适的部署方式：

### 方式一：直接使用（内网 / 受信网络）

无需反向代理，直接暴露 8080 端口。适用于内网、VPN 或个人局域网环境：

```yaml
# docker-compose.yml 保持默认即可
ports:
  - "8080:8080/tcp"
```

在 Anki 客户端中将同步地址设为 `http://服务器IP:8080`。

> ⚠️ HTTP 明文传输，密码可被中间人截获。仅在受信网络内使用。

### 方式二：HTTPS 反向代理（公网 / 生产环境）

通过反向代理启用 TLS，适用于公网暴露场景：

```yaml
# docker-compose.yml 将端口绑定到本地
ports:
  - "127.0.0.1:8080:8080/tcp"
```

使用 Caddy 自动获取证书（示例 `Caddyfile`）：

```caddyfile
sync.example.com {
    reverse_proxy localhost:8080
}
```

在 Anki 客户端中将同步地址设为 `https://sync.example.com`。

## Anki 客户端配置

部署服务器后，在 Anki 客户端中配置自定义同步地址：

**桌面端**（Windows / macOS / Linux）：

1. 打开 `工具 → 首选项 → 网络`（Anki 2.1.50+）
2. 勾选「自定义同步服务器」
3. 填入服务器地址（如 `http://服务器IP:8080` 或 `https://sync.example.com`）
4. 使用 `envs/user.env` 中配置的用户名和密码登录

**移动端**（AnkiDroid / AnkiMobile）：

- 在设置中找到同步选项，配置自定义同步 URL 和账号信息

> 首次同步时选择「下载」或「上传」决定同步方向。

## 编译镜像

如需手动编译镜像：

```bash
# 获取当前版本号
version=$(awk -F= '/^ANKI_VERSION=/{print $2}' .env)

# 单架构构建（当前平台）
docker buildx build -t anki/syncd:v${version} --build-arg ANKI_VERSION=${version} .

# 多架构构建（需要 buildx + QEMU）
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t anki/syncd:v${version} \
  --build-arg ANKI_VERSION=${version} .
```

CI 会在 `master` 分支推送时自动构建 `linux/amd64` + `linux/arm64` 双架构镜像并推送到 registry。

> 树莓派、ARM NAS 等 arm64 设备直接 `docker pull` 即可自动获取对应架构镜像。

## 参考资料

- [3 分钟为英语学习神器 Anki 部署一个专属同步服务器](https://www.cnblogs.com/ryanyangcs/p/17508044.html)
- [搭建 Anki 自托管同步服务器](https://blog.gazer.win/essay/build-anki-self-hosted-sync-server.html)
