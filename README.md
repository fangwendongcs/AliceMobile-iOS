# AliceMobile-iOS

AliceMobile-iOS 是 Alice AI digital companion 的独立 iOS 原生 SwiftUI 项目。它不是 WebView，也不是把 Web 端 Three.js / FBX / DOM UI 搬进 Xcode；第一阶段目标是把 Web / Backend 项目里已经沉淀的角色设定、API 契约、情绪状态、记忆边界和对话流程迁移成可运行的 iOS MVP 骨架。

## 当前状态

- 原生 SwiftUI 单页 MVP。
- 支持 Alice / Shiro / Wambo 角色切换。
- 默认 `Mock` 模式，不调用真实后端。
- 已增加 `Localhost` 和 `LAN IP` 后端模式，可执行 health check。
- 后端模式当前只接 `/api/health` 和 `/api/dialogue`，失败时回退 Mock contract。
- 展示 `reply_text/reply`、`emotion`、`tone`、`avatar_state`、Voice Output 和 memory 状态。
- 支持 iOS 原生 `AVSpeechSynthesizer` 本地语音 fallback，默认开启，可在 Settings 关闭。
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

1. 先在 Mac 上启动 Alice Web 项目的后端。
2. iOS Simulator 调试：打开 App 右上角 Settings，将 Mode 切换为 `Localhost`，默认使用 `http://127.0.0.1:3000`。
3. 真机调试：将 Mode 切换为 `LAN IP`，填写 `http://<mac-lan-ip>:3000` 形式的地址。
4. 点击 Check 验证 `/api/health`。
5. 回到聊天页发送消息，App 会调用 `POST /api/dialogue`。

后端不可用时会显示 `disconnected` 并回退 Mock contract，避免 Demo 卡死。App 不提供 API Key 输入框，也不会保存 provider secret。

## Dialogue Contract

iOS 当前消费统一后端契约，不复制 Web 侧 Persona / Memory / Emotion 决策逻辑：

- `reply` 或 `reply_text`：聊天文本展示。
- `companion_state`：后端或 mock contract 给出的伴随状态摘要。
- `emotion` / `tone`：本轮回复表现提示。
- `avatar_directive`：优先映射到 `AvatarState`，驱动 Rive 与 SwiftUI fallback。
- `memory` / `memory_status`：只展示状态和数量，不在 iOS 写长期记忆。
- `tts_status`：兼容后端状态展示；iOS Demo 使用本地 `AVSpeechSynthesizer` 做 Voice Output fallback，不调用 `/api/tts`。

如果后端仍返回旧版 `affect.motion.slot`，iOS 会兼容派生 `avatar_state`；如果同时返回 `avatar_directive`，优先使用后端 directive。

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
  Services/      AliceAPIClient 与 mock contract fallback
  Stores/        本地 session、角色、memory 和 API 模式
  ViewModels/    ChatViewModel
  Views/         SwiftUI 原生界面
docs/
  mobile-handoff/
  DEMO_ACCEPTANCE.md
  RIVE_INTEGRATION.md
  WEB_MIGRATION_AUDIT.md
```

## 安全边界

- App 不保存 OpenAI、MiniMax、Qwen、DeepSeek、n8n、Qdrant 或 TTS provider secret。
- App 只保存非敏感的 `sessionId`、`selectedAvatarId`、`memoryEnabled`、`voiceOutputEnabled`、`apiMode` 和 `backendBaseURL`。
- `backendBaseURL` 仅用于 LAN IP / 自定义调试，不在核心代码中写死个人本机 IP。
- 真实 provider、TTS、RAG 和记忆主库应由后端托管。
- 公开 iOS App 不应内置长期静态 API token。

## Demo 脚本

1. 启动 App，默认进入 Mock。
2. 切换 Alice / Shiro / Wambo，观察角色 tone 与 Avatar 状态变化。
3. 打开 Settings，确认 Voice Output 为 On，Avatar 区域显示 Rive 状态，Connection 显示 Mock/Localhost/LAN。
4. 回到首页发送“你好，测试状态”。
5. 观察 Avatar 进入 `speaking`，听到 iOS 本地语音播放，随后回到 `idle`。
6. 打开 Settings 查看 Mock/Remote、Voice Output 和 Rive asset 状态。

## 后续方向

1. 补入正式 `alice_avatar.riv`，并用 Xcode / Simulator 验证状态机输入。
2. 在后端提供移动端友好的 persona/avatar summary API。
3. 等后端安全代理准备好后，再评估云端 TTS；本阶段不接 `/api/tts`。
4. 接入 memory list / clear。
5. 继续打磨 Rive 状态机和角色素材管线。
