
import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class AppSettings {
    var openId: String
    var satoken: String
    var scaleFactor: Double
    var timestamp: Date
    
    init(openId: String = "", satoken: String = "", scaleFactor: Double = 1.0) {
        self.openId = openId
        self.satoken = satoken
        self.scaleFactor = scaleFactor
        self.timestamp = Date()
    }
}
