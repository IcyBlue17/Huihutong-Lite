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
    @Published var userName = "-"
    @Published var apartment = "-"
    @Published var passTime = "-"
    @Published var companyName = "-"
    @Published var countdownSeconds = 0 // 倒计时秒数
    private let apiService = APIService()
    private var refreshTimer: Timer?
    private var countdownTimer: Timer? // 倒计时定时器
    private var refreshInterval: TimeInterval = 15.0 // 默认刷新间隔
    private var currentQRData: String?

    var settings: AppSettings?
    var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSettings()
    }

    private func loadSettings() {
        guard let context = modelContext else { return }
        
        settings = context.getOrCreateAppSettings()
        scaleFactor = settings?.scaleFactor ?? 1.0
        refreshInterval = TimeInterval(settings?.qrRefreshInterval ?? 15)
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
            // 设置5秒超时
            let token = try await withTimeout(seconds: 5) {
                try await self.apiService.getSatoken(openId: settings.openId)
            }
            settings.satoken = token
            saveSettings()
        } catch is TimeoutError {
            statusMessage = "获取超时，点击二维码重试"
            alertMessage = "网络请求超时，请检查网络连接后重试"
            showAlert = true
            isLoading = false
            return
        } catch {
            statusMessage = "获取失败，点击二维码重试"
            alertMessage = "获取认证token失败：\(error.localizedDescription)\n\nOpenID 可能无效，请重新设置"
            showAlert = true
            isLoading = false
            return
        }
        
        do {
            // 设置5秒超时
            let qrData = try await withTimeout(seconds: 5) {
                try await self.apiService.getQRCodeData(satoken: settings.satoken)
            }
            
            async let userInfoResult: APIService.UserInfoData? = {
                do {
                    return try await withTimeout(seconds: 5) {
                        try await self.apiService.getUserInfo(satoken: settings.satoken)
                    }
                } catch {
                    return nil
                }
            }()
            
            currentQRData = qrData
            
            if let image = QRCodeGenerator.generateQRCode(from: qrData) {
                qrCodeImage = image
                statusMessage = "门禁码已更新，点击可刷新"
                if let userInfo = await userInfoResult {
                    userName = userInfo.name
                    apartment = userInfo.apartment
                    passTime = userInfo.passTime
                    companyName = userInfo.companyName
                }
                
                // 确保isLoading设置为false，这样文字颜色就不会是橙色
                isLoading = false
                startTimer()
            } else {
                statusMessage = "获取失败，点击二维码重试"
                alertMessage = "二维码生成失败，请重试"
                showAlert = true
                isLoading = false
            }
            
        } catch is TimeoutError {
            statusMessage = "获取超时，点击二维码重试"
            alertMessage = "网络请求超时，请检查网络连接后重试"
            showAlert = true
            isLoading = false
        } catch {
            statusMessage = "获取失败，点击二维码重试"
            alertMessage = "网络异常或数据错误：\(error.localizedDescription)"
            showAlert = true
            isLoading = false
        }
    }
    
    private func startTimer() {
        stopCountdownTimer() // 停止之前的倒计时
        
        // 设置倒计时
        countdownSeconds = Int(refreshInterval)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.countdownSeconds > 0 {
                    self.countdownSeconds -= 1
                } else {
                    self.stopCountdownTimer()
                }
            }
        }
        
        // 设置刷新定时器
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
        stopCountdownTimer()
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        countdownSeconds = 0
    }
    
    // 更新刷新间隔设置
    func updateRefreshInterval(_ interval: Int) {
        refreshInterval = TimeInterval(interval)
        // 如果正在运行，重新启动定时器
        if refreshTimer != nil {
            stopTimer()
            if qrCodeImage != nil {
                startTimer()
            }
        }
    }
    
    func showInputAlert() {
        alertMessage = "请输入从微信小程序抓包获取的 OpenID"
        showAlert = true
    }
    
    func onAppear() {
        refreshQRCode()
        // 监听刷新间隔变化通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("QRRefreshIntervalChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let newInterval = notification.object as? Int {
                self?.updateRefreshInterval(newInterval)
            }
        }
    }
    
    func onDisappear() {
        stopTimer()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("QRRefreshIntervalChanged"), object: nil)
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
