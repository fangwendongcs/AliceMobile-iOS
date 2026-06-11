# API Contract

最后更新：2026-06-11

本文件记录 AliceMobile-iOS 当前实际消费的后端契约。更完整的历史交接见 `mobile-handoff/API_CONTRACT_FOR_IOS.md`，但当前实现以本文件为准。

## 总原则

- iOS 是 Alice Core 客户端。
- iOS 调后端、解码 response、展示状态、驱动本端 renderer。
- iOS 不复制 Web 后端 Persona / Memory / Emotion / Tone 业务逻辑。
- iOS 不保存真实 provider key、TTS secret、n8n key、Qdrant credentials 或 token。
- API 失败必须 fallback 或展示可恢复错误，不能让 App 不可用。

## Backend Base URL

Settings 中的连接模式：

- `Mock`：不调用后端。
- `Localhost`：Simulator 使用 `http://127.0.0.1:3000`。
- `LAN IP`：真机调试时用户填写 `http://<mac-lan-ip>:3000`。

不要把个人局域网 IP 写进核心代码或提交到 Git。

## GET /api/health

用途：后端可用性探测。

预期响应：

```json
{ "ok": true }
```

处理规则：

- 2xx 视为 connected。
- 非 2xx、网络失败或无效 URL 视为 disconnected。
- disconnected 不阻塞 Mock fallback。

## POST /api/dialogue

用途：当前唯一 Remote 对话入口。

请求字段：

```json
{
  "message": "你好",
  "sessionId": "ios-session",
  "avatarId": "alice",
  "provider": "stub",
  "model": "stub",
  "systemPrompt": "",
  "options": {
    "useMemory": true,
    "useRag": false,
    "useWorkflow": false,
    "avatarId": "alice"
  }
}
```

当前优先响应字段：

```json
{
  "ok": true,
  "data": {
    "reply": "...",
    "companion_state": {
      "status": "connected",
      "emotion": "warm",
      "tone": "gentle",
      "avatar_state": "speaking",
      "memory_status": {
        "used": true,
        "status": "ready",
        "long_term_count": 0
      },
      "is_mock": false
    },
    "avatar_directive": {
      "avatar_state": "speaking",
      "motion_slot": "speaking",
      "intensity": 0.45,
      "duration_ms": 1200,
      "return_to": "idle",
      "source": "dialogue"
    },
    "memory_status": {
      "used": true,
      "status": "ready",
      "long_term_count": 0
    },
    "tts_status": {
      "used": false,
      "status": "not_requested"
    }
  }
}
```

兼容字段：

- `reply_text` 可作为 `reply` 的兼容别名。
- `emotion` / `tone` 顶层字段可覆盖展示状态。
- 旧 `affect` 仍可解码，但只作为 fallback。
- 旧 `affect.motion.slot` 只在 `avatar_directive` 缺失时用于派生 `AvatarState`。

## 当前不接的 API

- 不接 `/api/tts`。
- 不接 RAG API。
- 不接 n8n webhook。
- 不接 Qdrant 或 vector database。
- 不直接接第三方 provider API。

本地 Voice Output 由 `AVSpeechSynthesizer` 提供，和后端 TTS 无关。

## Fallback 规则

- Mock 模式返回固定 mock contract，`companion_state.is_mock = true`。
- Remote `/api/dialogue` 失败时，设置 connection 为 disconnected，并回退 Mock contract。
- Rive asset 缺失时，使用 SwiftUI fallback，不影响 dialogue。
- contract 缺少非关键字段时使用安全默认值。
- contract 解码失败时显示可恢复错误，不崩溃。

## 安全规则

- 不在 iOS 代码、plist、测试 fixture、README 或截图里出现真实 key。
- 不向用户提供 provider key 输入框。
- 如果后端未来启用移动端鉴权，必须用短期 session 或登录态，不内置长期静态 token。
