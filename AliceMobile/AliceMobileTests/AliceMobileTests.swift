//
//  AliceMobileTests.swift
//  AliceMobileTests
//
//  Created by 方文栋 on 2026/6/6.
//

import Foundation
import Testing
@testable import AliceMobile

@MainActor
struct AliceMobileTests {

    @Test func personaMigrationIncludesExpectedCharacters() async throws {
        #expect(CompanionPersona.all.map(\.avatarId) == ["alice", "osa_shiro", "osa_wambo"])
        #expect(CompanionPersona.find(avatarId: "alice").personaId == "alice_default")
        #expect(CompanionPersona.find(avatarId: "osa_shiro").tone == "calm_gentle")
        #expect(CompanionPersona.find(avatarId: "osa_wambo").defaultMotion.positiveSlot == .chat)
    }

    @Test func motionSlotsMapToNativeAvatarStates() async throws {
        #expect(AvatarStateReducer.state(for: .headTap) == .headAction)
        #expect(AvatarStateReducer.state(for: .armTap) == .armAction)
        #expect(AvatarStateReducer.state(for: .legTap) == .legAction)
        #expect(AvatarStateReducer.state(for: .chat) == .reacting)
        #expect(AvatarStateReducer.state(for: .speaking) == .speaking)
    }

    @Test func riveAvatarStateMachineCodesStayStable() async throws {
        #expect(RiveAvatarAsset.fileName == "alice_avatar")
        #expect(RiveAvatarAsset.resourceName == "alice_avatar.riv")
        #expect(RiveAvatarAsset.expectedStateMachineName == "AliceAvatar")
        #expect(RiveAvatarInput.avatarState == "avatar_state")
        #expect(RiveAvatarInput.emotion == "emotion")
        #expect(RiveAvatarInput.tone == "tone")
        #expect(RiveAvatarInput.intensity == "intensity")
        #expect(RiveAvatarInput.isSpeaking == "is_speaking")
        #expect(RiveAvatarStateMachineBridge.code(for: AvatarState.idle) == 2)
        #expect(RiveAvatarStateMachineBridge.code(for: AvatarState.speaking) == 5)
        #expect(RiveAvatarStateMachineBridge.code(for: Emotion.happy) == 2)
        #expect(RiveAvatarStateMachineBridge.code(for: AffectTone.playful) == 1)
    }

    @Test func riveAssetStatusExplainsMissingAsset() async throws {
        let status = RiveAvatarAsset.status(in: Bundle(for: BundleProbe.self))

        #expect(status.isAvailable == false)
        #expect(status.label == "Using SwiftUI fallback")
        #expect(status.detail.contains("alice_avatar.riv"))
    }

    @Test func riveTapTriggersKeepBodyPartSemantics() async throws {
        #expect(RiveAvatarInput.tapTrigger(for: .head) == "tap_head")
        #expect(RiveAvatarInput.tapTrigger(for: .arm) == "tap_arm")
        #expect(RiveAvatarInput.tapTrigger(for: .leg) == "tap_leg")
        #expect(RiveAvatarInput.tapTrigger(for: .body) == "tap_body")
        #expect(RiveAvatarInput.tapTrigger(for: .chat) == "tap_chat")
    }

    @Test func mockDialogueKeepsIOSContractShape() async throws {
        let client = AliceAPIClient()
        let response = try await client.sendDialogue(
            DialogueRequest(
                message: "你好，测试状态",
                sessionId: "ios-test-session",
                avatarId: "alice",
                options: .mvpDefaults(avatarId: "alice", memoryEnabled: true)
            )
        )

        #expect(response.reply.contains("Alice"))
        #expect(response.companionState.isMock == true)
        #expect(response.avatarDirective.source == "mock_contract")
        #expect(response.meta.persona?.avatarId == "alice")
        #expect(response.memory.sessionId == "ios-test-session")
        #expect(response.memory.longTerm?.count == 0)
        #expect(response.affect.reason == "mock_contract")
        #expect(response.affect.motion.slot == .speaking)
    }

    @Test func remoteDialogueEnvelopeDecodesSuccessShape() async throws {
        let data = Data("""
        {
          "ok": true,
          "data": {
            "reply": "Remote dialogue is ready.",
            "affect": {
              "emotion": "warm",
              "intensity": 0.48,
              "tone": "gentle",
              "reason": "default_warm",
              "voice": { "style": "gentle", "rate": 1.02, "pitch": 1.1 },
              "motion": { "slot": "speaking", "intensity": 0.45 }
            },
            "meta": {
              "mode": "llm_stub",
              "orchestration": "agent_pipeline",
              "persona": {
                "avatarId": "alice",
                "personaId": "alice_default",
                "name": "Alice",
                "tone": "warm_playful",
                "voiceStyle": "gentle",
                "motionStyle": "light",
                "memoryStrategy": "session_scoped_conservative"
              },
              "provider": "stub",
              "model": "stub"
            }
          }
        }
        """.utf8)

        let response = try AliceAPIResponseDecoder.decodeDialogue(data: data)

        #expect(response.reply == "Remote dialogue is ready.")
        #expect(response.affect.motion.slot == .speaking)
        #expect(response.avatarDirective.state == .speaking)
        #expect(response.companionState.emotion == .warm)
        #expect(response.meta.persona?.avatarId == "alice")
    }

    @Test func webDialogueContractDecodesCompanionStateAndAvatarDirective() async throws {
        let data = Data("""
        {
          "ok": true,
          "data": {
            "reply_text": "Web contract reply.",
            "companion_state": {
              "status": "connected",
              "emotion": "curious",
              "tone": "calm",
              "avatar_state": "thinking",
              "memory_status": {
                "used": true,
                "status": "ready",
                "long_term_count": 2
              },
              "is_mock": false
            },
            "emotion": "happy",
            "tone": "playful",
            "avatar_directive": {
              "avatar_state": "reacting",
              "motion_slot": "happy",
              "intensity": 0.73,
              "duration_ms": 1200,
              "return_to": "idle",
              "source": "web_backend"
            },
            "memory": {
              "used": true,
              "status": "ready",
              "session_id": "ios-test-session",
              "avatar_id": "alice",
              "long_term": {
                "used": true,
                "status": "ready",
                "count": 2,
                "items": []
              }
            },
            "memory_status": {
              "used": true,
              "status": "ready",
              "long_term_count": 2
            },
            "tts_status": {
              "used": false,
              "status": "not_requested"
            }
          }
        }
        """.utf8)

        let response = try AliceAPIResponseDecoder.decodeDialogue(data: data)

        #expect(response.reply == "Web contract reply.")
        #expect(response.companionState.status == "connected")
        #expect(response.companionState.avatarState == .thinking)
        #expect(response.affect.emotion == .happy)
        #expect(response.affect.tone == .playful)
        #expect(response.avatarDirective.state == .reacting)
        #expect(response.avatarDirective.motionSlot == .happy)
        #expect(response.avatarDirective.source == "web_backend")
        #expect(response.memoryStatus.longTermCount == 2)
        #expect(response.ttsStatus.status == "not_requested")
    }

    @Test func remoteDialogueEnvelopeDecodesBackendError() async throws {
        let data = Data("""
        {
          "ok": false,
          "error": {
            "code": "LLM_NOT_CONFIGURED",
            "message": "Backend provider is not configured."
          }
        }
        """.utf8)

        do {
            _ = try AliceAPIResponseDecoder.decodeDialogue(data: data)
            Issue.record("Expected backend error.")
        } catch let error as AliceAPIError {
            #expect(error == .backend(code: "LLM_NOT_CONFIGURED", message: "Backend provider is not configured."))
        }
    }

    @Test func appSettingsRejectsNonHTTPBackendURL() async throws {
        #expect(AppSettingsStore.normalizedURL(from: "http://127.0.0.1:3000") != nil)
        #expect(AppSettingsStore.normalizedURL(from: "https://example.com") != nil)
        #expect(AppSettingsStore.normalizedURL(from: "file:///tmp/backend") == nil)
        #expect(AppSettingsStore.normalizedURL(from: "not a url") == nil)
        #expect(AppSettingsStore.normalizedAPIMode(from: "remote") == .localhost)
        #expect(AppSettingsStore.effectiveBackendBaseURLString(mode: .mock, lanBaseURL: "") == nil)
        #expect(AppSettingsStore.effectiveBackendBaseURLString(mode: .localhost, lanBaseURL: "") == "http://127.0.0.1:3000")
        #expect(AppSettingsStore.effectiveBackendBaseURL(mode: .lan, lanBaseURL: "") == nil)
        #expect(AppSettingsStore.effectiveBackendBaseURL(mode: .lan, lanBaseURL: "http://macbook.local:3000") != nil)
    }

    @Test func remoteDialogueFailureFallsBackToMockContract() async throws {
        let defaults = isolatedDefaults()
        let settings = AppSettingsStore(defaults: defaults)
        settings.apiMode = .localhost

        let fallbackResponse = DialogueResponse(
            reply: "Fallback mock contract.",
            memory: .empty(sessionId: settings.sessionId, avatarId: "alice", used: true),
            affect: Affect(
                emotion: .warm,
                intensity: 0.4,
                tone: .gentle,
                reason: "test_mock_contract",
                voice: .gentle,
                motion: MotionAffect(slot: .speaking, intensity: 0.4)
            ),
            companionState: CompanionState(status: "mock", emotion: .warm, tone: .gentle, avatarState: .speaking, isMock: true),
            avatarDirective: AvatarDirective(state: .speaking, motionSlot: .speaking, intensity: 0.4, source: "test_mock_contract"),
            ttsStatus: .notRequested
        )

        let viewModel = ChatViewModel(settingsStore: settings) { mode, _ in
            if mode == .mock {
                return FixtureAliceAPIClient(response: fallbackResponse)
            }
            return FailingAliceAPIClient()
        }

        viewModel.draft = "hello"
        viewModel.sendDraft()
        try await waitUntil { viewModel.messages.last?.text == "Fallback mock contract." }

        #expect(viewModel.connectionStateLabel == "disconnected")
        #expect(viewModel.errorMessage?.contains("已回退 Mock") == true)
        #expect(viewModel.messages.last?.text == "Fallback mock contract.")
        #expect(viewModel.companionState.isMock == true)
        #expect(viewModel.avatarState == .speaking)
        #expect(viewModel.avatarDirective.source == "test_mock_contract")
    }
}

private final class BundleProbe: NSObject {}

private struct FailingAliceAPIClient: AliceAPIClienting {
    var modeLabel: String { "Failing" }

    func health() async throws -> Bool {
        throw AliceAPIError.httpStatus(503)
    }

    func sendDialogue(_ request: DialogueRequest) async throws -> DialogueResponse {
        throw AliceAPIError.httpStatus(503)
    }

    func fetchMemory(sessionId: String, avatarId: String) async throws -> MemoryState {
        throw AliceAPIError.httpStatus(503)
    }
}

private struct FixtureAliceAPIClient: AliceAPIClienting {
    var response: DialogueResponse
    var modeLabel: String { "Fixture" }

    func health() async throws -> Bool {
        true
    }

    func sendDialogue(_ request: DialogueRequest) async throws -> DialogueResponse {
        response
    }

    func fetchMemory(sessionId: String, avatarId: String) async throws -> MemoryState {
        response.memory
    }
}

private func isolatedDefaults() -> UserDefaults {
    let suiteName = "AliceMobileTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

@MainActor
private func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    condition: @escaping () -> Bool
) async throws {
    let step: UInt64 = 25_000_000
    var elapsed: UInt64 = 0
    while elapsed < timeoutNanoseconds {
        if condition() {
            return
        }
        try await Task.sleep(nanoseconds: step)
        elapsed += step
    }
    Issue.record("Timed out waiting for async condition.")
}
