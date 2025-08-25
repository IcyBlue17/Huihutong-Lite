
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
    struct LoginInfoResponse: Codable {
        let success: Bool
        let message: String
        let code: Int
        let data: LoginInfoData?
        let timestamp: Int64
        let requestId: String
    }
    
    struct LoginInfoData: Codable {
        let account: String
        let birthday: String?
        let status: Int
        let post: String?
        let telephone: String?
        let idType: Int
        let sex: String
        let name: String
        let system: String?
        let salt: String?
        let idCard: String
        let id: String
        let identifier: String
        let departName: String?
        let email: String?
        let permissions: String?
        let phone: String
        let departId: String?
        let avatar: String?
        let password: String?
        let remark: String?
    }
    struct BuildingListResponse: Codable {
        let success: Bool
        let message: String
        let code: Int
        let result: [BuildingInfo]
        let data: String?
        let timestamp: Int64
    }
    
    struct BuildingInfo: Codable {
        let roomId: String
        let roomName: String
        let id: String?
        let apartmentName: String
        let floorName: String
        let apartmentId: String
        let buildingId: String
        let buildingName: String
        let xiaoquId: String?
        let fangJianId: String?
        let floorId: String
    }
    enum ApartmentType: Int, CaseIterable {
        case wenxing = 1    // 文星
        case wenhui = 2     // 文荟
        case wencui = 3     // 文萃
        case wenhua = 4     // 文华
        case wenyuan = 5    // 文缘
        
        var name: String {
            switch self {
            case .wenxing: return "文星学生公寓"
            case .wenhui: return "文荟学生公寓"
            case .wencui: return "文萃学生公寓"
            case .wenhua: return "文华人才公寓"
            case .wenyuan: return "文缘学生公寓"
            }
        }
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
    func getBuildingList(satoken: String, apartmentId: Int, buildingId: String = "", floorId: String = "", roomId: String = "") async throws -> [BuildingInfo] {
        guard let url = URL(string: "\(baseURL)/proxy/qy/sdcz/listBuilding?apartmentId=\(apartmentId)&buildingId=\(buildingId)&floorId=\(floorId)&roomId=\(roomId)") else {
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
        
        let buildingResponse = try JSONDecoder().decode(BuildingListResponse.self, from: data)
        return buildingResponse.result
    }
    func getFloorList(satoken: String, apartmentId: Int, buildingId: String) async throws -> [BuildingInfo] {
        guard let url = URL(string: "\(baseURL)/proxy/qy/sdcz/listFloor?apartmentId=\(apartmentId)&buildingId=\(buildingId)&floorId=&roomId=") else {
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
        
        let floorResponse = try JSONDecoder().decode(BuildingListResponse.self, from: data)
        return floorResponse.result
    }
    func getRoomList(satoken: String, apartmentId: Int, buildingId: String, floorId: String) async throws -> [BuildingInfo] {
        guard let url = URL(string: "\(baseURL)/proxy/qy/sdcz/listRoom?apartmentId=\(apartmentId)&buildingId=\(buildingId)&floorId=\(floorId)&roomId=") else {
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
        
        let roomResponse = try JSONDecoder().decode(BuildingListResponse.self, from: data)
        return roomResponse.result
    }
    struct BalanceResponse: Codable {
        let success: Bool
        let message: String
        let code: Int
        let result: String
        let data: String?
        let timestamp: Int64
    }
    func getRoomBalance(satoken: String, apartmentId: Int, roomId: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/proxy/qy/sdcz/getRoomBalance?apartmentId=\(apartmentId)&roomId=\(roomId)") else {
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
        
        let balanceResponse = try JSONDecoder().decode(BalanceResponse.self, from: data)
        return balanceResponse.result
    }
    func getLoginInfo(satoken: String) async throws -> LoginInfoData {
        guard let url = URL(string: "\(baseURL)/pms/welcome/login-info") else {
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
        
        let loginInfoResponse = try JSONDecoder().decode(LoginInfoResponse.self, from: data)
        guard loginInfoResponse.code == 200, let userData = loginInfoResponse.data else {
            throw NSError(domain: "APIError", code: loginInfoResponse.code, userInfo: [NSLocalizedDescriptionKey: loginInfoResponse.message])
        }
        
        return userData
    }
}
