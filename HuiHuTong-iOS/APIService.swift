
import Foundation

class APIService: ObservableObject {
    private let baseURL = "https://api.215123.cn"
    
    struct LoginResponse: Codable {
        let data: LoginData
    }
    
    struct LoginData: Codable {
        let token: String
    }
    
    struct QRCodeResponse: Codable {
        let data: String
    }
    
    struct UserInfoResponse: Codable {
        let success: Bool
        let message: String
        let code: Int
        let data: UserInfoData
        let timestamp: Int64
        let requestId: String
    }
    
    struct UserInfoData: Codable {
        let lockedName: String?
        let passTime: String
        let phone: String
        let qrCode: String
        let mackCode: Int
        let lockedCount: Int
        let apartment: String
        let locked: Int
        let text: String
        let qrCodeStatus: Int
        let companyName: String
        let status: Int
        let name: String
    }
    func getSatoken(openId: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/web-app/auth/certificateLogin?openId=\(openId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
        return loginResponse.data.token
    }
    
    func getQRCodeData(satoken: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/pms/welcome/make-qrcode") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(satoken, forHTTPHeaderField: "satoken")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let qrResponse = try JSONDecoder().decode(QRCodeResponse.self, from: data)
        return qrResponse.data
    }
    
    func getUserInfo(satoken: String) async throws -> UserInfoData {
        guard let url = URL(string: "\(baseURL)/pms/welcome/make-code-info") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(satoken, forHTTPHeaderField: "satoken")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let userInfoResponse = try JSONDecoder().decode(UserInfoResponse.self, from: data)
        return userInfoResponse.data
    }
}
