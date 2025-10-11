import Foundation
import SwiftData
import UIKit

// MARK: - 超时错误
struct TimeoutError: Error {
    let message = "请求超时"
}

// MARK: - 超时函数
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

// MARK: - 公共工具方法
@available(iOS 17.0, *)
extension ModelContext {
    /// 获取或创建AppSettings
    func getOrCreateAppSettings() -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        if let settings = try? fetch(descriptor).first {
            return settings
        } else {
            let newSettings = AppSettings()
            insert(newSettings)
            try? save()
            return newSettings
        }
    }
}

// MARK: - 错误处理辅助
struct ErrorHandler {
    static func errorMessage(for error: Error) -> String {
        if let decodingError = error as? DecodingError {
            return "数据解析错误：\(decodingError.localizedDescription)"
        } else if let urlError = error as? URLError {
            return "网络错误：\(urlError.localizedDescription)"
        } else {
            return error.localizedDescription
        }
    }
}

// MARK: - 日期格式化工具
class DateFormatters {
    static let chineseDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

// MARK: - 外部应用跳转
struct ExternalAppHelper {
    static func openWeChat(onError: @escaping (String) -> Void) {
        guard let url = URL(string: "weixin://") else {
            onError("无法打开微信")
            return
        }
        
        UIApplication.shared.open(url) { success in
            if !success {
                DispatchQueue.main.async {
                    onError("无法打开微信，请确保已安装微信应用")
                }
            }
        }
    }
}

// MARK: - 字符串清理扩展
extension String {
    /// 清理宿舍地址字符串
    var cleanedApartmentString: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ,", with: "")
    }
    
    /// 清理后如果为空返回"-"
    var cleanedOrDash: String {
        let cleaned = cleanedApartmentString
        return cleaned.isEmpty ? "-" : cleaned
    }
}

// MARK: - 性别显示辅助
extension String {
    var genderDisplay: String {
        switch self {
        case "1": return "男"
        case "0": return "女"
        default: return self
        }
    }
}

