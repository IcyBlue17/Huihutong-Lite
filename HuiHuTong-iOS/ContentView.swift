import SwiftUI
import SwiftData
typealias ApartmentType = APIService.ApartmentType
typealias BuildingInfo = APIService.BuildingInfo

@available(iOS 17.0, *)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var isOpenIdValid = false
    @State private var isValidatingOpenId = true
    @State private var colorModePreference = 0 //0跟随系统,1浅色,2深色
    
    var body: some View {
        TabView(selection: $selectedTab) {
            if isValidatingOpenId {
                LoadingView(message: "正在验证OpenID...")
                    .tabItem {
                        Image(systemName: "qrcode")
                        Text("门禁")
                    }
                    .tag(0)
            } else if isOpenIdValid {
                AccessControlView(modelContext: modelContext)
                    .tabItem {
                        Image(systemName: "qrcode")
                        Text("门禁")
                    }
                    .tag(0)
            } else {
                DisabledView(message: "请先在个人信息页面设置有效的OpenID")
                    .tabItem {
                        Image(systemName: "qrcode")
                            .foregroundColor(.gray)
                        Text("门禁")
                            .foregroundColor(.gray)
                    }
                    .tag(0)
            }
            if isValidatingOpenId {
                LoadingView(message: "正在验证OpenID...")
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text("水电费")
                    }
                    .tag(1)
            } else if isOpenIdValid {
                UtilityBillView(modelContext: modelContext)
                    .tabItem {
                        Image(systemName: "bolt.fill")
                        Text("水电费")
                    }
                    .tag(1)
            } else {
                DisabledView(message: "请先在个人信息页面设置有效的OpenID")
                    .tabItem {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.gray)
                        Text("水电费")
                            .foregroundColor(.gray)
                    }
                    .tag(1)
            }
            PersonalInfoView(modelContext: modelContext, isOpenIdValid: $isOpenIdValid)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("个人信息")
                }
                .tag(2)
            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("关于")
                }
                .tag(3)
        }
        .onAppear {
            loadStartupPreferences()
            checkOpenIdValidation()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenIDUpdated"))) { _ in
            checkOpenIdValidation()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ColorModeChanged"))) { _ in
            loadColorModePreference()
        }
        .preferredColorScheme(getPreferredColorScheme())
        .onChange(of: isOpenIdValid) { newValue in
            if !newValue {
                selectedTab = 2 // 个人信息页面
            }
        }
    }
    private func checkOpenIdValidation() {
        Task {
            do {
                let settings = try await getAppSettings()
                if !settings.openId.isEmpty {
                    let apiService = APIService()
                    let satoken = try await apiService.getSatoken(openId: settings.openId)
                    let _ = try await apiService.getLoginInfo(satoken: satoken)
                    await MainActor.run {
                        isOpenIdValid = true
                        isValidatingOpenId = false
                    }
                } else {
                    await MainActor.run {
                        isOpenIdValid = false
                        isValidatingOpenId = false
                    }
                }
            } catch {
                await MainActor.run {
                    isOpenIdValid = false
                    isValidatingOpenId = false
                }
            }
        }
    }
    
    private func loadStartupPreferences() {
        Task {
            do {
                let settings = try await getAppSettings()
                await MainActor.run {
                    selectedTab = settings.startupTab
                    colorModePreference = settings.colorMode
                }
            } catch {
                await MainActor.run {
                    selectedTab = 0
                    colorModePreference = 0
                }
            }
        }
    }
    
    private func loadColorModePreference() {
        Task {
            do {
                let settings = try await getAppSettings()
                await MainActor.run {
                    colorModePreference = settings.colorMode
                }
            } catch {
            }
        }
    }
    
    private func getPreferredColorScheme() -> ColorScheme? {
        switch colorModePreference {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    private func getAppSettings() async throws -> AppSettings {
        return await MainActor.run {
            let descriptor = FetchDescriptor<AppSettings>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            do {
                let allSettings = try modelContext.fetch(descriptor)
                
                if let settings = allSettings.first {
                    return settings
                } else {
                    let newSettings = AppSettings()
                    modelContext.insert(newSettings)
                    try modelContext.save()
                    return newSettings
                }
            } catch {
                return AppSettings()
            }
        }
    }
}
struct DisabledView: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "lock.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("功能暂不可用")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()
            )
            .navigationTitle("慧湖通Lite")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
struct AccessControlView: View {
    let modelContext: ModelContext
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    Spacer()
                    Spacer()
                    
                    Text(viewModel.statusMessage)
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isLoading ? .orange : (colorScheme == .dark ? .white : .primary))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if let qrImage = viewModel.qrCodeImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: min(geometry.size.width * 0.8, 300),
                                   height: min(geometry.size.width * 0.8, 300))
                            .scaleEffect(viewModel.scaleFactor)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                            .onTapGesture {
                                viewModel.refreshQRCode()
                            }
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = max(0.4, min(1.0, value))
                                        viewModel.scaleFactor = newScale
                                    }
                                    .onEnded { _ in
                                        viewModel.saveSettings()
                                    }
                            )
                    } else {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color.gray.opacity(0.3))
                            .frame(width: min(geometry.size.width * 0.8, 300),
                                   height: min(geometry.size.width * 0.8, 300))
                            .cornerRadius(16)
                            .overlay(
                                VStack {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 40))
                                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                                        .padding(.bottom, 8)
                                    
                                    Text("等待二维码生成...")
                                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                                }
                            )
                            .onTapGesture {
                                viewModel.refreshQRCode()
                            }
                    }
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        if viewModel.countdownSeconds > 0 {
                            Text("二维码下次刷新还剩：\(viewModel.countdownSeconds)秒")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        } else {
                            Text("二维码刷新间隔已设置")
                                .font(.system(size: 14))
                                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        InfoRow(icon: "person.fill", title: "姓名", value: viewModel.userName, colorScheme: colorScheme)
                        InfoRow(icon: "building.fill", title: "单位", value: viewModel.companyName, colorScheme: colorScheme)
                        InfoRow(icon: "building.2.fill", title: "宿舍", value: viewModel.apartment.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ,", with: ""), colorScheme: colorScheme)
                        InfoRow(icon: "calendar.badge.clock", title: "生效", value: viewModel.passTime, colorScheme: colorScheme)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                        .ignoresSafeArea()
                )
            }
            .navigationTitle("慧湖通Lite")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("确定") {
                viewModel.showAlert = false
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .fontWeight(.medium)
        }
        .font(.system(size: 14))
    }
}
struct UtilityBillView: View {
    let modelContext: ModelContext
    @State private var selectedApartment: ApartmentType? = nil
    @State private var selectedBuilding: BuildingInfo? = nil
    @State private var selectedFloor: BuildingInfo? = nil
    @State private var selectedRoom: BuildingInfo? = nil
    @State private var availableBuildings: [BuildingInfo] = []
    @State private var availableFloors: [BuildingInfo] = []
    @State private var availableRooms: [BuildingInfo] = []
    @State private var billInfo: String = ""
    @State private var roomBalance: String = ""
    @State private var isLoadingBuildings = false
    @State private var isLoadingFloors = false
    @State private var isLoadingRooms = false
    @State private var isQueryingBalance = false
    @State private var isQueryingBill = false
    @State private var errorMessage = ""
    @State private var showError = false
    @Environment(\.colorScheme) var colorScheme
    private let apiService = APIService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("公寓")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Menu {
                        ForEach(ApartmentType.allCases, id: \.self) { apartment in
                            Button(apartment.name) {
                                selectedApartment = apartment
                                selectedBuilding = nil
                                selectedFloor = nil
                                selectedRoom = nil
                                availableBuildings = []
                                availableFloors = []
                                availableRooms = []
                                loadBuildings()
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedApartment?.name ?? "请选择公寓")
                                .foregroundColor(selectedApartment == nil ? .gray : (colorScheme == .dark ? .white : .primary))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isLoadingBuildings)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("楼栋")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        if isLoadingBuildings {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    Menu {
                        if availableBuildings.isEmpty && selectedApartment != nil && !isLoadingBuildings {
                            Button("暂无数据") { }
                                .disabled(true)
                        } else {
                            // 按楼栋分组
                            let groupedBuildings = Dictionary(grouping: availableBuildings) { $0.buildingName }
                            ForEach(Array(groupedBuildings.keys.sorted()), id: \.self) { buildingName in
                                Button(buildingName) {
                                    if let building = groupedBuildings[buildingName]?.first {
                                        selectedBuilding = building
                                        selectedFloor = nil
                                        selectedRoom = nil
                                        availableFloors = []
                                        availableRooms = []
                                        loadFloors()
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedBuilding?.buildingName ?? "请先选择公寓")
                                .foregroundColor((selectedBuilding == nil || selectedApartment == nil) ? .gray : (colorScheme == .dark ? .white : .primary))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(selectedApartment == nil || isLoadingBuildings)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("楼层")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        if isLoadingFloors {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    Menu {
                        if availableFloors.isEmpty && selectedBuilding != nil && !isLoadingFloors {
                            Button("暂无数据") { }
                                .disabled(true)
                        } else {
                            let groupedFloors = Dictionary(grouping: availableFloors) { $0.floorName }
                            ForEach(Array(groupedFloors.keys.sorted()), id: \.self) { floorName in
                                Button(floorName) {
                                    if let floor = groupedFloors[floorName]?.first {
                                        selectedFloor = floor
                                        selectedRoom = nil
                                        availableRooms = []
                                        loadRooms()
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedFloor?.floorName ?? "请先选择楼栋")
                                .foregroundColor((selectedFloor == nil || selectedBuilding == nil) ? .gray : (colorScheme == .dark ? .white : .primary))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(selectedBuilding == nil || isLoadingFloors)
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("寝室号")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        if isLoadingRooms {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    Menu {
                        if availableRooms.isEmpty && selectedFloor != nil && !isLoadingRooms {
                            Button("暂无数据") { }
                                .disabled(true)
                        } else {
                            ForEach(availableRooms, id: \.roomId) { room in
                                Button(room.roomName) {
                                    selectedRoom = room
                                    roomBalance = ""
                                    queryBalance()
                                    saveUtilitySelection()
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedRoom?.roomName ?? "请先选择楼层")
                                .foregroundColor((selectedRoom == nil || selectedFloor == nil) ? .gray : (colorScheme == .dark ? .white : .primary))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(selectedFloor == nil || isLoadingRooms)
                }
                if selectedRoom != nil {
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("电费余额")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Spacer()
                                
                                if isQueryingBalance {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(selectedRoom?.apartmentName ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(selectedRoom?.buildingName ?? "") - \(selectedRoom?.floorName ?? "") - \(selectedRoom?.roomName ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("余额")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if isQueryingBalance {
                                        Text("查询中...")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    } else if roomBalance.isEmpty {
                                        Text("未查询")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    } else {
                                        HStack(spacing: 4) {
                                            Text("¥")
                                                .font(.headline)
                                                .foregroundColor(.green)
                                            Text(roomBalance)
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        
                        HStack(spacing: 12) {
                            Button(action: queryBalance) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("刷新余额")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .foregroundColor(.blue)
                            }
                            .disabled(isQueryingBalance)
                            Button(action: rechargeBalance) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("充值")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                if selectedRoom != nil && !roomBalance.isEmpty && roomBalance != "--" {
                    Button(action: queryBill) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("查看消费详情")
                        }
                        .font(.system(size: 16))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
                if !billInfo.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("查询结果")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text(billInfo)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()
            )
            .navigationTitle("慧湖通Lite")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadSavedUtilitySelection()
        }
    }
    
    private func loadBuildings() {
        guard let apartment = selectedApartment else { return }
        
        isLoadingBuildings = true
        
        Task {
            do {
                guard let settings = try? await getAppSettings(),
                      !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isLoadingBuildings = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let buildings = try await apiService.getBuildingList(satoken: satoken, apartmentId: apartment.rawValue)
                
                await MainActor.run {
                    availableBuildings = buildings
                    isLoadingBuildings = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "获取楼栋信息失败：\(error.localizedDescription)"
                    showError = true
                    isLoadingBuildings = false
                }
            }
        }
    }
    
    private func loadFloors() {
        guard let apartment = selectedApartment,
              let building = selectedBuilding else { return }
        
        isLoadingFloors = true
        
        Task {
            do {
                guard let settings = try? await getAppSettings(),
                      !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isLoadingFloors = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let floors = try await apiService.getFloorList(satoken: satoken, apartmentId: apartment.rawValue, buildingId: building.buildingId)
                
                await MainActor.run {
                    availableFloors = floors
                    isLoadingFloors = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "获取楼层信息失败：\(error.localizedDescription)"
                    showError = true
                    isLoadingFloors = false
                }
            }
        }
    }
    
    private func loadRooms() {
        guard let apartment = selectedApartment,
              let building = selectedBuilding,
              let floor = selectedFloor else { return }
        
        isLoadingRooms = true
        
        Task {
            do {
                guard let settings = try? await getAppSettings(),
                      !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isLoadingRooms = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let rooms = try await apiService.getRoomList(satoken: satoken, apartmentId: apartment.rawValue, buildingId: building.buildingId, floorId: floor.floorId)
                
                await MainActor.run {
                    availableRooms = rooms
                    isLoadingRooms = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "获取房间信息失败：\(error.localizedDescription)"
                    showError = true
                    isLoadingRooms = false
                }
            }
        }
    }
    
    private func queryBill() {
        guard let building = selectedBuilding,
              let floor = selectedFloor,
              let room = selectedRoom else { return }
        
        isQueryingBill = true
    }
    
    private func queryBalance() {
        guard let apartment = selectedApartment,
              let room = selectedRoom,
              let roomId = room.id else { return }
        
        isQueryingBalance = true
        roomBalance = ""
        
        Task {
            do {
                guard let settings = try? await getAppSettings(),
                      !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isQueryingBalance = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let balance = try await apiService.getRoomBalance(satoken: satoken, apartmentId: apartment.rawValue, roomId: roomId)
                
                await MainActor.run {
                    roomBalance = balance
                    isQueryingBalance = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "查询余额失败：\(error.localizedDescription)"
                    showError = true
                    isQueryingBalance = false
                }
            }
        }
    }
    
    private func rechargeBalance() {
        // TODO: 实现充值功能
        errorMessage = "充值功能即将上线，敬请期待！"
        showError = true
    }
    
    private func saveUtilitySelection() {
        guard let apartment = selectedApartment,
              let building = selectedBuilding,
              let floor = selectedFloor,
              let room = selectedRoom else { return }
        
        Task {
            do {
                let settings = try await getAppSettings()
                settings.selectedApartmentId = apartment.rawValue
                settings.selectedBuildingId = building.buildingId
                settings.selectedFloorId = floor.floorId
                settings.selectedRoomId = room.roomId
                settings.selectedApartmentName = apartment.name
                settings.selectedBuildingName = building.buildingName
                settings.selectedFloorName = floor.floorName
                settings.selectedRoomName = room.roomName
                try await MainActor.run {
                    try modelContext.save()
                }
            } catch {
            }
        }
    }
    
    private func loadSavedUtilitySelection() {
        Task {
            do {
                let settings = try await getAppSettings()
                if settings.selectedApartmentId != 0,
                   let apartment = ApartmentType(rawValue: settings.selectedApartmentId) {
                    
                    await MainActor.run {
                        selectedApartment = apartment
                        if !settings.selectedBuildingName.isEmpty {
                            selectedBuilding = BuildingInfo(
                                roomId: settings.selectedRoomId,
                                roomName: settings.selectedRoomName,
                                id: settings.selectedRoomId,
                                apartmentName: settings.selectedApartmentName,
                                floorName: settings.selectedFloorName,
                                apartmentId: String(settings.selectedApartmentId),
                                buildingId: settings.selectedBuildingId,
                                buildingName: settings.selectedBuildingName,
                                xiaoquId: "",
                                fangJianId: settings.selectedRoomId,
                                floorId: settings.selectedFloorId
                            )
                        }
                        if !settings.selectedFloorName.isEmpty {
                            selectedFloor = BuildingInfo(
                                roomId: settings.selectedRoomId,
                                roomName: settings.selectedRoomName,
                                id: settings.selectedRoomId,
                                apartmentName: settings.selectedApartmentName,
                                floorName: settings.selectedFloorName,
                                apartmentId: String(settings.selectedApartmentId),
                                buildingId: settings.selectedBuildingId,
                                buildingName: settings.selectedBuildingName,
                                xiaoquId: "",
                                fangJianId: settings.selectedRoomId,
                                floorId: settings.selectedFloorId
                            )
                        }
                        
                        if !settings.selectedRoomName.isEmpty {
                            selectedRoom = BuildingInfo(
                                roomId: settings.selectedRoomId,
                                roomName: settings.selectedRoomName,
                                id: settings.selectedRoomId,
                                apartmentName: settings.selectedApartmentName,
                                floorName: settings.selectedFloorName,
                                apartmentId: String(settings.selectedApartmentId),
                                buildingId: settings.selectedBuildingId,
                                buildingName: settings.selectedBuildingName,
                                xiaoquId: "",
                                fangJianId: settings.selectedRoomId,
                                floorId: settings.selectedFloorId
                            )
                        }
                    }
                }
            } catch {
            }
        }
    }
    
    private func getAppSettings() async throws -> AppSettings {
        return await MainActor.run {
            let descriptor = FetchDescriptor<AppSettings>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            if let settings = try? modelContext.fetch(descriptor).first {
                return settings
            } else {
                // 如果没有设置记录，创建一个空的
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                return newSettings
            }
        }
    }
}

// 个人信息视图
struct PersonalInfoView: View {
    let modelContext: ModelContext
    @Binding var isOpenIdValid: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var openIdInput = ""
    @State private var showingOpenIdInput = false
    @State private var isValidating = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var personalInfo: APIService.LoginInfoData?
    @State private var userDetailInfo: APIService.UserInfoData?
    @State private var isLoading = false
    private let apiService = APIService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("OpenID 设置")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isOpenIdValid ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(isOpenIdValid ? "已验证" : "未验证")
                                    .font(.caption)
                                    .foregroundColor(isOpenIdValid ? .green : .red)
                            }
                        }
                        
                        Button(action: {
                            loadCurrentOpenId()
                            showingOpenIdInput = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text(isOpenIdValid ? "修改 OpenID" : "设置 OpenID")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .disabled(isValidating)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                    )
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("个人信息")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            
                            Spacer()
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        if let info = personalInfo {
                            VStack(spacing: 12) {
                                PersonalInfoRow(icon: "person.fill", title: "姓名", value: userDetailInfo?.name ?? info.name, colorScheme: colorScheme)
                                PersonalInfoRow(icon: "phone.fill", title: "手机号", value: info.phone, colorScheme: colorScheme)
                                PersonalInfoRow(icon: "creditcard.fill", title: "身份证", value: info.idCard, colorScheme: colorScheme)
                                PersonalInfoRow(icon: "number", title: "学号/工号", value: info.identifier, colorScheme: colorScheme)
                                PersonalInfoRow(icon: "person.crop.circle", title: "性别", value: info.sex == "1" ? "男" : (info.sex == "0" ? "女" : info.sex), colorScheme: colorScheme)
                                PersonalInfoRow(icon: "building.fill", title: "单位", value: userDetailInfo?.companyName ?? "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "building.2.fill", title: "宿舍", value: userDetailInfo?.apartment.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ,", with: "") ?? "-", colorScheme: colorScheme)
                            }
                        } else {
                            VStack(spacing: 12) {
                                PersonalInfoRow(icon: "person.fill", title: "姓名", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "phone.fill", title: "手机号", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "creditcard.fill", title: "身份证", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "number", title: "识别号", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "person.crop.circle", title: "性别", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "building.fill", title: "单位", value: "-", colorScheme: colorScheme)
                                PersonalInfoRow(icon: "building.2.fill", title: "宿舍", value: "-", colorScheme: colorScheme)
                            }
                        }
                        
                        if isOpenIdValid && personalInfo == nil {
                            Button(action: loadPersonalInfo) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("刷新信息")
                                }
                                .font(.system(size: 14))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue.opacity(0.1))
                                )
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                    )
                    PreferencesView(modelContext: modelContext)
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()
            )
            .navigationTitle("慧湖通Lite")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            loadSavedPersonalInfo()
            if isOpenIdValid && personalInfo == nil {
                loadPersonalInfo()
            }
        }
        .alert("设置 OpenID", isPresented: $showingOpenIdInput) {
            TextField("请输入 OpenID", text: $openIdInput)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Button("确定") {
                validateAndSaveOpenId()
            }
            .disabled(isValidating)
            
            Button("取消", role: .cancel) {
                showingOpenIdInput = false
            }
        } message: {
            if isValidating {
                Text("正在验证...")
            } else {
                Text("请输入从微信小程序抓包获取的 OpenID")
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCurrentOpenId() {
        Task {
            do {
                let settings = try await getAppSettings()
                await MainActor.run {
                    openIdInput = settings.openId
                }
            } catch {
                await MainActor.run {
                    openIdInput = ""
                }
            }
        }
    }
    
    private func validateAndSaveOpenId() {
        guard !openIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "OpenID 不能为空"
            showError = true
            showingOpenIdInput = false
            return
        }
        
        isValidating = true
        
        Task {
            do {
                // 验证OpenID
                let satoken = try await apiService.getSatoken(openId: openIdInput)
                let loginInfo = try await apiService.getLoginInfo(satoken: satoken)
                let userInfo = try await apiService.getUserInfo(satoken: satoken)
                
                // 保存OpenID
                let settings = try await getAppSettings()
                settings.openId = openIdInput
                
                try await MainActor.run {
                    try modelContext.save()
                    isOpenIdValid = true
                    personalInfo = loginInfo
                    userDetailInfo = userInfo
                    isValidating = false
                    showingOpenIdInput = false
                    savePersonalInfo(loginInfo: loginInfo, userInfo: userInfo)
                }
                
                // 通知父视图更新状态
                await MainActor.run {
                    // 触发ContentView重新检查OpenID状态
                    NotificationCenter.default.post(name: NSNotification.Name("OpenIDUpdated"), object: nil)
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    showingOpenIdInput = false
                    isOpenIdValid = false
                    personalInfo = nil
                    userDetailInfo = nil
                    errorMessage = "OpenID 验证失败：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func loadPersonalInfo() {
        guard isOpenIdValid else { return }
        
        isLoading = true
        
        Task {
            do {
                let settings = try await getAppSettings()
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let loginInfo = try await apiService.getLoginInfo(satoken: satoken)
                let userInfo = try await apiService.getUserInfo(satoken: satoken)
                
                await MainActor.run {
                    personalInfo = loginInfo
                    userDetailInfo = userInfo
                    isLoading = false
                    // 保存个人信息到本地
                    savePersonalInfo(loginInfo: loginInfo, userInfo: userInfo)
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "获取个人信息失败：\(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func savePersonalInfo(loginInfo: APIService.LoginInfoData, userInfo: APIService.UserInfoData) {
        Task {
            do {
                let settings = try await getAppSettings()
                
                // 将个人信息序列化为JSON字符串保存
                if let loginInfoData = try? JSONEncoder().encode(loginInfo),
                   let loginInfoJson = String(data: loginInfoData, encoding: .utf8) {
                    settings.savedPersonalInfoJson = loginInfoJson
                }
                
                if let userInfoData = try? JSONEncoder().encode(userInfo),
                   let userInfoJson = String(data: userInfoData, encoding: .utf8) {
                    settings.savedUserDetailInfoJson = userInfoJson
                }
                
                try await MainActor.run {
                    try modelContext.save()
                }
            } catch {
                print("保存个人信息失败: \(error)")
            }
        }
    }
    
    private func loadSavedPersonalInfo() {
        Task {
            do {
                let settings = try await getAppSettings()
                if !settings.openId.isEmpty {
                    var loadedPersonalInfo: APIService.LoginInfoData?
                    var loadedUserDetailInfo: APIService.UserInfoData?
                    
                    // 加载个人基本信息
                    if !settings.savedPersonalInfoJson.isEmpty,
                       let data = settings.savedPersonalInfoJson.data(using: .utf8) {
                        loadedPersonalInfo = try? JSONDecoder().decode(APIService.LoginInfoData.self, from: data)
                    }
                    
                    // 加载用户详细信息
                    if !settings.savedUserDetailInfoJson.isEmpty,
                       let data = settings.savedUserDetailInfoJson.data(using: .utf8) {
                        loadedUserDetailInfo = try? JSONDecoder().decode(APIService.UserInfoData.self, from: data)
                    }
                    
                    await MainActor.run {
                        personalInfo = loadedPersonalInfo
                        userDetailInfo = loadedUserDetailInfo
                    }
                }
            } catch {
                print("加载个人信息失败: \(error)")
            }
        }
    }
    
    private func getAppSettings() async throws -> AppSettings {
        return await MainActor.run {
            let descriptor = FetchDescriptor<AppSettings>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            
            if let settings = try? modelContext.fetch(descriptor).first {
                return settings
            } else {
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                return newSettings
            }
        }
    }
}

struct PersonalInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                .frame(width: 70, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .fontWeight(.medium)
        }
        .font(.system(size: 14))
    }
}
@available(iOS 17.0, *)
struct PreferencesView: View {
    let modelContext: ModelContext
    @Environment(\.colorScheme) var colorScheme
    @State private var currentSettings: AppSettings?
    @State private var selectedStartupTab = 0
    @State private var selectedColorMode = 0
    @State private var qrRefreshInterval = 15
    @State private var intervalInput = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("偏好设置")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                // 启动页面设置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("启动页面")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(StartupTab.allCases, id: \.rawValue) { tab in
                            Button(action: {
                                selectedStartupTab = tab.rawValue
                                savePreferences()
                            }) {
                                Text(tab.displayName)
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedStartupTab == tab.rawValue ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(selectedStartupTab == tab.rawValue ? .white : (colorScheme == .dark ? .white : .primary))
                            }
                        }
                        Spacer()
                    }
                }
                
                // 颜色模式设置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text("颜色模式")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(ColorMode.allCases, id: \.rawValue) { mode in
                            Button(action: {
                                selectedColorMode = mode.rawValue
                                savePreferences()
                                // 通知主界面更新颜色模式
                                NotificationCenter.default.post(name: NSNotification.Name("ColorModeChanged"), object: nil)
                            }) {
                                Text(mode.displayName)
                                    .font(.system(size: 12))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedColorMode == mode.rawValue ? Color.orange : Color.gray.opacity(0.2))
                                    )
                                    .foregroundColor(selectedColorMode == mode.rawValue ? .white : (colorScheme == .dark ? .white : .primary))
                            }
                        }
                        Spacer()
                    }
                }
                
                // 二维码刷新时间设置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(.green)
                            .frame(width: 20)
                        Text("二维码刷新时间")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        TextField("刷新间隔", text: $intervalInput)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                            .onSubmit {
                                updateRefreshInterval()
                            }
                        
                        Text("秒")
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        
                        Button(action: {
                            updateRefreshInterval()
                        }) {
                            Text("应用")
                                .font(.system(size: 12))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("(5-300秒)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
        )
        .onAppear {
            loadPreferences()
        }
    }
    
    private func updateRefreshInterval() {
        if let value = Int(intervalInput), value >= 5, value <= 300 {
            qrRefreshInterval = value
            savePreferences()
            // 通知MainViewModel更新刷新间隔
            NotificationCenter.default.post(name: NSNotification.Name("QRRefreshIntervalChanged"), object: value)
        } else {
            intervalInput = "\(qrRefreshInterval)"
        }
    }
    
    private func loadPreferences() {
        Task {
            do {
                let settings = try await getAppSettings()
                await MainActor.run {
                    currentSettings = settings
                    selectedStartupTab = settings.startupTab
                    selectedColorMode = settings.colorMode
                    qrRefreshInterval = settings.qrRefreshInterval
                    intervalInput = "\(settings.qrRefreshInterval)" // 同步输入框的值
                }
            } catch {
                print("加载偏好设置失败: \(error)")
            }
        }
    }
    
    private func savePreferences() {
        Task {
            do {
                let settings = try await getAppSettings()
                settings.startupTab = selectedStartupTab
                settings.colorMode = selectedColorMode
                settings.qrRefreshInterval = qrRefreshInterval
                
                try await MainActor.run {
                    try modelContext.save()
                }
            } catch {
                print("保存偏好设置失败: \(error)")
            }
        }
    }
    private func getAppSettings() async throws -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        let settings = try modelContext.fetch(descriptor)
        
        if let existingSettings = settings.first {
            return existingSettings
        } else {
            // 如果没有设置，创建新的
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try modelContext.save()
            return newSettings
        }
    }
}

// 加载页面视图
struct LoadingView: View {
    let message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .foregroundColor(.blue)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
            .modelContainer(for: AppSettings.self, inMemory: true)
    } else {
        Text("需要 iOS 17.0 或更高版本")
    }
}
