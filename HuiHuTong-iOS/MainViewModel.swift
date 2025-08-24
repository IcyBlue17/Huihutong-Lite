
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
    private let apiService = APIService()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 15.0 // 多久刷新一次
    private var currentQRData: String?
    private var originalBrightness: CGFloat = 0.5
    
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
            onQRCodeHidden()
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
            if settings.satoken.isEmpty {
                let token = try await apiService.getSatoken(openId: settings.openId)
                settings.satoken = token
                saveSettings()
            }
            
            let qrData = try await apiService.getQRCodeData(satoken: settings.satoken)
            
            currentQRData = qrData
            
            if let image = QRCodeGenerator.generateQRCode(from: qrData) {
                qrCodeImage = image
                statusMessage = "二维码更新成功！"
                onQRCodeGenerated()
                startTimer()
            } else {
                onQRCodeHidden()
                throw NSError(domain: "QRCodeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "生成二维码失败"])
            }
            
        } catch {
            if error.localizedDescription.contains("token") || error.localizedDescription.contains("401") {
                do {
                    let newToken = try await apiService.getSatoken(openId: settings.openId)
                    settings.satoken = newToken
                    saveSettings()
                    
                    let qrData = try await apiService.getQRCodeData(satoken: settings.satoken)
                    if let image = QRCodeGenerator.generateQRCode(from: qrData) {
                        qrCodeImage = image
                        statusMessage = "二维码更新成功！"
                        onQRCodeGenerated()
                        startTimer()
                    }
                } catch {
                    statusMessage = "更新失败：\(error.localizedDescription)"
                    alertMessage = "OpenID 可能无效，请重新设置"
                    showAlert = true
                    onQRCodeHidden()
                    scheduleRetry()
                }
            } else {
                statusMessage = "返回数据异常，可能是OpenID输入有误，正在重试..."
                onQRCodeHidden()
                scheduleRetry()
            }
        }
        
        isLoading = false
    }
    
    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: false) { _ in
            Task {
                await self.generateQRCode()
            }
        }
    }
    
    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func scheduleRetry() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            Task {
                await self.generateQRCode()
            }
        }
    }
    
    func showInputAlert() {
        alertMessage = "请输入从微信小程序抓包获取的 OpenID"
        showAlert = true
    }
    
    func showAboutInfo() {
        showAbout = true
    }
    
    func setMaxBrightness() {
        originalBrightness = UIScreen.main.brightness
        UIScreen.main.brightness = 1.0
    }
    
    func restoreOriginalBrightness() {
        UIScreen.main.brightness = originalBrightness
    }
    
    func onAppear() {
        originalBrightness = UIScreen.main.brightness
        refreshQRCode()
    }
    
    func onDisappear() {
        restoreOriginalBrightness()
        stopTimer()
    }
    
    // 当二维码生成成功时调用
    func onQRCodeGenerated() {
        setMaxBrightness()
    }
    
    // 当二维码消失或生成失败时调用
    func onQRCodeHidden() {
        restoreOriginalBrightness()
    }
    
    deinit {
        Task { @MainActor in
            stopTimer()
        }
    }
}
