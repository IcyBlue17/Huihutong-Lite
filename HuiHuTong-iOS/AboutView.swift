import SwiftUI
@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 20) {
                    AppHeaderView(colorScheme: colorScheme)
                    CoreFeaturesSection(colorScheme: colorScheme)
                    QuickStartSection(colorScheme: colorScheme)
                }
                .padding(.horizontal, 20)
            }
            .background((colorScheme == .dark ? Color.black : Color(UIColor.systemGroupedBackground)).ignoresSafeArea())
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 分离应用头部视图
struct AppHeaderView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
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
                Text("宿舍生活全能助手")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                Text("Ver.2.0.0")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 20)
    }
}

// 分离核心功能板块
struct CoreFeaturesSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "核心功能", colorScheme: colorScheme)
            InfoCard(colorScheme: colorScheme) {
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "qrcode", text: "获取门禁二维码 - 自动刷新，极速进出", colorScheme: colorScheme)
                    FeatureRow(icon: "bolt.fill", text: "水电费查询 - 实时余额，一键查看", colorScheme: colorScheme)
                }
            }
        }
    }
}

// 分离快速上手板块
struct QuickStartSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "快速上手", colorScheme: colorScheme)
            InfoCard(colorScheme: colorScheme) {
                VStack(alignment: .leading, spacing: 12) {
                    UsageStep(number: "1", title: "获取OpenID", description: "通过微信小程序抓包获取个人OpenID", colorScheme: colorScheme)
                    UsageStep(number: "2", title: "享受便利", description: "自动生成二维码，查询电费等", colorScheme: colorScheme)
                }
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
                .frame(width: 24, height: 24)
                .font(.system(size: 16, weight: .medium))
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 2)
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

#Preview {
    if #available(iOS 17.0, *) {
        AboutView()
    }
}
