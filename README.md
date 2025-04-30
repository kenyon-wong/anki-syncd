# Anki 同步服务器 Docker 镜像

[![Build status](https://github.com/kenyon-wong/anki-sync-server-docker/workflows/Docker%20Image%20CI/badge.svg)](https://github.com/kenyon-wong/anki-sync-server-docker/actions)

基于 Rust 实现的 Anki 自托管同步服务器 Docker 镜像，支持最新版本的 Anki 客户端。

## 功能特点

- 基于官方 Rust 实现的同步服务器
- 多用户支持
- 自动构建最新版本
- 优化的系统参数配置
- 日志轮转支持

## 快速开始

1. 克隆仓库：
   ```bash
   git clone https://github.com/kenyon-wong/anki-sync-server-docker.git
   cd anki-sync-server-docker
   ```

2. 配置用户：
   ```bash
   # 编辑 envs/users.env 文件
   # 格式：SYNC_USER1=username:password
   ```

3. 启动服务：
   ```bash
   docker compose up -d
   ```

## 配置说明

### 环境变量

在 `envs/pub.env` 中可以配置以下参数：

- `TZ`: 时区设置 (默认: Asia/Shanghai)
- `SYNC_BASE`: 同步文件存储路径 (默认: /opt/anki.d/sync.d)
- `SYNC_HOST`: 监听地址 (默认: 0.0.0.0)
- `SYNC_PORT`: 监听端口 (默认: 8080)
- `MAX_SYNC_PAYLOAD_MEGS`: 最大同步负载大小 (默认: 100MB)

### 用户认证

在 `envs/users.env` 中配置用户名和密码：

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

## 编译镜像

如需手动编译镜像：

```bash
# 获取当前版本号
version=$(cat .github/version)

# 编译镜像
docker build -t anki/syncd:v${version} --build-arg ANKI_VERSION=${version} .
```

## 参考资料

- [3 分钟为英语学习神器 Anki 部署一个专属同步服务器](https://www.cnblogs.com/ryanyangcs/p/17508044.html)
- [搭建 Anki 自托管同步服务器](https://blog.gazer.win/essay/build-anki-self-hosted-sync-server.html)
