# ADR-0001: Use Native SwiftUI, Not WebView

## 背景

AliceMobile-iOS 需要成为 Alice Core 的 iOS 原生客户端。Web 项目已有 Three.js、DOM、CSS 和浏览器音频实现，但这些属于桌面 Web runtime。

## 决策

AliceMobile-iOS 使用 SwiftUI 原生实现，不使用 WebView 包装 Web 项目。

## 原因

- 原生 App 更适合系统级语音、设置、触控和未来移动端能力。
- WebView 会把 Web runtime 的复杂度直接带进 iOS。
- 当前目标是验证统一后端契约，而不是复刻 Web UI。

## 后果

- Web 项目只作为只读参考。
- iOS 需要维护自己的 SwiftUI UI、ViewModel 和 renderer abstraction。
- Web DOM、CSS、Three.js、FBX runtime 不迁移。

## 当前状态

Accepted。当前主线已按 SwiftUI 原生推进。
