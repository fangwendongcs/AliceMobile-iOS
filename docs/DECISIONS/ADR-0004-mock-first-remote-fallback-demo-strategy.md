# ADR-0004: Mock-First Remote Fallback Demo Strategy

## 背景

短期 Web 后端仍在本地运行，iOS Demo 需要在没有后端、没有正式 Rive asset、没有 provider secret 时也可录屏。

## 决策

默认使用 Mock contract。Localhost / LAN IP 可连接本地 Web backend。Remote 失败时回退 Mock contract，并明确显示 disconnected / mock 状态。

## 原因

- Demo 不应因为本地后端未启动而不可用。
- iOS 第一阶段重点是状态展示和 contract 对齐，不是完整产品闭环。
- Mock contract 可以证明 UI 和 renderer 消费统一字段，而不复制后端业务逻辑。

## 后果

- Mock responder 只能返回固定 contract fixture，不做本地人格、记忆、情绪决策。
- 后端失败必须可恢复。
- Settings 和首页必须显示当前连接状态。
- 测试需要覆盖 decoding、fallback、avatar mapping 和 Rive missing fallback。

## 当前状态

Accepted。当前 App 已支持 Mock / Localhost / LAN IP 与 Remote fallback。
