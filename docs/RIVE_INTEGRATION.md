# Rive Integration

AliceMobile-iOS 已通过 Swift Package Manager 接入官方 `rive-ios` package 的 `RiveRuntime` 产品。当前实现保持 mock-first 和 SwiftUI fallback：如果正式 `.riv` 素材缺失，App 仍然可以打开、聊天、切换角色并展示状态。

Rive 只负责表现层。`RiveAvatarStateMachineBridge` 消费 `DialogueResponse.avatarDirective`、`affect.emotion`、`affect.tone` 和当前 `AvatarState`，不参与 Persona、Memory、Emotion 或 Tone 决策。后端不可用时，这些输入来自 mock contract；`.riv` 缺失时同一份状态继续驱动 SwiftUI fallback。

## 资源约定

- 文件名：`alice_avatar.riv`
- 放置位置：`AliceMobile/AliceMobile/alice_avatar.riv`
- 推荐默认 state machine 名称：`AliceAvatar`

当前代码用 `Bundle.main.url(forResource: "alice_avatar", withExtension: "riv")` 检测资源，并用 `RiveViewModel(fileName: "alice_avatar", stateMachineName: "AliceAvatar")` 加载约定的 state machine。正式素材应在 Rive Editor 中提供 `AliceAvatar` 状态机。

Settings 的 Avatar 区域会显示素材状态：

- `Rive asset ready`：App bundle 中已找到 `alice_avatar.riv`。
- `Using SwiftUI fallback`：未找到正式 Rive 素材，当前使用 SwiftUI fallback。

## 状态机输入

Rive runtime 的 state machine input 通常是 number、boolean 或 trigger。iOS 端保留产品语义，但在运行时使用稳定 code 映射：

| iOS 语义 | Rive input | 类型 |
| --- | --- | --- |
| avatar_state | `avatar_state` | number |
| emotion | `emotion` | number |
| tone | `tone` | number |
| intensity | `intensity` | number |
| is_speaking | `is_speaking` | boolean |
| head tap | `tap_head` | trigger |
| arm tap | `tap_arm` | trigger |
| leg tap | `tap_leg` | trigger |
| body tap | `tap_body` | trigger |
| chat tap | `tap_chat` | trigger |

Code 表定义在 `RiveAvatarStateMachineBridge`。不要在 SwiftUI 页面里散落新的 input 名称；新增输入时先扩展桥接层和测试。

映射优先级：

1. `/api/dialogue` 返回 `avatar_directive.avatar_state` 时，优先使用该状态。
2. 没有 `avatar_directive` 时，从 `affect.motion.slot` 派生 `AvatarState`。
3. 后端失败时使用 mock contract 的 `avatar_directive`。
4. Rive asset 缺失或 `RiveRuntime` 不可用时，保持同一份状态并切到 SwiftUI fallback。

## 未迁移内容

- 不迁移 Web hit test、Three.js、FBX、DOM 或浏览器音频。
- 不在 iOS 本地运行模型、RAG、n8n 或 TTS provider secret。
- 不提交临时设计稿或密钥文件。

## 验证清单

1. `alice_avatar.riv` 缺失时，App 应显示 SwiftUI fallback。
2. `alice_avatar.riv` 存在时，App 应显示 Rive renderer。
3. Alice / Shiro / Wambo 切换后，`avatar_state`、`emotion`、`tone`、`intensity` 应同步写入 Rive。
4. Head / Arm / Leg / Body / Chat 点击应触发对应 trigger。
5. 后端不可用不应影响 Rive fallback 或 mock 聊天。
6. Rive / SwiftUI fallback 不应包含独立人格、长期记忆或情绪决策逻辑。
