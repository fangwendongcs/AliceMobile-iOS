# Codex Handoff

最后更新：2026-06-11

本文件是每轮 Codex 任务结束时需要维护的项目交接记忆。如果项目方向、架构、API 契约、风险或下一步发生变化，必须同步更新。

## 接手前必读

每次开始任务前，先读：

1. `../AGENTS.md`
2. `DOCS_INDEX.md`
3. `PROJECT_CONTEXT.md`
4. `ARCHITECTURE.md`
5. `API_CONTRACT.md`
6. `CODEX_HANDOFF.md`

不要因为当前 prompt 没提到，就推翻已有路线。若用户明确要求与文档冲突，先说明冲突，再按用户最新明确指令执行，并更新对应文档。

## 当前真实状态

- AliceMobile-iOS 是 SwiftUI 原生数字伙伴 Demo。
- 首页是语音优先 Avatar 舞台，不是传统聊天 App。
- 当前主线是 Rive / SwiftUI fallback，不切 VRM。
- RiveRuntime 已接入，正式 `alice_avatar.riv` 缺失时必须继续走 SwiftUI fallback。
- Mock / Localhost / LAN IP、Health Check、Settings、Design Tokens、AvatarRendering 抽象已完成。
- Remote 只接轻量 `/api/health` 与 `/api/dialogue`。
- 本地 Voice Output 使用 `AVSpeechSynthesizer`，不接后端 `/api/tts`。
- iOS 不接 RAG、n8n、Qdrant、VRM、SceneKit、RealityKit、WebView。
- Web 项目 `myproject-Alice` 是只读参考，不允许修改。

## 最近完成内容

- 对齐 `/api/dialogue` contract：`reply/reply_text`、`companion_state`、`avatar_directive`、`memory_status`、`tts_status`。
- Mock responder 改为固定 mock contract，不再做本地人格、记忆、情绪推断。
- Settings 显示 connection、backend URL、renderer、Rive asset、memory、Voice Output 状态。
- `VoiceOutputService` 使用 iOS 本地 `AVSpeechSynthesizer` 做语音播放 fallback。
- 新增长期记忆文档结构：`AGENTS.md`、`DOCS_INDEX.md`、`PROJECT_CONTEXT.md`、`ARCHITECTURE.md`、`API_CONTRACT.md`、ADR。

## 当前风险

- 旧 `mobile-handoff` 文档是历史迁移资料，部分内容会提到未来 `/api/tts`、RAG 或 3D 方向。当前主线以 `PROJECT_CONTEXT.md` 和 `API_CONTRACT.md` 为准。
- 正式 `alice_avatar.riv` 未作为仓库必备资产时，Rive renderer 会切 SwiftUI fallback。
- `AppAPIMode.remote` 仍作为历史兼容 case 存在，但 Settings 只展示 Mock / Localhost / LAN IP。
- 本地 Voice Output 音色只是 Demo fallback，不是最终产品级 TTS。
- Simulator test 在 Codex 沙盒内可能出现 CoreSimulator 权限、SwiftPM 网络或 test runner 超时。

## 当前缺失

- 正式 Rive 素材和状态机验收。
- 与真实 Web backend 的 `/api/dialogue` 端到端联调样例。
- Memory list / clear UI 未进入当前主线。
- 云端 TTS 未进入当前主线。
- VRM / 3D 技术验证未开始，且不应进入当前主线。

## 常用命令

检查状态：

```sh
git status --short
```

文档-only 修改：

```sh
git diff --check
```

源码修改后的 compile-only build：

```sh
xcodebuild -project AliceMobile/AliceMobile.xcodeproj -scheme AliceMobile -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build
```

单元测试：

```sh
xcodebuild -project AliceMobile/AliceMobile.xcodeproj -scheme AliceMobile -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:AliceMobileTests test
```

如果沙盒内失败，优先判断是否是权限、SwiftPM 网络或 CoreSimulator 问题，再请求 `xcodebuild` 沙盒外权限。

## 已知环境问题

- Codex MCP `test_sim` 可能在 `Writing result bundle` 后超时。
- 沙盒内直接 `xcodebuild test` 可能无法访问 CoreSimulator 日志，或因 SwiftPM 网络受限无法解析 GitHub。
- Simulator test 可能出现 Mach error -308、CoreSimulator service invalid 或 result bundle 为空。
- 之前沙盒外完整 `xcodebuild test -only-testing:AliceMobileTests` 可通过。
- 如果出现这类环境错误，先重试沙盒外完整 `xcodebuild test`，不要直接判定代码失败。

## 下一步建议

1. 用真实 Web backend 本地启动后，验证 Localhost `/api/health` 和 `/api/dialogue`。
2. 补入正式 `alice_avatar.riv` 后，按 `RIVE_INTEGRATION.md` 验证 state machine inputs。
3. 继续 polish 首页 Avatar 舞台与录屏路径。
4. 只在用户明确要求时，才推进 Memory list / clear、云端 TTS 或 VRM spike。

## 任务结束规则

- 不自动提交 Git。
- 不修改 Web 项目。
- 不新增 secret、证书、token、`.riv`、`.vrm`、DerivedData 或 build 产物。
- 如果文档-only 修改，说明未跑完整 xcodebuild。
- 如果改了 Swift 源码，必须跑 compile-only build，能跑测试则跑测试。
