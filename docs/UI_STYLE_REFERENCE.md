# Alice Mobile UI Style Reference

本项目当前本地设计参考图已保存到：

`docs/design-references/alice-mobile-ui-reference.png`

该目录已加入 `.gitignore`，图片只作为本机视觉参考，不提交到 Git。

## 设计方向

- 近黑沉浸背景，避免普通 dashboard 感。
- 首屏优先展示 Avatar 舞台，而不是功能说明或表格。
- 顶部采用左侧菜单、中央品牌名、右侧设置的轻量结构。
- 主色使用紫色微光，辅以少量青绿色、暖黄色状态色。
- 面板使用低透明度深色玻璃质感、细描边、8px 圆角。
- 声音/聆听状态用紫色声波、微光和轻量脉冲表达。
- 设置页参考“我的空间 / 伙伴设置”的卡片化信息层级。

## 后续 UI 约束

- 新增 UI 时优先复用 `AliceTheme` 和 `AliceMetrics`。
- 不把设计稿图片作为运行时资源。
- RiveRuntime 已接入；`alice_avatar.riv` 缺失或不可用时，`SwiftUIAvatarView` 继续作为 fallback。
- 保持 Mock 默认和无密钥输入框的安全边界。
