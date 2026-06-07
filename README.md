# AliceMobile-iOS

AliceMobile-iOS 是 Alice AI digital companion 的独立 iOS 原生 SwiftUI 项目。它不是 WebView，也不是把 Web 端 Three.js / FBX / DOM UI 搬进 Xcode；第一阶段目标是把 Web / Backend 项目里已经沉淀的角色设定、API 契约、情绪状态、记忆边界和对话流程迁移成可运行的 iOS MVP 骨架。

## 当前状态

- 原生 SwiftUI 单页 MVP。
- 支持 Alice / Shiro / Wambo 角色切换。
- 默认 `Mock` 模式，不调用真实后端。
- 已增加 `Remote` 试用模式，可配置后端 Base URL 并执行 health check。
- Remote 模式当前只接 `/api/health` 和 `/api/dialogue`，失败时回退 Mock。
- 展示 `emotion`、`tone`、`avatar_state`、voice 参数和 memory 状态。
- 已建立 `AliceAPIClient` 骨架，保留 `/api/dialogue` 和 `/api/memory` 的 Codable 契约。
- 已通过 Swift Package Manager 引入 `RiveRuntime`，`AvatarRendering` 当前支持 Rive renderer 与 SwiftUI fallback。
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

## 真实试用模式

1. 打开 App 右上角 Settings。
2. 将 Mode 切换为 `Remote`。
3. 填写后端 Base URL，例如 `http://127.0.0.1:3000`。
4. 点击 Check 验证 `/api/health`。
5. 回到聊天页发送消息，App 会调用 `POST /api/dialogue`。

Remote 失败时会显示错误并回退 Mock，避免 Demo 卡死。App 不提供 API Key 输入框，也不会保存 provider secret。

## Avatar 渲染策略

当前默认优先选择 `Rive`。项目已接入 `RiveRuntime`，并约定正式素材文件名为 `alice_avatar.riv`。如果 bundle 中没有该素材，`RiveAvatarView` 会自动显示 SwiftUI fallback，确保 Mock 聊天和状态展示仍可运行。

Rive state machine 约定：

- 素材文件：`AliceMobile/AliceMobile/alice_avatar.riv`
- 推荐默认 state machine 名称：`AliceAvatar`
- number inputs：`avatar_state`、`emotion`、`tone`、`intensity`
- boolean input：`is_speaking`
- trigger inputs：`tap_head`、`tap_arm`、`tap_leg`、`tap_body`、`tap_chat`

`avatar_state`、`emotion` 和 `tone` 在 iOS 端使用稳定数字 code 映射，详见 `RiveAvatarStateMachineBridge`。

Settings 的 Avatar 区域会显示当前是否识别到 `alice_avatar.riv`。显示 `Using SwiftUI fallback` 时，说明 RiveRuntime 已接入但正式素材尚未进入 App bundle。

## 主要目录

```text
AliceMobile/AliceMobile/
  Models/        Swift Codable 领域模型
  Services/      AliceAPIClient 与 mock-first 对话服务
  Stores/        本地 session、角色、memory 和 API 模式
  ViewModels/    ChatViewModel
  Views/         SwiftUI 原生界面
docs/
  mobile-handoff/
  WEB_MIGRATION_AUDIT.md
```

## 安全边界

- App 不保存 OpenAI、MiniMax、Qwen、DeepSeek、n8n、Qdrant 或 TTS provider secret。
- App 只保存非敏感的 `sessionId`、`selectedAvatarId`、`memoryEnabled`、`apiMode` 和 `backendBaseURL`。
- 真实 provider、TTS、RAG 和记忆主库应由后端托管。
- 公开 iOS App 不应内置长期静态 API token。

## Demo 脚本

1. 启动 App，默认进入 Mock，可直接发送“你好，测试状态”。
2. 切换 Alice / Shiro / Wambo，观察角色 tone 与 Avatar 状态变化。
3. 点击 Head / Arm / Leg / Body / Chat，观察 `avatar_state` 和状态面板。
4. 打开 Settings，切换 Remote，填写后端地址并 Check。
5. 发送消息，验证真实 `/api/dialogue` 或自动 Mock fallback。

## 后续方向

1. 补入正式 `alice_avatar.riv`，并用 Xcode / Simulator 验证状态机输入。
2. 在后端提供移动端友好的 persona/avatar summary API。
3. 接入 `/api/tts` 和 iOS 音频播放。
4. 接入 memory list / clear。
5. 继续打磨 Rive 状态机和角色素材管线。
