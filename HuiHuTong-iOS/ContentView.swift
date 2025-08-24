import SwiftUI
import SwiftData

@available(iOS 17.0, *)
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = MainViewModel()
    @State private var showingOpenIdInput = false
    @State private var openIdInput = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
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
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            if let settings = viewModel.settings {
                                openIdInput = settings.openId
                            }
                            showingOpenIdInput = true
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("修改 OpenID")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        
                        Button(action: {
                            viewModel.showAboutInfo()
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                Text("关于")
                            }
                            .font(.system(size: 16))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                            .cornerRadius(10)
                        }
                    }
                    
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
        .sheet(isPresented: $viewModel.showAbout) {
            AboutView()
        }
        .alert("设置 OpenID", isPresented: $showingOpenIdInput) {
            TextField("请输入 OpenID", text: $openIdInput)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            
            Button("确定") {
                viewModel.updateOpenId(openIdInput)
                showingOpenIdInput = false
            }
            
            Button("取消", role: .cancel) {
                showingOpenIdInput = false
            }
        } message: {
            Text("请输入从微信小程序抓包获取的 OpenID")
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

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
            .modelContainer(for: AppSettings.self, inMemory: true)
    } else {
        Text("需要 iOS 17.0 或更高版本")
    }
}
