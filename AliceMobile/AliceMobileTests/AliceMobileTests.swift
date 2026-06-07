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
        #expect(response.meta.persona?.avatarId == "alice")
        #expect(response.memory.sessionId == "ios-test-session")
        #expect(response.affect.motion.slot == .speaking || response.affect.motion.slot == .idle)
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
        #expect(response.meta.persona?.avatarId == "alice")
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
    }

}

private final class BundleProbe: NSObject {}
