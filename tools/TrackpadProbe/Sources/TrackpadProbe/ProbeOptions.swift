enum ProbeOptions: Equatable, Sendable {
    case check, help, requestTestAccess, capture(seconds: Int), captureDefault(seconds: Int), captureClicksDefault(seconds: Int), testFourFingerClose(seconds: Int)

    var observesButtons: Bool {
        switch self {
        case .captureClicksDefault, .testFourFingerClose: true
        default: false
        }
    }

    var postsTestShortcut: Bool {
        if case .testFourFingerClose = self { return true }
        return false
    }

    enum InvalidArguments: Error { case usage }

    init(arguments: [String]) throws {
        switch arguments {
        case [], ["--check"]: self = .check
        case ["--help"]: self = .help
        case ["--request-test-access"]: self = .requestTestAccess
        case ["--capture"]: self = .capture(seconds: 20)
        case ["--capture-default"]: self = .captureDefault(seconds: 20)
        case ["--capture-clicks-default"]: self = .captureClicksDefault(seconds: 20)
        case ["--test-four-finger-close"]: self = .testFourFingerClose(seconds: 20)
        default:
            guard arguments.count == 3, ["--capture", "--capture-default", "--capture-clicks-default", "--test-four-finger-close"].contains(arguments[0]), arguments[1] == "--seconds",
                  let seconds = Int(arguments[2]), (1...30).contains(seconds) else {
                throw InvalidArguments.usage
            }
            switch arguments[0] {
            case "--capture": self = .capture(seconds: seconds)
            case "--capture-default": self = .captureDefault(seconds: seconds)
            case "--test-four-finger-close": self = .testFourFingerClose(seconds: seconds)
            default: self = .captureClicksDefault(seconds: seconds)
            }
        }
    }
}
