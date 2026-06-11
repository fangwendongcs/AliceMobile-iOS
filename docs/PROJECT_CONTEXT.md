# Project Context

最后更新：2026-06-11

## 产品定位

AliceMobile-iOS 是 Alice AI digital companion 的 iOS 原生 Demo。它要证明 iOS 是 Alice Core 的一个客户端，而不是独立聊天 Demo，也不是 WebView 包壳。

当前体验重点是“语音优先 Avatar 舞台”：用户看到的是一个可表达状态的数字伙伴舞台，聊天记录和设置是辅助信息。

## 当前 Demo 目标

当前阶段目标是可录屏 Demo 闭环：

- App 可启动并默认进入 Mock contract。
- 首页保持 Avatar 舞台优先。
- 发送消息后展示 reply、emotion、tone、avatar_state、memory badge。
- 本地 Voice Output 使用 `AVSpeechSynthesizer` 播放回复。
- RiveRuntime 可用时走 Rive；正式 `.riv` 缺失时稳定走 SwiftUI fallback。
- Settings 可展示 connection、backend URL、renderer、Rive asset、memory、Voice Output 状态。
- Localhost / LAN IP 可用于轻量 Remote `/api/health` 和 `/api/dialogue` 联调。
- 后端不可用时 App 不崩溃，回退 Mock contract。

## 当前已完成

- SwiftUI 单页原生 App。
- Alice / Shiro / Wambo 静态角色切换。
- Mock / Localhost / LAN IP 模式。
- `AliceAPIClient` 支持 `/api/health`、`/api/dialogue`，并保留 `/api/memory` 解码能力。
- `DialogueResponse` 兼容 `reply/reply_text`、`companion_state`、`avatar_directive`、`memory_status`、`tts_status` 和旧 `affect`。
- `AvatarRendering` 抽象包含 Rive renderer 与 SwiftUI fallback。
- `RiveRuntime` 已接入，约定 `alice_avatar.riv` 和 `AliceAvatar` state machine。
- 本地 `VoiceOutputService` 使用 `AVSpeechSynthesizer`，不需要 provider key。
- Demo 验收文档、Rive 文档、UI 风格参考已存在。

## 当前不做

- 不接 RAG。
- 不接 n8n。
- 不接 Qdrant。
- 不接后端 `/api/tts`。
- 不做完整语音输入、流式响应、后台常驻。
- 不做 VRM、SceneKit、RealityKit 主线。
- 不做 WebView。
- 不修改 Web 项目 `myproject-Alice`。
- 不在 iOS 端维护独立长期记忆系统。
- 不在 iOS 端实现 Persona / Memory / Emotion / Tone 决策。

## 路线

### Phase 1：视觉与架构基线

目标：建立 SwiftUI 原生壳、Design Tokens、AvatarRendering 抽象、Mock contract、Settings 和 Rive / SwiftUI fallback。

状态：已完成基础能力，仍可继续 polish。

### Phase 2：语音优先 Demo 闭环

目标：首页保持 Avatar 舞台优先，发送消息后通过本地 Voice Output 播放，Avatar 状态同步到 speaking / idle。

状态：已具备本地 `AVSpeechSynthesizer` fallback。当前不接后端 `/api/tts`。

### Phase 3：Rive 正式素材接入

目标：加入正式 `alice_avatar.riv`，验证 `AliceAvatar` state machine inputs、tap triggers 和 fallback 稳定性。

状态：RiveRuntime 已接入，正式 `.riv` 未作为当前仓库必备条件。缺失时必须保持 SwiftUI fallback。

### Phase 4：Remote `/api/dialogue` 稳定联调

目标：和 Web 后端本地运行的 Alice Core 契约对齐，稳定消费 `/api/health` 和 `/api/dialogue`。

状态：已支持 Localhost / LAN IP 配置和 fallback。后续只做轻量联调，不扩大到 RAG / TTS / n8n。

### Phase 5：VRM 资产审计与 3D 技术验证

目标：只做未来 spike，审计授权、包体、性能、骨骼、渲染方案。

状态：暂不进入主线，不引入 SceneKit / RealityKit / VRM runtime。

## 为什么当前选 Rive，而不是 VRM

- Rive 更适合当前 Demo 的状态机表达、轻量交互和录屏稳定性。
- Rive 与 SwiftUI fallback 可以共用 `AvatarRenderContext` 和 `AvatarState`。
- VRM 涉及模型授权、包体、骨骼兼容、动作 retarget、渲染性能和 native runtime 选择，风险明显高于当前阶段收益。
- 当前目标是证明 iOS 消费 Alice Core 契约，不是证明 3D runtime。

## 为什么首页语音优先，而不是传统聊天页

- 产品定位是 digital companion，不是普通 chatbot。
- Avatar 舞台能直观展示 emotion、tone、avatar_state、Voice Output 和 fallback。
- 聊天列表只是对话记录，不应抢占第一视觉层级。
- Demo 录屏需要先看到“伙伴在场”，再看到文本。

## 与 Web 项目的关系

Web 项目路径：

`/Users/fangwendong/02project/project/02数字人/myproject-Alice`

它是只读参考和短期本地后端来源。AliceMobile-iOS 不修改该项目，不迁移 Web runtime，不复制业务逻辑。
