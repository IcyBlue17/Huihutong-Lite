
import Foundation
import UIKit

class Tracker {
    private let baseURL = "https://huihu-api.icybit.cn"
    private let authToken = "114514."
    
    // 追踪数据结构
    struct TrackingData: Codable {
        let device_model: String
        let ios_version: String
        let idfv: String
        let timestamp: Int64
    }
    
    // 响应数据结构
    struct TrackingResponse: Codable {
        let code: Int
    }
    
    // 发送追踪数据
    func sendTrackingData() {
        Task {
            do {
                // 获取设备型号
                let deviceModel = await getDeviceModel()
                
                // 获取 iOS 版本
                let iosVersion = UIDevice.current.systemVersion
                
                // 获取 IDFV (Identifier for Vendor)
                let idfv = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
                
                // 获取时间戳（毫秒）
                let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                
                // 构造追踪数据
                let trackingData = TrackingData(
                    device_model: deviceModel,
                    ios_version: iosVersion,
                    idfv: idfv,
                    timestamp: timestamp
                )
                
                // 发送到服务器
                try await postTrackingData(trackingData)
                
                print("✅ 追踪数据发送成功")
            } catch {
                print("❌ 追踪数据发送失败: \(error.localizedDescription)")
            }
        }
    }
    
    // 获取设备型号
    private func getDeviceModel() async -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier
    }
    
    // POST 发送数据到服务器
    private func postTrackingData(_ data: TrackingData) async throws {
        guard let url = URL(string: "\(baseURL)/v1/tracker") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authToken, forHTTPHeaderField: "Huihu-Auth-token")
        
        // 将数据编码为 JSON
        let jsonData = try JSONEncoder().encode(data)
        request.httpBody = jsonData
        
        // 调试输出
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 发送追踪数据: \(jsonString)")
        }
        
        // 发送请求
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📥 服务器响应状态码: \(httpResponse.statusCode)")
        
        // 尝试解析响应
        if let responseString = String(data: responseData, encoding: .utf8) {
            print("📥 服务器响应内容: \(responseString)")
        }
        
        // 解析响应
        let trackingResponse = try JSONDecoder().decode(TrackingResponse.self, from: responseData)
        
        // 检查返回的 code 是否为 200
        if trackingResponse.code != 200 {
            throw NSError(
                domain: "TrackerError",
                code: trackingResponse.code,
                userInfo: [NSLocalizedDescriptionKey: "服务器返回错误，code: \(trackingResponse.code)"]
            )
        }
    }
}

