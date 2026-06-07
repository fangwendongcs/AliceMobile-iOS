# AliceMobile-iOS

AliceMobile-iOS 是 Alice AI digital companion 的独立 iOS 原生 SwiftUI 项目。它不是 WebView，也不是把 Web 端 Three.js / FBX / DOM UI 搬进 Xcode；第一阶段目标是把 Web / Backend 项目里已经沉淀的角色设定、API 契约、情绪状态、记忆边界和对话流程迁移成可运行的 iOS MVP 骨架。

## 当前状态

- 原生 SwiftUI 单页 MVP。
- 支持 Alice / Shiro / Wambo 角色切换。
- 默认 `Mock` 模式，不调用真实后端。
- 展示 `emotion`、`tone`、`avatar_state`、voice 参数和 memory 状态。
- 已建立 `AliceAPIClient` 骨架，保留 `/api/dialogue` 和 `/api/memory` 的 Codable 契约。
- 不包含真实 API Key、Apple 账号、证书、Provisioning Profile 或真实发布配置。

## 与 Web 项目的关系

只读参考项目：

`/Users/fangwendong/02project/project/02数字人/myproject-Alice`

iOS 复用的是产品语义和后端契约：

- persona：`alice`、`osa_shiro`、`osa_wambo`
- dialogue：`POST /api/dialogue`
- memory：`sessionId`、`avatarId`、`longTerm.count`
- affect：`emotion`、`tone`、`voice`、`motion.slot`
- avatar state：`idle`、`thinking`、`speaking`、`reacting`、`head_action` 等

iOS 不迁移：

- Three.js / WebGL runtime
- FBXLoader / AnimationMixer / Web 动画队列
- DOM 控制器、CSS 布局、浏览器音频实现
- Node backend、n8n、RAG、Qdrant 的运行时
- Web 端模型资产和 manifest 的 3D runtime 字段

## 如何运行

1. 用 Xcode 打开：

   `AliceMobile/AliceMobile.xcodeproj`

2. 选择 `AliceMobile` scheme。
3. 选择 iPhone Simulator。
4. 点击 Run。

当前默认使用本地 mock 数据，不需要启动 Web 后端，也不需要配置任何 provider secret。

## 主要目录

```text
AliceMobile/AliceMobile/
  Models/        Swift Codable 领域模型
  Services/      AliceAPIClient 与 mock-first 对话服务
  Stores/        本地 session、角色和 memory 开关
  ViewModels/    ChatViewModel
  Views/         SwiftUI 原生界面
docs/
  mobile-handoff/
  WEB_MIGRATION_AUDIT.md
```

## 安全边界

- App 不保存 OpenAI、MiniMax、Qwen、DeepSeek、n8n、Qdrant 或 TTS provider secret。
- App 只保存非敏感的 `sessionId`、`selectedAvatarId` 和 `memoryEnabled`。
- 真实 provider、TTS、RAG 和记忆主库应由后端托管。
- 公开 iOS App 不应内置长期静态 API token。

## 后续方向

1. 在后端提供移动端友好的 persona/avatar summary API。
2. 将 `AliceAPIClient` 从 mock 切到可配置后端地址。
3. 接入 `/api/dialogue`、`/api/tts`、`/api/memory` 的真实联调。
4. 增加 AVSpeechSynthesizer 或后端 TTS 音频播放。
5. 评估 Rive / Lottie / SceneKit / RealityKit 的原生 Avatar 表现方案。
