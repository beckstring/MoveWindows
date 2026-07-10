public enum LayoutCommand: Equatable, Sendable {
    case apply(SnapLayout)
    case maximizeStoringCurrent
    case restorePrevious
    case none
}

/// Windows Win+Arrow semantics: halves compose with Up/Down into quarters,
/// quarters ladder up to maximize and down to halves, maximized+Down restores.
/// Down on floating/bottom states is a deliberate no-op (Windows minimizes there;
/// changing that is a one-line edit in this table).
public enum Transitions {
    public static func transition(from current: SnapLayout?, direction: Direction) -> LayoutCommand {
        switch (current, direction) {
        case (nil, .left): return .apply(.leftHalf)
        case (nil, .right): return .apply(.rightHalf)
        case (nil, .up): return .maximizeStoringCurrent
        case (nil, .down): return .none

        case (.leftHalf, .left): return .none
        case (.leftHalf, .right): return .apply(.rightHalf)
        case (.leftHalf, .up): return .apply(.topLeftQuarter)
        case (.leftHalf, .down): return .apply(.bottomLeftQuarter)

        case (.rightHalf, .left): return .apply(.leftHalf)
        case (.rightHalf, .right): return .none
        case (.rightHalf, .up): return .apply(.topRightQuarter)
        case (.rightHalf, .down): return .apply(.bottomRightQuarter)

        case (.topLeftQuarter, .left): return .none
        case (.topLeftQuarter, .right): return .apply(.topRightQuarter)
        case (.topLeftQuarter, .up): return .maximizeStoringCurrent
        case (.topLeftQuarter, .down): return .apply(.leftHalf)

        case (.topRightQuarter, .left): return .apply(.topLeftQuarter)
        case (.topRightQuarter, .right): return .none
        case (.topRightQuarter, .up): return .maximizeStoringCurrent
        case (.topRightQuarter, .down): return .apply(.rightHalf)

        case (.bottomLeftQuarter, .left): return .none
        case (.bottomLeftQuarter, .right): return .apply(.bottomRightQuarter)
        case (.bottomLeftQuarter, .up): return .apply(.leftHalf)
        case (.bottomLeftQuarter, .down): return .none

        case (.bottomRightQuarter, .left): return .apply(.bottomLeftQuarter)
        case (.bottomRightQuarter, .right): return .none
        case (.bottomRightQuarter, .up): return .apply(.rightHalf)
        case (.bottomRightQuarter, .down): return .none

        case (.maximized, .left): return .apply(.leftHalf)
        case (.maximized, .right): return .apply(.rightHalf)
        case (.maximized, .up): return .none
        case (.maximized, .down): return .restorePrevious
        }
    }
}
