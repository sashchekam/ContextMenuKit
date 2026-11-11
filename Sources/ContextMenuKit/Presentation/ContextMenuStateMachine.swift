/// Phase of a menu session.
enum ContextMenuState: CaseIterable, Equatable {
    case idle
    /// The source view is being pressed down; nothing is shown yet.
    case pressing
    /// The preview is lifting and the menu is expanding.
    case presenting
    case presented
    /// The preview is flying back; the selected action, if any, waits for the end.
    case dismissing
}

/// Allowed transitions between the phases of a menu session.
///
/// Every command goes through ``handle(_:)``: a rejected event means the command came
/// too late or twice (a tap during the dismissal, a stale animation completion) and must be ignored.
struct ContextMenuStateMachine {
    enum Event: CaseIterable, Equatable {
        case pressBegan
        case pressCancelled
        case presentationBegan
        case presentationFinished
        case dismissalBegan
        case dismissalFinished
    }

    private(set) var state: ContextMenuState

    init(state: ContextMenuState = .idle) {
        self.state = state
    }

    static func nextState(from state: ContextMenuState, on event: Event) -> ContextMenuState? {
        switch (state, event) {
        case (.idle, .pressBegan):
            .pressing
        case (.pressing, .pressCancelled):
            .idle
        case (.idle, .presentationBegan), (.pressing, .presentationBegan):
            .presenting
        case (.presenting, .presentationFinished):
            .presented
        case (.presenting, .dismissalBegan), (.presented, .dismissalBegan):
            .dismissing
        case (.dismissing, .dismissalFinished):
            .idle
        default:
            nil
        }
    }

    /// Applies the event if it is allowed in the current state.
    /// - Returns: `true` if the state has changed.
    @discardableResult
    mutating func handle(_ event: Event) -> Bool {
        guard let nextState = Self.nextState(from: state, on: event) else {
            return false
        }
        state = nextState
        return true
    }
}
