# AGENTS.md

本文件是 AliceMobile-iOS 后续 Codex / agent 接手项目时必须先读的强约束入口。不要把当前 prompt 当成唯一上下文；项目方向以本文件和 `docs/DOCS_INDEX.md` 链接的长期记忆文档为准。

## 必读顺序

每次开始任务前，先按顺序阅读：

1. `AGENTS.md`
2. `docs/DOCS_INDEX.md`
3. `docs/PROJECT_CONTEXT.md`
4. `docs/ARCHITECTURE.md`
5. `docs/CODEX_HANDOFF.md`

按任务需要继续阅读：

- `docs/API_CONTRACT.md`
- `docs/DEMO_ACCEPTANCE.md`
- `docs/RIVE_INTEGRATION.md`
- `docs/UI_STYLE_REFERENCE.md`
- `docs/mobile-handoff/*`
- `docs/DECISIONS/*`

## 项目目标

AliceMobile-iOS 是 Alice AI digital companion 的 iOS 原生 Demo。当前阶段目标是形成可录屏 Demo 闭环：语音优先 Avatar 舞台、Rive / SwiftUI fallback 主线、Mock contract、轻量 Remote `/api/health` 和 `/api/dialogue` 联调。

它不是 WebView，不是传统聊天 App，不是 Web 3D runtime 移植项目。

## 当前主线

- SwiftUI 原生 App。
- 首页优先是 Avatar 舞台和语音输出体验，不改回传统聊天列表优先。
- 当前 Avatar 主线是 Rive renderer + SwiftUI fallback。
- `RiveRuntime` 已接入；没有正式 `alice_avatar.riv` 时必须继续走 SwiftUI fallback。
- 本地 Voice Output 使用 iOS `AVSpeechSynthesizer`，不调用后端 `/api/tts`。
- Backend 模式只接轻量 `/api/health` 和 `/api/dialogue`。
- Mock/Localhost/LAN IP、Health Check、Settings、Design Tokens、AvatarRendering 抽象已完成。

## 允许做的事情

- 修复 SwiftUI、ViewModel、API client、settings、contract decoding、renderer mapping、fallback 的小步问题。
- 补充或修正文档、测试、验收清单。
- 增强 Rive state machine bridge，但必须保持 SwiftUI fallback 可用。
- 调整 UI 时优先复用 `AliceTheme` 和现有布局，不重做产品形态。
- 只读参考 Web 项目 `myproject-Alice` 的契约和产品语义。

## 禁止做的事情

- 不修改 Web 项目 `/Users/fangwendong/02project/project/02数字人/myproject-Alice`。
- 不接 RAG、n8n、Qdrant。
- 不接后端 `/api/tts`。
- 不引入 VRM、SceneKit、RealityKit、WebView 作为当前主线。
- 不移除 Rive fallback 或 SwiftUI fallback。
- 不把首页改成传统聊天 App。
- 不在 iOS 端实现独立人格、长期记忆、情绪决策或 RAG 业务逻辑。
- 不保存 provider key、OpenAI key、TTS secret、n8n key、Qdrant credentials、证书或 token。
- 不提交 `.riv`、`.vrm`、DerivedData、build 产物、证书、密钥或本机私有配置。

## 文档更新规则

- 修改架构时，同步更新 `docs/ARCHITECTURE.md` 和必要 ADR。
- 修改产品路线或阶段边界时，同步更新 `docs/PROJECT_CONTEXT.md` 和 `docs/CODEX_HANDOFF.md`。
- 修改后端契约时，同步更新 `docs/API_CONTRACT.md`，必要时同步 `docs/mobile-handoff/API_CONTRACT_FOR_IOS.md`。
- 修改验收标准时，同步更新 `docs/DEMO_ACCEPTANCE.md`。
- 每轮任务结束时，如果当前真实状态、风险、缺失或下一步改变，更新 `docs/CODEX_HANDOFF.md`。
- 如果用户最新明确指令与文档冲突，先说明冲突，再按用户最新指令执行，并同步更新相关文档。

## 测试命令

文档-only 修改可不跑完整 Xcode build，但必须说明未改源码。

源码修改后至少运行：

```sh
xcodebuild -project AliceMobile/AliceMobile.xcodeproj -scheme AliceMobile -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' build
```

单元测试优先运行：

```sh
xcodebuild -project AliceMobile/AliceMobile.xcodeproj -scheme AliceMobile -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:AliceMobileTests test
```

注意：Codex 沙盒内直接跑 simulator test 可能遇到 CoreSimulator 权限、SwiftPM 网络或 test runner 超时问题。必要时请求 `xcodebuild` 沙盒外权限。

## Git 边界

- 开始修改前运行 `git status --short`。
- 不自动提交，不自动 push。
- 不运行破坏性命令，例如 `git reset --hard`、`git checkout --`、删除用户文件。
- 如果发现 Web 项目有改动，只报告，不修改。
- 如果工作树中已有用户改动，不覆盖、不回滚，先读 diff 再决定。

## 安全边界

- iOS 只保存非敏感设置：sessionId、selectedAvatarId、memoryEnabled、voiceOutputEnabled、apiMode、backendBaseURL。
- Localhost 用于 Simulator；LAN IP 只允许作为本机调试输入，不写死个人 IP。
- Provider secret 留在后端或安全凭证系统，不进入 App、plist、README、测试 fixture 或截图。
