
import Foundation
import SwiftData
enum StartupTab: Int, CaseIterable {
    case accessControl = 0
    case utilityBill = 1
    case personalInfo = 2
    case about = 3
    
    var displayName: String {
        switch self {
        case .accessControl: return "门禁"
        case .utilityBill: return "水电费"
        case .personalInfo: return "个人信息"
        case .about: return "关于"
        }
    }
}

// 颜色模式选项
enum ColorMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

@available(iOS 17.0, *)
@Model
final class AppSettings {
    var openId: String
    var satoken: String
    var scaleFactor: Double
    var timestamp: Date
    var savedPersonalInfoJson: String
    var savedUserDetailInfoJson: String
    var selectedApartmentId: Int
    var selectedBuildingId: String
    var selectedFloorId: String
    var selectedRoomId: String
    var selectedApartmentName: String
    var selectedBuildingName: String
    var selectedFloorName: String
    var selectedRoomName: String
    var startupTab: Int
    var colorMode: Int
    var qrRefreshInterval: Int
    init(openId: String = "", satoken: String = "", scaleFactor: Double = 1.0) {
        self.openId = openId
        self.satoken = satoken
        self.scaleFactor = scaleFactor
        self.timestamp = Date()
        self.savedPersonalInfoJson = ""
        self.savedUserDetailInfoJson = ""
        self.selectedApartmentId = 0
        self.selectedBuildingId = ""
        self.selectedFloorId = ""
        self.selectedRoomId = ""
        self.selectedApartmentName = ""
        self.selectedBuildingName = ""
        self.selectedFloorName = ""
        self.selectedRoomName = ""
        self.startupTab = 0
        self.colorMode = 0
        self.qrRefreshInterval = 15
    }
}
