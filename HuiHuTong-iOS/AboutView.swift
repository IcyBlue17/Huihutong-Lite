import SwiftUI
import SafariServices
@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showingTutorial = false
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image("AppIconImage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        VStack(spacing: 8) {
                            Text("慧湖通Lite")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                            Text("快速获取宿舍门禁二维码，无需忍受卡顿的小程序")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                            
                            Text("Ver.1.14.5")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "使用说明", colorScheme: colorScheme)
                        InfoCard(colorScheme: colorScheme) {
                            VStack(alignment: .leading, spacing: 12) {
                                UsageStep(number: "1", title: "获取OpenID", description: "从微信小程序中抓包获取OpenID", colorScheme: colorScheme)
                                UsageStep(number: "2", title: "输入OpenID", description: "点击按钮输入获取到的OpenID", colorScheme: colorScheme)
                                UsageStep(number: "3", title: "生成二维码", description: "应用将自动生成并定时刷新二维码（8秒一次）", colorScheme: colorScheme)
                                UsageStep(number: "4", title: "使用二维码", description: "在进入宿舍时出示生成的二维码即可", colorScheme: colorScheme)
                            }
                        }
                    }
                    
                    Button(action: {
                        showingTutorial = true
                    }) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.white)
                            Text("查看使用教程")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 18))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 10)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 20)
            }
            .background((colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)).ignoresSafeArea())
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingTutorial) {
                SafariView(url: URL(string: "https://github.com/PairZhu/HuiHuTong/blob/main/README.md")!)
            }
        }
    }
}
struct SectionHeader: View {
    let title: String
    let colorScheme: ColorScheme
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(colorScheme == .dark ? .white : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct InfoCard<Content: View>: View {
    let colorScheme: ColorScheme
    let content: () -> Content
    init(colorScheme: ColorScheme, @ViewBuilder content: @escaping () -> Content) {
        self.colorScheme = colorScheme
        self.content = content
    }
    var body: some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 2, x: 0, y: 1)
            )
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
    }
}

struct UsageStep: View {
    let number: String
    let title: String
    let description: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay {
                    Text(number)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
            
            Spacer()
        }
    }
}

struct TechRow: View {
    let title: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        AboutView()
    }
}
