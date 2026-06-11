# Architecture

最后更新：2026-06-11

## 总体结构

AliceMobile-iOS 是 SwiftUI 原生 App。当前架构重点是把 Alice Core contract 解码成本地展示状态，再驱动 Avatar renderer 和 Voice Output fallback。

```text
CompanionHomeView
-> ChatViewModel
-> AliceAPIClient
-> /api/health or /api/dialogue

ChatViewModel
-> AvatarRenderContext
-> AvatarStageView
-> RiveAvatarView or SwiftUIAvatarView

ChatViewModel
-> VoiceOutputService
-> AVSpeechSynthesizer
```

## ChatViewModel 职责

`ChatViewModel` 是当前主界面的状态协调层。

负责：

- 管理 selectedPersona、messages、draft、isSending。
- 管理 avatarState、currentAffect、companionState、avatarDirective、ttsStatus。
- 管理 memoryState、memoryEnabled。
- 管理 apiMode、backendBaseURL、healthStatus。
- 发送 `DialogueRequest`。
- Remote 失败时回退 Mock contract。
- 将 `DialogueResponse` 映射为 UI 状态和 `AvatarRenderContext`。
- 调用 `VoiceOutputing` 做本地语音播放。

不负责：

- 不做长期记忆写入策略。
- 不做人格、情绪、tone 决策。
- 不直接绑定具体 Rive 文件、VRM 文件或渲染 runtime。
- 不保存 provider secret。

## AppSettingsStore 职责

`AppSettingsStore` 只保存本地非敏感设置：

- `sessionId`
- `selectedAvatarId`
- `memoryEnabled`
- `voiceOutputEnabled`
- `apiMode`
- `backendBaseURL`

`Localhost` 模式固定用于 Simulator 默认地址 `http://127.0.0.1:3000`。`LAN IP` 模式允许用户输入 Mac 局域网 URL，但不得把个人 IP 写死进核心代码或文档。

## AliceAPIClient 职责

`AliceAPIClient` 是后端契约访问层。

当前职责：

- `health()` 调用 `/api/health`。
- `sendDialogue(_:)` 调用 `/api/dialogue`。
- `fetchMemory(...)` 保留 `/api/memory` 解码能力，但当前 Demo 主线不强调 memory list / clear。
- 解码 `{ ok, data, error }` envelope。
- 在 mock 模式返回固定 mock contract。

边界：

- 不直接调用 OpenAI、MiniMax、Qwen、DeepSeek、n8n、Qdrant 或 TTS provider。
- 不保存 token。
- 不把后端业务逻辑复制到 iOS。

## Models 职责

`DialogueModels.swift` 是 Swift 侧 contract 模型层。

当前优先字段：

- `reply` / `reply_text`
- `companion_state`
- `emotion`
- `tone`
- `avatar_directive`
- `memory_status`
- `tts_status`

旧 `affect` 仍兼容，但只作为 fallback，不是未来主契约方向。

## AvatarRendering 抽象

`AvatarRendering` 定义 renderer 边界。业务状态通过 `AvatarRenderContext` 传入。

当前实现：

- `RiveAvatarRenderer`
- `SwiftUIAvatarRenderer`

未来可选：

- `FutureVRMAvatarView` 只能作为 spike 或独立技术验证出现，不进入当前主线。

约束：

- 业务逻辑不能直接绑定 Rive、VRM 或具体资源文件。
- renderer 只表现 `avatarState`、`affect`、active body part。
- renderer 不决定人格、记忆、情绪或 tone。
- `.riv` 缺失时必须显示 SwiftUI fallback。

## SwiftUIAvatarView 职责

`SwiftUIAvatarView` 是无外部资产的 fallback renderer。

负责：

- 在 Rive asset 缺失时保持 Demo 可运行。
- 表现 speaking、listening、thinking、reacting、error 和 body-part tap 状态。

不负责：

- 不替代 Rive 正式素材。
- 不实现独立业务规则。

## RiveAvatarView 职责

`RiveAvatarView` 在 bundle 存在 `alice_avatar.riv` 且 `RiveRuntime` 可用时使用。

约定：

- 文件：`alice_avatar.riv`
- State machine：`AliceAvatar`
- Inputs：`avatar_state`、`emotion`、`tone`、`intensity`、`is_speaking`
- Triggers：`tap_head`、`tap_arm`、`tap_leg`、`tap_body`、`tap_chat`

`RiveAvatarStateMachineBridge` 负责稳定数字 code 映射。

## FutureVRMAvatarView 边界

当前没有 `FutureVRMAvatarView` 实现。后续如要做 VRM，只能先作为 Phase 5 spike：

- 不替换 Rive 主线。
- 不引入 SceneKit / RealityKit 主线改造。
- 不迁移 Web Three.js / FBX runtime。
- 不改动 Alice Core contract。

## VoiceOutputService 职责

`VoiceOutputService.swift` 当前提供 `VoiceOutputing` 和 `AVSpeechVoiceOutput`。

职责：

- 使用 iOS `AVSpeechSynthesizer` 做本地 Voice Output fallback。
- 播放期间通知 `ChatViewModel` 进入 speaking 状态。
- 播放失败时可恢复，不影响对话和 Avatar fallback。

边界：

- 不调用 `/api/tts`。
- 不保存 TTS provider key。
- 不追求最终产品级音色。

## Mock / Remote 模式边界

Mock：

- 不访问后端。
- 返回固定 mock contract。
- 不根据用户文本做长期记忆、情绪、人格推断。

Localhost：

- 给 iOS Simulator 使用。
- 默认 `http://127.0.0.1:3000`。

LAN IP：

- 给真机调试使用。
- 用户手动填写 Mac 局域网 URL。

Remote 失败：

- health 或 dialogue 失败时显示 disconnected。
- 回退 Mock contract。
- App 不崩溃。

## 安全边界

- iOS 不保存 provider secret。
- iOS 不保存 n8n key、Qdrant credentials、TTS secret、OpenAI key、证书或 token。
- iOS 不读取 `.env`。
- 真机调试 URL 只存本地 UserDefaults，不进入代码库。
