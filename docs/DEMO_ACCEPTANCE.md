# Demo Acceptance

本文用于 AliceMobile-iOS 的本地 Demo 录屏和手动验收。目标是验证原生 SwiftUI、Mock/Backend contract、Avatar state、Memory badge 和 Rive fallback 的完整路径。

## 默认 Mock 路径

1. 打开 `AliceMobile/AliceMobile.xcodeproj`。
2. 选择 `AliceMobile` scheme 和 iPhone Simulator。
3. 启动 App 后保持 `Mock` 模式。
4. 发送一条中文消息。
5. 首页状态应显示：
   - `mode = Mock`
   - `contract = mock contract`
   - `avatar_state` 从 `thinking` 进入 `speaking`，随后回到 `idle`
   - `directive` 来源为 mock contract
   - memory badge 显示当前长期记忆数量或 disabled

## 角色与 Avatar 路径

1. 切换 Alice / Shiro / Wambo。
2. 点击 Head / Arm / Leg / Body / Chat。
3. 验收点：
   - `avatar_state` 对应切到 head / arm / leg / reacting。
   - `emotion_tone` 与当前交互同步。
   - Rive 素材缺失时仍显示 SwiftUI fallback。
   - Settings > Avatar 显示 `Using SwiftUI fallback` 或 `Rive asset ready`。

## Backend 试用路径

1. 启动 Web backend。
2. Settings > Connection 选择 `Localhost`。
3. 点击 `Check`。
4. 发送消息。
5. 验收点：
   - `/api/health` 可用时 `connection = connected`。
   - `/api/dialogue` 返回 `avatar_directive` 时优先驱动 Avatar。
   - 后端失败时 `connection = disconnected`，App 回退 Mock contract，不崩溃。

## 安全边界

- iOS 不保存 provider API key、n8n secret、Qdrant credentials 或 TTS secret。
- 不提交真实 Bundle ID、证书、Provisioning Profile 或 Apple 账号信息。
- 不迁移 WebView、Three.js、FBX、DOM 或浏览器音频。
- 设计稿目录 `docs/design-references/` 保持 ignored。

## 当前已知限制

- 正式 `alice_avatar.riv` 尚未进入仓库时，Rive renderer 会显示 SwiftUI fallback。
- `RiveRuntime.xcframework` 首次构建需要 Xcode/SwiftPM 下载二进制包。
- TTS 仍只展示 contract 状态，真实音频播放放到后续阶段。
