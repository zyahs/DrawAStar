# JiFeng Backend

第一版后台是一个部署在现有 ECS 上的模块化单体：

- NestJS API
- Prisma + MariaDB
- JWT access/refresh session
- 用户资料、身份绑定、游戏记录、游戏配置
- 后台管理员登录、用户列表、封禁、配置、审计日志

## 本地启动

```bash
cd backend
cp .env.example .env
npm install
npm run prisma:generate
npm run prisma:dev
npm run start:dev
```

默认 API 前缀是 `/api`，例如：

- `POST /api/auth/guest`
- `POST /api/auth/refresh`
- `GET /api/me`
- `PATCH /api/me`
- `POST /api/games/records`
- `GET /api/games/leaderboard?kind=TRUTH_OR_DARE`
- `POST /api/admin/bootstrap`
- `POST /api/admin/login`
- `GET /api/admin/users`

## ECS 部署建议

先沿用当前服务器上的 Nginx、MariaDB、Redis 基础设施：

1. MariaDB 建库和低权限用户。
2. 上传 `backend/` 到 `/home/admin/jifeng-backend`。
3. 写 `.env`，不要提交真实密钥。
4. `npm ci && npm run prisma:generate && npm run prisma:migrate && npm run build`。
5. 用 systemd 跑 `node dist/main.js`。
6. Nginx 新增 `api.zy-fbdy.com` 或 `/jifeng-api/` 反代到 `127.0.0.1:3008`。

## 登录策略

MVP 建议：

1. App 首次启动走游客登录，用户无感拥有账号。
2. iOS 优先绑定 Apple 登录。
3. 手机号登录延后；保留 `PHONE` identity，不在第一版接运营商 SDK。

`/api/auth/apple` 现在只放了开发占位。生产环境需要补 Apple JWKS 签名校验、bundleId/audience 校验后再开启。

## IM 判断

第一版不建议接完整 IM SDK。这个 App 的核心是小游戏和聚会玩法，先做“房间事件/游戏消息”即可：

- 房间内实时同步：沿用轻量 WebSocket 或现有 `JFRemoteGameSession` 的服务端中转。
- 私聊/群聊：等确实出现持续社交需求再接 IM。
- 用户消息通知：先用系统推送或站内通知表，不要一开始引入复杂会话体系。

这样既能支持联机玩法，又不会过早承担审核、敏感词、投诉、封禁、消息存储等 IM 运营成本。
