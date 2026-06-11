# Docs Index

本索引用于后续 agent 快速恢复项目上下文。每次接手任务时先读“必须阅读”，再按任务类型读取参考文档。

## 必须阅读

1. `../AGENTS.md`
   - 强约束入口：允许做什么、禁止做什么、测试和 Git 边界。
2. `PROJECT_CONTEXT.md`
   - 产品定位、阶段路线、当前做和不做的范围。
3. `ARCHITECTURE.md`
   - SwiftUI、ViewModel、API client、renderer、Voice Output 的职责边界。
4. `CODEX_HANDOFF.md`
   - 当前真实状态、近期完成内容、风险、缺失和下一步。
5. `API_CONTRACT.md`
   - 当前 iOS 需要消费的后端契约和 fallback 规则。

## 常用参考

- `../README.md`
  - 面向项目运行和 Demo 的简明说明。
- `DEMO_ACCEPTANCE.md`
  - 录屏和手动验收清单。
- `RIVE_INTEGRATION.md`
  - Rive asset、state machine input、SwiftUI fallback 规则。
- `UI_STYLE_REFERENCE.md`
  - 当前视觉方向和 UI 约束。
- `WEB_MIGRATION_AUDIT.md`
  - 从 Web 项目只读参考过哪些内容，以及哪些内容不能迁移。

## Mobile Handoff 参考

`mobile-handoff/` 目录来自 Web 项目到 iOS 的迁移上下文。它们是历史和语义参考，不自动覆盖当前主线。

- `mobile-handoff/API_CONTRACT_FOR_IOS.md`
- `mobile-handoff/PROJECT_CURRENT_STATUS.md`
- `mobile-handoff/IOS_MIGRATION_SCOPE.md`
- `mobile-handoff/DIALOGUE_FLOW_SPEC.md`
- `mobile-handoff/AVATAR_STATE_SPEC.md`
- `mobile-handoff/EMOTION_STATE_SPEC.md`
- `mobile-handoff/MEMORY_SPEC.md`
- `mobile-handoff/PERSONA_SPEC.md`
- `mobile-handoff/ASSET_INVENTORY.md`

如果这些文档与 `PROJECT_CONTEXT.md`、`ARCHITECTURE.md` 或 `API_CONTRACT.md` 冲突，以当前长期记忆文档为准，并在任务报告中说明冲突来源。

## ADR

`DECISIONS/` 记录已经做出的技术决策：

- `DECISIONS/ADR-0001-use-native-swiftui-not-webview.md`
- `DECISIONS/ADR-0002-use-rive-as-current-avatar-mainline-and-keep-vrm-as-future-spike.md`
- `DECISIONS/ADR-0003-keep-ios-client-secret-free.md`
- `DECISIONS/ADR-0004-mock-first-remote-fallback-demo-strategy.md`

## 文档更新规则

- 不把同一段大文本复制到多个文档。
- README 只保留运行和入口信息。
- PROJECT_CONTEXT 记录产品路线和阶段边界。
- ARCHITECTURE 记录代码职责和技术边界。
- API_CONTRACT 记录当前 App 实际消费的后端契约。
- CODEX_HANDOFF 记录每轮交接和当前风险。
- ADR 记录不应反复争论的技术选择。
- 修改架构、路线、API 契约或验收标准时，必须同步更新对应文档。
