# Mail-in-a-Box Docker 部署指南

本文档说明如何使用 Docker 和 docker-compose 部署 Mail-in-a-Box 邮件服务器。

## 前提条件

- Docker 和 Docker Compose 已安装
- 至少 1GB 内存（推荐 2GB+）
- 有效的域名指向您的服务器
- 开放的网络端口（见下方端口列表）

## 快速开始

1. **克隆项目并进入目录**
   ```bash
   git clone <repository-url>
   cd mailinabox
   ```

2. **配置环境变量**
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，至少设置 PRIMARY_HOSTNAME
   nano .env
   ```

3. **构建并启动服务**
   ```bash
   docker-compose up -d
   ```

4. **查看日志**
   ```bash
   docker-compose logs -f mailinabox
   ```

## 环境配置

### 必需配置

在 `.env` 文件中设置以下变量：

- `PRIMARY_HOSTNAME`: 邮件服务器的主域名（如：mail.example.com）

### 可选配置

- `PUBLIC_IP`: 公网 IPv4 地址（通常自动检测）
- `PUBLIC_IPV6`: 公网 IPv6 地址（通常自动检测）
- `TZ`: 时区设置（默认：UTC）

## 端口说明

以下端口需要在防火墙中开放：

| 端口 | 协议 | 服务 | 说明 |
|------|------|------|------|
| 25 | TCP | SMTP | 邮件传输 |
| 53 | TCP/UDP | DNS | 域名解析 |
| 80 | TCP | HTTP | Web 界面（重定向到 HTTPS） |
| 110 | TCP | POP3 | 邮件接收 |
| 143 | TCP | IMAP | 邮件接收 |
| 443 | TCP | HTTPS | 安全 Web 界面 |
| 465 | TCP | SMTPS | 安全邮件传输 |
| 587 | TCP | SMTP Submission | 邮件提交 |
| 993 | TCP | IMAPS | 安全邮件接收 |
| 995 | TCP | POP3S | 安全邮件接收 |
| 10222 | TCP | Management API | 管理接口 |

## 数据持久化

重要数据存储在 Docker 卷中：

- `mailinabox_data`: 主要用户数据
- `mailinabox_ssl`: SSL 证书
- `mailinabox_mail`: 邮件数据
- `mailinabox_dns`: DNS 配置
- `mailinabox_backup`: 备份数据

## 管理界面

服务启动后，可通过以下方式访问管理界面：

- HTTPS: `https://your-hostname/admin`
- HTTP: `http://your-hostname/admin`（会重定向到 HTTPS）

## 常见问题

### 1. 容器启动失败

检查日志：
```bash
docker-compose logs mailinabox
```

常见原因：
- 内存不足（至少需要 1GB）
- 端口被占用
- 域名配置错误

### 2. SSL 证书问题

Mail-in-a-Box 使用 Let's Encrypt 自动获取 SSL 证书。确保：
- 域名正确指向服务器
- 端口 80 和 443 可访问
- 防火墙配置正确

### 3. 邮件发送/接收问题

检查：
- DNS 记录是否正确设置
- 端口 25、587、465 是否开放
- 域名信誉度（新域名可能被标记为垃圾邮件）

## 备份和恢复

### 备份

```bash
# 备份所有数据卷
docker run --rm -v mailinabox_data:/data -v $(pwd):/backup ubuntu tar czf /backup/mailinabox-backup.tar.gz /data

# 或者使用内置备份功能（需要配置）
docker-compose exec mailinabox /home/mailinabox/mailinabox/management/backup.py
```

### 恢复

```bash
# 恢复数据卷
docker run --rm -v mailinabox_data:/data -v $(pwd):/backup ubuntu tar xzf /backup/mailinabox-backup.tar.gz -C /
```

## 升级

1. 停止服务：
   ```bash
   docker-compose down
   ```

2. 更新代码：
   ```bash
   git pull
   ```

3. 重新构建并启动：
   ```bash
   docker-compose build --no-cache
   docker-compose up -d
   ```

## 故障排除

### 查看服务状态

```bash
# 查看容器状态
docker-compose ps

# 查看实时日志
docker-compose logs -f

# 进入容器
docker-compose exec mailinabox bash
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart mailinabox
```

## 安全注意事项

1. **定期更新**: 保持系统和 Docker 镜像更新
2. **强密码**: 使用强密码保护管理账户
3. **防火墙**: 只开放必要的端口
4. **监控**: 定期检查日志和系统状态
5. **备份**: 定期备份重要数据

## 性能优化

1. **内存**: 推荐至少 2GB 内存
2. **存储**: 使用 SSD 提高性能
3. **网络**: 确保网络连接稳定
4. **监控**: 使用内置的 Munin 监控系统

## 支持

如遇问题，请：

1. 查看官方文档：https://mailinabox.email
2. 检查 GitHub Issues
3. 参考社区论坛：https://discourse.mailinabox.email
