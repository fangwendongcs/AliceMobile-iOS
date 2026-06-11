# ADR-0002: Use Rive As Current Avatar Mainline And Keep VRM As Future Spike

## 背景

项目需要 Avatar 表现层。候选方向包括 SwiftUI fallback、Rive、VRM、SceneKit、RealityKit 和 Web 3D runtime。

## 决策

当前主线使用 Rive + SwiftUI fallback。VRM 只保留为未来 Phase 5 技术验证，不进入当前主线。

## 原因

- Rive 适合轻量状态机、录屏 Demo 和跨状态输入。
- SwiftUI fallback 可在 `.riv` 缺失时保持 App 可用。
- VRM 涉及授权、包体、骨骼、动作、性能和 renderer runtime，不适合当前阶段。
- 当前核心目标是 Alice Core contract 对齐，不是 3D 技术证明。

## 后果

- `AvatarRendering` 必须保持 renderer 抽象。
- 不允许业务逻辑绑定具体 `.riv` 或未来 `.vrm` 文件。
- 正式 `alice_avatar.riv` 缺失时必须继续 SwiftUI fallback。
- 后续 VRM spike 不能替换当前 Rive 主线，除非用户明确改变路线并同步文档。

## 当前状态

Accepted。RiveRuntime 已接入，SwiftUI fallback 仍是安全底线。
