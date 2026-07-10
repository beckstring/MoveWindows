import Testing
@testable import MoveWindowsCore

@Suite struct TransitionsTests {
    @Test func fullMatrix() {
        let expectations: [(SnapLayout?, Direction, LayoutCommand)] = [
            (nil, .left, .apply(.leftHalf)),
            (nil, .right, .apply(.rightHalf)),
            (nil, .up, .maximizeStoringCurrent),
            (nil, .down, .none),

            (.leftHalf, .left, .none),
            (.leftHalf, .right, .apply(.rightHalf)),
            (.leftHalf, .up, .apply(.topLeftQuarter)),
            (.leftHalf, .down, .apply(.bottomLeftQuarter)),

            (.rightHalf, .left, .apply(.leftHalf)),
            (.rightHalf, .right, .none),
            (.rightHalf, .up, .apply(.topRightQuarter)),
            (.rightHalf, .down, .apply(.bottomRightQuarter)),

            (.topLeftQuarter, .left, .none),
            (.topLeftQuarter, .right, .apply(.topRightQuarter)),
            (.topLeftQuarter, .up, .maximizeStoringCurrent),
            (.topLeftQuarter, .down, .apply(.leftHalf)),

            (.topRightQuarter, .left, .apply(.topLeftQuarter)),
            (.topRightQuarter, .right, .none),
            (.topRightQuarter, .up, .maximizeStoringCurrent),
            (.topRightQuarter, .down, .apply(.rightHalf)),

            (.bottomLeftQuarter, .left, .none),
            (.bottomLeftQuarter, .right, .apply(.bottomRightQuarter)),
            (.bottomLeftQuarter, .up, .apply(.leftHalf)),
            (.bottomLeftQuarter, .down, .none),

            (.bottomRightQuarter, .left, .apply(.bottomLeftQuarter)),
            (.bottomRightQuarter, .right, .none),
            (.bottomRightQuarter, .up, .apply(.rightHalf)),
            (.bottomRightQuarter, .down, .none),

            (.maximized, .left, .apply(.leftHalf)),
            (.maximized, .right, .apply(.rightHalf)),
            (.maximized, .up, .none),
            (.maximized, .down, .restorePrevious),
        ]
        for (state, direction, expected) in expectations {
            #expect(Transitions.transition(from: state, direction: direction) == expected,
                    "\(String(describing: state)) + \(direction)")
        }
    }

    @Test func composedSequencesMatchWindowsBehavior() {
        // Left then Up → top-left quarter (simulate by feeding detected states).
        #expect(Transitions.transition(from: nil, direction: .left) == .apply(.leftHalf))
        #expect(Transitions.transition(from: .leftHalf, direction: .up) == .apply(.topLeftQuarter))
        // Quarter ladder down: topLeft → leftHalf → bottomLeft → (no-op).
        #expect(Transitions.transition(from: .topLeftQuarter, direction: .down) == .apply(.leftHalf))
        #expect(Transitions.transition(from: .leftHalf, direction: .down) == .apply(.bottomLeftQuarter))
        #expect(Transitions.transition(from: .bottomLeftQuarter, direction: .down) == .none)
    }
}
