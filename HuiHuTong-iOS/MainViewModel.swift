import SwiftUI
import SwiftData
@available(iOS 17.0, *)
@MainActor
class MainViewModel: ObservableObject {
    @Published var qrCodeImage: UIImage?
    @Published var statusMessage = "准备中..."
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var scaleFactor: Double = 1.0
    @Published var showAbout = false
    @Published var userName = "-"
    @Published var apartment = "-"
    @Published var passTime = "-"
    @Published var companyName = "-"
    private let apiService = APIService()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 15.0
    private var currentQRData: String?

    var settings: AppSettings?
    var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }

    private func loadSettings() {
        guard let context = modelContext else { return }
    
        let descriptor = FetchDescriptor<AppSettings>()
        if let existingSettings = try? context.fetch(descriptor).first {
            settings = existingSettings
            scaleFactor = existingSettings.scaleFactor
        } else {
            let newSettings = AppSettings()
            context.insert(newSettings)
            settings = newSettings
            try? context.save()
        }
    }
    
    func saveSettings() {
        guard let context = modelContext, let settings = settings else { return }
        
        settings.scaleFactor = scaleFactor
        try? context.save()
    }
    
    func updateOpenId(_ newOpenId: String) {
        guard let settings = settings else { return }
        
        settings.openId = newOpenId
        settings.satoken = ""
        saveSettings()
        
        refreshQRCode()
    }
    
    func refreshQRCode() {
        stopTimer()
        
        guard let settings = settings, !settings.openId.isEmpty else {
            statusMessage = "请先设置 OpenID"
            showInputAlert()
            return
        }
        
        Task {
            await generateQRCode()
        }
    }
    
    private func generateQRCode() async {
        guard let settings = settings else { return }
        
        isLoading = true
        statusMessage = "正在更新二维码..."
        
        do {
            let token = try await apiService.getSatoken(openId: settings.openId)
            settings.satoken = token
            saveSettings()
        } catch {
            statusMessage = "获取失败，点击二维码重试"
            alertMessage = "获取认证token失败：\(error.localizedDescription)\n\nOpenID 可能无效，请重新设置"
            showAlert = true
            isLoading = false
            return
        }
        do {
            let qrData = try await apiService.getQRCodeData(satoken: settings.satoken)
            async let userInfoResult: APIService.UserInfoData? = {
                do {
                    return try await apiService.getUserInfo(satoken: settings.satoken)
                } catch {
                    print("获取用户信息失败: \(error)")
                    return nil
                }
            }()
            
            currentQRData = qrData
            
            if let image = QRCodeGenerator.generateQRCode(from: qrData) {
                qrCodeImage = image
                statusMessage = "二维码更新成功！"
                if let userInfo = await userInfoResult {
                    userName = userInfo.name
                    apartment = userInfo.apartment
                    passTime = userInfo.passTime
                    companyName = userInfo.companyName
                }
                
                startTimer()
            } else {
                statusMessage = "获取失败，点击二维码重试"
                alertMessage = "二维码生成失败，请重试"
                showAlert = true
            }
            
        } catch {
            statusMessage = "获取失败，点击二维码重试"
            alertMessage = "网络异常或数据错误：\(error.localizedDescription)"
            showAlert = true
        }
        
        isLoading = false
    }
    
    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.generateQRCode()
            }
        }
    }
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func showInputAlert() {
        alertMessage = "请输入从微信小程序抓包获取的 OpenID"
        showAlert = true
    }
    
    func showAboutInfo() {
        showAbout = true
    }
    
    func onAppear() {
        refreshQRCode()
    }
    
    func onDisappear() {
        stopTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
