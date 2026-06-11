# Demo Acceptance

本文用于 AliceMobile-iOS 的本地 Demo 录屏和手动验收。目标是验证原生 SwiftUI、Mock/Backend contract、Avatar state、Voice Output、Memory badge 和 Rive fallback 的完整路径。

## 推荐录屏路径

1. 打开 App，默认进入 `Mock` 模式。
2. 选择 Alice / Shiro / Wambo 中任意角色。
3. 打开 Settings，确认 Voice Output 为 On，并查看 Connection 的 Mock/Remote 状态与 Avatar 的 Rive 状态。
4. 回到首页发送一条中文消息。
5. Avatar 应进入 `speaking`，同时播放 iOS 本地语音。
6. 语音结束后 Avatar 应回到 `idle`。
7. 再次打开 Settings，展示 Mock/Remote、Voice Output、Rive asset ready / SwiftUI fallback 状态。

## 默认 Mock 路径

1. 打开 `AliceMobile/AliceMobile.xcodeproj`。
2. 选择 `AliceMobile` scheme 和 iPhone Simulator。
3. 启动 App 后保持 `Mock` 模式。
4. 发送一条中文消息。
5. 首页状态应显示：
   - `mode = Mock`
   - `contract = mock contract`
   - `avatar_state` 从 `thinking` 进入 `speaking`，本地语音结束后回到 `idle`
   - `directive` 来源为 mock contract
   - Voice Output 开启时，TTS 状态进入 `speaking` / `completed`
   - memory badge 显示当前长期记忆数量或 disabled

## Voice Output 路径

1. Settings > Voice 打开 `Voice Output`。
2. 回到首页发送消息。
3. 验收点：
   - 不需要输入 API Key。
   - 不调用 `/api/tts`。
   - 使用 iOS `AVSpeechSynthesizer` 本地 fallback 播放回复。
   - 播放期间 Avatar 状态为 `speaking`。
   - 关闭 Voice Output 后再次发送消息，不触发本地 speaking 播放链路。

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
- iOS 不接 `/api/tts`，本阶段只使用系统本地语音 fallback。
- 不提交真实 Bundle ID、证书、Provisioning Profile 或 Apple 账号信息。
- 不迁移 WebView、Three.js、FBX、DOM 或浏览器音频。
- 设计稿目录 `docs/design-references/` 保持 ignored。

## 当前已知限制

- 正式 `alice_avatar.riv` 尚未进入仓库时，Rive renderer 会显示 SwiftUI fallback。
- `RiveRuntime.xcframework` 首次构建需要 Xcode/SwiftPM 下载二进制包。
- Voice Output 使用系统本地语音，音色不是最终产品级云端 TTS。
