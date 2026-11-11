@testable import ContextMenuKit
import Testing

@Suite("ContextMenuStateMachine")
struct ContextMenuStateMachineTests {
    typealias Event = ContextMenuStateMachine.Event

    static let allowedTransitions: [Transition] = [
        Transition(initialState: .idle, event: .pressBegan, expectedState: .pressing),
        Transition(initialState: .pressing, event: .pressCancelled, expectedState: .idle),
        Transition(initialState: .idle, event: .presentationBegan, expectedState: .presenting),
        Transition(initialState: .pressing, event: .presentationBegan, expectedState: .presenting),
        Transition(initialState: .presenting, event: .presentationFinished, expectedState: .presented),
        Transition(initialState: .presenting, event: .dismissalBegan, expectedState: .dismissing),
        Transition(initialState: .presented, event: .dismissalBegan, expectedState: .dismissing),
        Transition(initialState: .dismissing, event: .dismissalFinished, expectedState: .idle)
    ]

    static let rejectedEvents: [RejectedEvent] = ContextMenuState.allCases.flatMap { state in
        Event.allCases.compactMap { event in
            let isAllowed = allowedTransitions.contains { $0.initialState == state && $0.event == event }
            return isAllowed ? nil : RejectedEvent(state: state, event: event)
        }
    }

    @Test("Allowed event moves the machine to the next state", arguments: allowedTransitions)
    func allowedTransition(_ transition: Transition) {
        var machine = ContextMenuStateMachine(state: transition.initialState)

        let isHandled = machine.handle(transition.event)

        #expect(isHandled)
        #expect(machine.state == transition.expectedState)
    }

    @Test("Any other event is rejected and keeps the state", arguments: rejectedEvents)
    func rejectedEvent(_ rejectedEvent: RejectedEvent) {
        var machine = ContextMenuStateMachine(state: rejectedEvent.state)

        let isHandled = machine.handle(rejectedEvent.event)

        #expect(!isHandled)
        #expect(machine.state == rejectedEvent.state)
    }

    @Test("A full session with a long press goes back to idle")
    func fullSession() {
        var machine = ContextMenuStateMachine()

        let events: [Event] = [.pressBegan, .presentationBegan, .presentationFinished, .dismissalBegan, .dismissalFinished]
        let results = events.map { machine.handle($0) }

        #expect(results.allSatisfy { $0 })
        #expect(machine.state == .idle)
    }
}

struct Transition: Sendable, CustomTestStringConvertible {
    let initialState: ContextMenuState
    let event: ContextMenuStateMachine.Event
    let expectedState: ContextMenuState

    var testDescription: String {
        "\(initialState) + \(event) → \(expectedState)"
    }
}

struct RejectedEvent: Sendable, CustomTestStringConvertible {
    let state: ContextMenuState
    let event: ContextMenuStateMachine.Event

    var testDescription: String {
        "\(state) + \(event)"
    }
}
