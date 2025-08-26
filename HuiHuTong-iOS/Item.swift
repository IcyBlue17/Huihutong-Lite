
import Foundation
import SwiftData

@available(iOS 17.0, *)
@Model
final class AppSettings {
    var openId: String
    var satoken: String
    var scaleFactor: Double
    var timestamp: Date
    
    // 偏好设置
    var startupTab: Int
    var colorMode: Int // 0跟随系统,1浅色,2深色
    var qrRefreshInterval: Int
    
    // 水电费选择记录
    var selectedApartmentId: Int
    var selectedBuildingId: String
    var selectedFloorId: String
    var selectedRoomId: String
    var selectedApartmentName: String
    var selectedBuildingName: String
    var selectedFloorName: String
    var selectedRoomName: String
    
    // 个人信息缓存
    var savedPersonalInfoJson: String
    var savedUserDetailInfoJson: String
    
    init(openId: String = "", satoken: String = "", scaleFactor: Double = 1.0) {
        self.openId = openId
        self.satoken = satoken
        self.scaleFactor = scaleFactor
        self.timestamp = Date()
        
        // 初始化偏好设置
        self.startupTab = 0
        self.colorMode = 0
        self.qrRefreshInterval = 15
        
        // 初始化选择记录
        self.selectedApartmentId = 0
        self.selectedBuildingId = ""
        self.selectedFloorId = ""
        self.selectedRoomId = ""
        self.selectedApartmentName = ""
        self.selectedBuildingName = ""
        self.selectedFloorName = ""
        self.selectedRoomName = ""
        
        // 初始化个人信息缓存
        self.savedPersonalInfoJson = ""
        self.savedUserDetailInfoJson = ""
    }
}

// 辅助枚举
enum StartupTab: Int, CaseIterable {
    case access = 0
    case utility = 1
    case profile = 2
    case about = 3
    
    var displayName: String {
        switch self {
        case .access: return "门禁"
        case .utility: return "水电费"
        case .profile: return "个人信息"
        case .about: return "关于"
        }
    }
}

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
