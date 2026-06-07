//
//  AliceMobileTests.swift
//  AliceMobileTests
//
//  Created by 方文栋 on 2026/6/6.
//

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

}
