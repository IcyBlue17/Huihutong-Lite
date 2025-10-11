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
        .preferredColorScheme(getPreferredColorScheme())
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
        await MainActor.run {
            modelContext.getOrCreateAppSettings()
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
        .navigationViewStyle(StackNavigationViewStyle())
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
                        InfoRow(icon: "building.2.fill", title: "宿舍", value: viewModel.apartment.cleanedApartmentString, colorScheme: colorScheme)
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
        .navigationViewStyle(StackNavigationViewStyle())
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
    @State private var selectedApartmentId: Int? = nil
    @State private var selectedBuilding: BuildingInfo? = nil
    @State private var selectedFloor: BuildingInfo? = nil
    @State private var selectedRoom: BuildingInfo? = nil
    @State private var buildingList: [BuildingInfo] = []
    @State private var floorList: [BuildingInfo] = []
    @State private var roomList: [BuildingInfo] = []
    @State private var roomBalance: String = ""
    @State private var queryTimestamp: Date? = nil
    @State private var isLoadingBuildings = false
    @State private var isLoadingFloors = false
    @State private var isLoadingRooms = false
    @State private var isQueryingBalance = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showComingSoon = false
    @Environment(\.colorScheme) var colorScheme
    private let apiService = APIService()
    
    // 公寓列表定义
    private let apartments = [
        (id: 1, name: "文星学生公寓", available: true),
        (id: 2, name: "文缘学生公寓", available: false),
        (id: 3, name: "文萃学生公寓", available: false),
        (id: 4, name: "文华学生公寓", available: false),
        (id: 5, name: "文荟学生公寓", available: false)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
            VStack(spacing: 20) {
                    // 步骤1: 选择公寓
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("选择公寓")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                            Spacer()
                        }
                        
                        ForEach(apartments, id: \.id) { apartment in
                            Button(action: {
                                if apartment.available {
                                    selectApartment(apartment.id)
                                } else {
                                    showComingSoon = true
                                }
                            }) {
                                HStack {
                                    Text(apartment.name)
                                        .font(.system(size: 15))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                                    Spacer()
                                    
                                    if !apartment.available {
                                        Text("开发中")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    
                                    if selectedApartmentId == apartment.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                            .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedApartmentId == apartment.id ? 
                                              Color.blue.opacity(0.1) : 
                                              (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.3)))
                                )
                            }
                        }
                        
                        if isLoadingBuildings {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在加载楼栋信息...")
                        .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                    )
                    
                    // 步骤2: 选择楼栋
                    if !buildingList.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "2.circle.fill")
                                    .foregroundColor(.green)
                                Text("选择楼栋")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                Spacer()
                            }
                            
                            // 去重并获取唯一的楼栋
                            let uniqueBuildings = Dictionary(grouping: buildingList, by: { $0.buildingId })
                                .compactMap { $0.value.first }
                                .sorted { $0.buildingName < $1.buildingName }
                            
                            ForEach(uniqueBuildings, id: \.buildingId) { building in
                                Button(action: {
                                    selectBuilding(building)
                                }) {
                                    HStack {
                                        Text(building.buildingName)
                                            .font(.system(size: 15))
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Spacer()
                                
                                        if selectedBuilding?.buildingId == building.buildingId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedBuilding?.buildingId == building.buildingId ? 
                                                  Color.green.opacity(0.1) : 
                                                  (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.3)))
                                    )
                                }
                            }
                            
                            if isLoadingFloors {
                            HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("正在加载楼层信息...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                        )
                    }
                    
                    // 步骤3: 选择楼层
                    if !floorList.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "3.circle.fill")
                                    .foregroundColor(.orange)
                                Text("选择楼层")
                                    .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                Spacer()
                            }
                            
                            // 去重并获取唯一的楼层
                            let uniqueFloors = Dictionary(grouping: floorList, by: { $0.floorId })
                                .compactMap { $0.value.first }
                                .sorted { Int($0.floorId) ?? 0 < Int($1.floorId) ?? 0 }
                            
                            ForEach(uniqueFloors, id: \.floorId) { floor in
                                Button(action: {
                                    selectFloor(floor)
                                }) {
                                    HStack {
                                        Text(floor.floorName)
                                            .font(.system(size: 15))
                                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Spacer()
                                
                                        if selectedFloor?.floorId == floor.floorId {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.orange)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedFloor?.floorId == floor.floorId ? 
                                                  Color.orange.opacity(0.1) : 
                                                  (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.3)))
                                    )
                                }
                            }
                            
                            if isLoadingRooms {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("正在加载房间信息...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                        )
                    }
                    
                    // 步骤4: 选择房间（折叠菜单）
                    if !roomList.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "4.circle.fill")
                                    .foregroundColor(.purple)
                                Text("选择房间")
                                                .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                Spacer()
                            }
                            
                            Picker("选择房间", selection: Binding(
                                get: { selectedRoom?.id ?? "" },
                                set: { newValue in
                                    if let room = roomList.first(where: { $0.id == newValue }) {
                                        selectRoom(room)
                                    }
                                }
                            )) {
                                Text("请选择房间").tag("")
                                ForEach(roomList, id: \.id) { room in
                                    Text(room.roomName).tag(room.id ?? "")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6).opacity(0.5))
                            )
                            
                            if let room = selectedRoom {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.purple)
                                    Text("已选择：\(room.roomName)")
                                        .font(.subheadline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                        )
                    }
                        
                    // 底部操作按钮
                    if selectedRoom != nil {
                        HStack(spacing: 12) {
                            Button(action: {
                                if let apartmentId = selectedApartmentId,
                                   let roomId = selectedRoom?.id {
                                    queryRoomBalance(apartmentId: apartmentId, roomId: roomId)
                                }
                            }) {
                                HStack {
                                    if isQueryingBalance {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(isQueryingBalance ? "查询中..." : "立即查询")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
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
                            .disabled(isQueryingBalance)
                            
                            Button(action: openWeChat) {
                                HStack {
                                    Image(systemName: "message.fill")
                                    Text("打开微信")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
                        )
                    }
                    
                    // 余额显示卡片
                    if !roomBalance.isEmpty, let timestamp = queryTimestamp {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("电费余额")
                                    .font(.headline)
                                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("查询时间：")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatDate(timestamp))
                                        .font(.subheadline)
                                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("余额")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Text("¥")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text(roomBalance)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.green)
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
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        )
                    }
                    
                    Spacer()
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
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadSavedSelection()
        }
        .alert("提示", isPresented: $showComingSoon) {
            Button("确定") {
                showComingSoon = false
            }
        } message: {
            Text("该公寓功能开发中，敬请期待！")
        }
        .alert("错误", isPresented: $showError) {
            Button("确定") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 选择公寓
    private func selectApartment(_ apartmentId: Int) {
        selectedApartmentId = apartmentId
        resetSelectionFrom(level: 1)
        loadBuildingList(apartmentId: apartmentId)
    }
    
    // 重置选择（从指定层级开始）
    private func resetSelectionFrom(level: Int) {
        if level <= 1 {
            selectedBuilding = nil
            buildingList = []
        }
        if level <= 2 {
            selectedFloor = nil
            floorList = []
        }
        if level <= 3 {
            selectedRoom = nil
            roomList = []
        }
        roomBalance = ""
        queryTimestamp = nil
    }
    
    // MARK: - 加载楼栋列表
    private func loadBuildingList(apartmentId: Int) {
        isLoadingBuildings = true
        
        Task {
            do {
                let settings = try await getAppSettings()
                guard !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isLoadingBuildings = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let buildings = try await apiService.getBuildingList(satoken: satoken, apartmentId: apartmentId)
                
                await MainActor.run {
                    buildingList = buildings
                    isLoadingBuildings = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "加载楼栋失败：\(ErrorHandler.errorMessage(for: error))"
                    showError = true
                    isLoadingBuildings = false
                }
            }
        }
    }
    
    // MARK: - 选择楼栋
    private func selectBuilding(_ building: BuildingInfo) {
        selectedBuilding = building
        resetSelectionFrom(level: 2)
        saveUserSelection()
        
        guard let apartmentId = selectedApartmentId else { return }
        loadFloorList(apartmentId: apartmentId, buildingId: building.buildingId)
    }
    
    // MARK: - 加载楼层列表
    private func loadFloorList(apartmentId: Int, buildingId: String) {
        isLoadingFloors = true
        
        Task {
            do {
                let settings = try await getAppSettings()
                guard !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isLoadingFloors = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let floors = try await apiService.getFloorList(satoken: satoken, apartmentId: apartmentId, buildingId: buildingId)
                
                await MainActor.run {
                    floorList = floors
                    isLoadingFloors = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "加载楼层失败：\(ErrorHandler.errorMessage(for: error))"
                    showError = true
                    isLoadingFloors = false
                }
            }
        }
    }
    
    // MARK: - 选择楼层
    private func selectFloor(_ floor: BuildingInfo) {
        selectedFloor = floor
        resetSelectionFrom(level: 3)
        saveUserSelection()
        
        guard let apartmentId = selectedApartmentId,
              let building = selectedBuilding else { return }
        loadRoomList(apartmentId: apartmentId, buildingId: building.buildingId, floorId: floor.floorId)
    }
    
    // MARK: - 加载房间列表
    private func loadRoomList(apartmentId: Int, buildingId: String, floorId: String) {
        isLoadingRooms = true
        
        Task {
            do {
                let settings = try await getAppSettings()
                guard !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                    showError = true
                        isLoadingRooms = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let rooms = try await apiService.getRoomList(satoken: satoken, apartmentId: apartmentId, buildingId: buildingId, floorId: floorId)
                
                await MainActor.run {
                    roomList = rooms
                    isLoadingRooms = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "加载房间失败：\(ErrorHandler.errorMessage(for: error))"
                    showError = true
                    isLoadingRooms = false
                }
            }
        }
    }
    
    // MARK: - 选择房间（不自动查询）
    private func selectRoom(_ room: BuildingInfo) {
        selectedRoom = room
        // 保存用户的选择
        saveUserSelection()
    }
    
    // MARK: - 查询房间余额
    private func queryRoomBalance(apartmentId: Int, roomId: String) {
        isQueryingBalance = true
        
        Task {
            do {
                let settings = try await getAppSettings()
                guard !settings.openId.isEmpty else {
                    await MainActor.run {
                        errorMessage = "请先在个人信息页面设置OpenID"
                        showError = true
                        isQueryingBalance = false
                    }
                    return
                }
                
                let satoken = try await apiService.getSatoken(openId: settings.openId)
                let balance = try await apiService.getRoomBalance(satoken: satoken, apartmentId: apartmentId, roomId: roomId)
                
                await MainActor.run {
                    roomBalance = balance
                    queryTimestamp = Date()
                    isQueryingBalance = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "查询余额失败：\(ErrorHandler.errorMessage(for: error))"
            showError = true
                    isQueryingBalance = false
                }
            }
        }
    }
    
    // MARK: - 格式化日期
    private func formatDate(_ date: Date) -> String {
        DateFormatters.chineseDateTime.string(from: date)
    }
    
    // MARK: - 保存用户选择
    private func saveUserSelection() {
        Task {
            do {
                let settings = try await getAppSettings()
                
                settings.selectedApartmentId = selectedApartmentId ?? 0
                settings.selectedBuildingId = selectedBuilding?.buildingId ?? ""
                settings.selectedBuildingName = selectedBuilding?.buildingName ?? ""
                settings.selectedFloorId = selectedFloor?.floorId ?? ""
                settings.selectedFloorName = selectedFloor?.floorName ?? ""
                settings.selectedRoomId = selectedRoom?.id ?? ""
                settings.selectedRoomName = selectedRoom?.roomName ?? ""
                
                // 获取公寓名称
                if let apartmentId = selectedApartmentId {
                    let apartmentName = apartments.first(where: { $0.id == apartmentId })?.name ?? ""
                    settings.selectedApartmentName = apartmentName
                }
                
                try await MainActor.run {
                    try modelContext.save()
                }
            } catch {
                // 保存失败时静默处理
            }
        }
    }
    
    // MARK: - 加载已保存的选择
    private func loadSavedSelection() {
        Task {
            do {
                let settings = try await getAppSettings()
                
                // 如果有保存的选择，恢复状态
                if settings.selectedApartmentId != 0 {
                    await MainActor.run {
                        selectedApartmentId = settings.selectedApartmentId
                    }
                    
                    // 加载楼栋列表
                    let satoken = try await apiService.getSatoken(openId: settings.openId)
                    let buildings = try await apiService.getBuildingList(satoken: satoken, apartmentId: settings.selectedApartmentId)
                    
                    await MainActor.run {
                        buildingList = buildings
                        
                        // 恢复选中的楼栋
                        if !settings.selectedBuildingId.isEmpty {
                            selectedBuilding = buildings.first(where: { $0.buildingId == settings.selectedBuildingId })
                            
                            if selectedBuilding != nil {
                                // 加载楼层列表
                                Task {
                                    do {
                                        let floors = try await apiService.getFloorList(
                                            satoken: satoken,
                                            apartmentId: settings.selectedApartmentId,
                                            buildingId: settings.selectedBuildingId
                                        )
                                        
                                        await MainActor.run {
                                            floorList = floors
                                            
                                            // 恢复选中的楼层
                                            if !settings.selectedFloorId.isEmpty {
                                                selectedFloor = floors.first(where: { $0.floorId == settings.selectedFloorId })
                                                
                                                if selectedFloor != nil {
                                                    // 加载房间列表
                                                    Task {
                                                        do {
                                                            let rooms = try await apiService.getRoomList(
                                                                satoken: satoken,
                                                                apartmentId: settings.selectedApartmentId,
                                                                buildingId: settings.selectedBuildingId,
                                                                floorId: settings.selectedFloorId
                                                            )
                                                            
                                                            await MainActor.run {
                                                                roomList = rooms
                                                                
                                                                // 恢复选中的房间
                                                                if !settings.selectedRoomId.isEmpty {
                                                                    selectedRoom = rooms.first(where: { $0.id == settings.selectedRoomId })
                                                                }
                                                            }
                                                        } catch {
                                                            // 加载失败时静默处理
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        // 加载失败时静默处理
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                // 加载失败时静默处理
            }
        }
    }
    
    // MARK: - 打开微信
    private func openWeChat() {
        ExternalAppHelper.openWeChat { error in
            self.errorMessage = error
            self.showError = true
        }
    }
    
    private func getAppSettings() async throws -> AppSettings {
        await MainActor.run {
            modelContext.getOrCreateAppSettings()
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
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    OpenIdSettingsSection(
                        isOpenIdValid: isOpenIdValid,
                        isValidating: isValidating,
                        colorScheme: colorScheme,
                        onOpenIdSetup: {
                            loadCurrentOpenId()
                            showingOpenIdInput = true
                        }
                    )
                    
                    if let info = personalInfo {
                        PersonalInfoSection(
                            personalInfo: info,
                            userDetailInfo: userDetailInfo,
                            colorScheme: colorScheme
                        )
                    } else {
                        EmptyPersonalInfoSection(
                            isOpenIdValid: isOpenIdValid,
                            isLoading: isLoading,
                            colorScheme: colorScheme,
                            onRefresh: loadPersonalInfo
                        )
                    }
                    
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
        .navigationViewStyle(StackNavigationViewStyle())
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
                // 保存失败时静默处理
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
                // 加载失败时静默处理
            }
        }
    }
    
    private func getAppSettings() async throws -> AppSettings {
        await MainActor.run {
            modelContext.getOrCreateAppSettings()
        }
    }
}

// 分离OpenID设置板块
struct OpenIdSettingsSection: View {
    let isOpenIdValid: Bool
    let isValidating: Bool
    let colorScheme: ColorScheme
    let onOpenIdSetup: () -> Void
    
    var body: some View {
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
            
            Button(action: onOpenIdSetup) {
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
    }
}

// 分离个人信息板块
struct PersonalInfoSection: View {
    let personalInfo: APIService.LoginInfoData
    let userDetailInfo: APIService.UserInfoData?
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("个人信息")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                PersonalInfoRow(icon: "person.fill", title: "姓名", value: userDetailInfo?.name ?? personalInfo.name, colorScheme: colorScheme)
                PersonalInfoRow(icon: "phone.fill", title: "手机号", value: personalInfo.phone, colorScheme: colorScheme)
                PersonalInfoRow(icon: "creditcard.fill", title: "身份证", value: personalInfo.idCard, colorScheme: colorScheme)
                PersonalInfoRow(icon: "number", title: "学号/工号", value: personalInfo.identifier, colorScheme: colorScheme)
                PersonalInfoRow(icon: "person.crop.circle", title: "性别", value: personalInfo.sex.genderDisplay, colorScheme: colorScheme)
                PersonalInfoRow(icon: "building.fill", title: "单位", value: userDetailInfo?.companyName ?? "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "building.2.fill", title: "宿舍", value: (userDetailInfo?.apartment ?? "").cleanedOrDash, colorScheme: colorScheme)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.6) : Color(.systemGray6).opacity(0.3))
        )
    }
}

// 空个人信息板块
struct EmptyPersonalInfoSection: View {
    let isOpenIdValid: Bool
    let isLoading: Bool
    let colorScheme: ColorScheme
    let onRefresh: () -> Void
    
    var body: some View {
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
            
            VStack(spacing: 12) {
                PersonalInfoRow(icon: "person.fill", title: "姓名", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "phone.fill", title: "手机号", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "creditcard.fill", title: "身份证", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "number", title: "识别号", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "person.crop.circle", title: "性别", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "building.fill", title: "单位", value: "-", colorScheme: colorScheme)
                PersonalInfoRow(icon: "building.2.fill", title: "宿舍", value: "-", colorScheme: colorScheme)
            }
            
            if isOpenIdValid {
                Button(action: onRefresh) {
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
                    selectedStartupTab = settings.startupTab
                    selectedColorMode = settings.colorMode
                    qrRefreshInterval = settings.qrRefreshInterval
                    intervalInput = "\(settings.qrRefreshInterval)"
                }
            } catch {
                // 加载偏好设置时静默处理
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
                // 保存偏好设置时静默处理
            }
        }
    }
    private func getAppSettings() async throws -> AppSettings {
        await MainActor.run {
            modelContext.getOrCreateAppSettings()
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
