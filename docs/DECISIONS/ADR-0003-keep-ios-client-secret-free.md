# ADR-0003: Keep iOS Client Secret-Free

## 背景

Alice Core 可能使用 LLM provider、TTS provider、n8n、Qdrant 和其他后端服务。这些能力通常需要 secret。

## 决策

iOS 客户端不保存真实 provider key、TTS secret、n8n key、Qdrant credentials、API token、证书或私钥。

## 原因

- 移动端包体可被反编译。
- 静态 token 容易泄露。
- Secret 应留在后端、凭证系统或用户登录后的短期 session 中。

## 后果

- App 不提供 provider key 输入框。
- iOS 只传非敏感选项，例如 avatarId、sessionId、provider/model 名称、message。
- 当前 Remote 只接 `/api/health` 和 `/api/dialogue`。
- 云端 TTS、RAG、n8n、Qdrant 不进入当前 iOS 主线。

## 当前状态

Accepted。`.gitignore` 已覆盖常见 secret、证书、环境文件和构建产物。
