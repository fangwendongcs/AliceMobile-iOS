# Rive Integration

AliceMobile-iOS 已通过 Swift Package Manager 接入官方 `rive-ios` package 的 `RiveRuntime` 产品。当前实现保持 mock-first 和 SwiftUI fallback：如果正式 `.riv` 素材缺失，App 仍然可以打开、聊天、切换角色并展示状态。

## 资源约定

- 文件名：`alice_avatar.riv`
- 放置位置：`AliceMobile/AliceMobile/alice_avatar.riv`
- 推荐默认 state machine 名称：`AliceAvatar`

当前代码用 `Bundle.main.url(forResource: "alice_avatar", withExtension: "riv")` 检测资源，并用 `RiveViewModel(fileName: "alice_avatar", stateMachineName: nil)` 加载默认 state machine。请在 Rive Editor 中把正式状态机设为默认，或后续在代码里显式填入状态机名称。

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
