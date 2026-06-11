# Web Migration Audit

本文记录本阶段从 `AI_Companion_alice` Web / Backend 项目迁移或参考到 `AliceMobile-iOS` 的内容。Web 项目只读参考，未修改。

## 读取的 mobile-handoff 文档

- `docs/mobile-handoff/PROJECT_CURRENT_STATUS.md`
- `docs/mobile-handoff/IOS_MIGRATION_SCOPE.md`
- `docs/mobile-handoff/PERSONA_SPEC.md`
- `docs/mobile-handoff/API_CONTRACT_FOR_IOS.md`
- `docs/mobile-handoff/DIALOGUE_FLOW_SPEC.md`
- `docs/mobile-handoff/EMOTION_STATE_SPEC.md`
- `docs/mobile-handoff/AVATAR_STATE_SPEC.md`
- `docs/mobile-handoff/MEMORY_SPEC.md`
- `docs/mobile-handoff/ASSET_INVENTORY.md`

## 只读查看的 Web 项目文件

Web 项目路径：

`/Users/fangwendong/02project/project/02数字人/myproject-Alice`

查看文件：

- `backend/config/avatarPersonas.js`
- `backend/routes/dialogueRoutes.js`
- `backend/services/DialogueOrchestrationService.js`
- `backend/services/CompanionAffectService.js`
- `backend/services/EmotionPolicy.js`
- `backend/services/TonePolicy.js`
- `public/avatars/registry.json`
- `public/avatars/alice/manifest.json`
- `public/avatars/osa_shiro/manifest.json`
- `public/avatars/osa_wambo/manifest.json`
- `js/animation/states.js`
- `js/animation/MotionSlotRegistry.js`
- `js/config/dialogues.js`
- `js/dialogue/DialogueManager.js`
- `js/ai/LLMClient.js`

## 已迁移 / 已参考

- 角色配置：Alice / Shiro / Wambo 的 `avatarId`、`personaId`、`name`、`summary`、`tone`、`boundaries`、默认 voice、默认 motion、`memoryStrategy`。
- 对话契约：`DialogueRequest`、`DialogueOptions`、`DialogueResponse`、`PersonaMeta`、`MemoryState`、`Affect` 的 Swift Codable 结构。
- 默认 API 模式：保留 `stub` / `mock` 本地演示路径，不调用真实模型。
- 情绪语义：`neutral`、`warm`、`happy`、`curious`、`thinking`、`apologetic`、`concerned`。
- 语气语义：`gentle`、`playful`、`calm`、`encouraging`。
- Motion slot：`idle`、`intro`、`headTap`、`legTap`、`armTap`、`bodyTap`、`chat`、`speaking`、`listening`，并为 iOS affect 补充 `thinking`、`happy`、`apologize`。
- Avatar state：`idle`、`listening`、`thinking`、`speaking`、`reacting`、`error`、`head_action`、`arm_action`、`leg_action` 等 Swift enum。
- 记忆边界：iOS 只保存非敏感 session/角色/开关，长期记忆主库以后端为准。
- Mock contract：保留固定 mock response fixture，用于展示统一契约字段，不在 iOS 本地做人格、记忆或情绪决策。

## 未迁移内容及原因

- Three.js、WebGL、FBXLoader、AnimationMixer：浏览器 3D runtime，不适合直接进入 SwiftUI MVP。
- Web AnimationController、MotionManager、ActionQueue：与 Web 3D 播放和 retarget 绑定，本阶段只迁移状态语义。
- DOM 控制器、CSS 和浏览器 UI：平台实现不同，iOS 使用 SwiftUI 原生视图。
- Browser speechSynthesis、Web Audio：浏览器专用；当前用 AVSpeechSynthesizer，本阶段不接后端 `/api/tts`。
- GLB / VRM / FBX 模型资产：授权、体积、骨骼兼容和原生渲染方案仍需单独评估。
- Node backend、RAG、n8n、Qdrant：继续作为后端能力，不在 iOS 本地运行。
- Web manifest 的 `model.url`、`transform`、`camera`、`hitRegions`、`retargeting`：与 Web runtime 强绑定，本阶段不作为 iOS 运行依赖。
- `.env`、API key、webhook secret、provider secret：安全风险，不进入移动端。

## 当前 iOS MVP 对应文件

- `AliceMobile/AliceMobile/Models/Persona.swift`
- `AliceMobile/AliceMobile/Models/AffectModels.swift`
- `AliceMobile/AliceMobile/Models/AvatarState.swift`
- `AliceMobile/AliceMobile/Models/DialogueModels.swift`
- `AliceMobile/AliceMobile/Services/AliceAPIClient.swift`
- `AliceMobile/AliceMobile/Stores/AppSettingsStore.swift`
- `AliceMobile/AliceMobile/ViewModels/ChatViewModel.swift`
- `AliceMobile/AliceMobile/Views/CompanionHomeView.swift`

## 安全审计结论

- 本阶段没有新增真实密钥、证书、Apple 账号或 Provisioning Profile。
- `AliceAPIClient` 默认 `.mock`，不会自动请求真实后端。
- Localhost / LAN IP 模式只接 `/api/health` 与 `/api/dialogue`，不硬编码 token。
- `.gitignore` 已覆盖 Xcode 用户状态、构建产物、环境文件、证书、私钥、provisioning profile 和常见服务配置文件。
