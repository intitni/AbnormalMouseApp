import Foundation

private let defaultQueue = DispatchQueue(label: "com.intii.abnormalmouse.default")

extension DispatchQueue {
    static var `default`: DispatchQueue { defaultQueue }
}
