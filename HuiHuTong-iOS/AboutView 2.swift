import SwiftUI
@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    AppHeaderView(colorScheme: colorScheme)
                    
                    DeveloperMessageSection(colorScheme: colorScheme)
                    
                    CoreFeaturesSection(colorScheme: colorScheme)
                    
                    QuickStartSection(colorScheme: colorScheme)
                    
                    AuthorSection(colorScheme: colorScheme)
                    
                    ThankYouSection(colorScheme: colorScheme)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                        [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)] :
                        [Color(UIColor.systemBackground), Color(UIColor.systemGroupedBackground)]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// 分离应用头部视图
struct AppHeaderView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // App图标带动画效果
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 10)
                
            Image("AppIconImage")
                .resizable()
                .aspectRatio(contentMode: .fit)
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 10) {
                Text("慧湖通Lite")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("🏠 宿舍生活全能助手")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                HStack(spacing: 8) {
                Text("Ver.2.0.0")
                    .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("开源项目")
                        .font(.caption)
                        .foregroundColor(.white)
                    .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .green.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
    }
}

// 开发者说明板块
struct DeveloperMessageSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "quote.opening")
                    .foregroundColor(.orange)
                Text("开发者的话")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Image(systemName: "quote.closing")
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("这个项目纯粹是因为无聊才做的 😅")
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("某天突然想到可以做个轻量版的慧湖通，于是就动手做了。希望能给大家的宿舍生活带来一点便利！")
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white)
                .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// 分离核心功能板块
struct CoreFeaturesSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("核心功能")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            VStack(spacing: 12) {
                FeatureCard(
                    icon: "qrcode",
                    title: "门禁二维码",
                    description: "自动刷新，极速进出",
                    color: .blue,
                    colorScheme: colorScheme
                )
                
                FeatureCard(
                    icon: "bolt.fill",
                    title: "水电费查询",
                    description: "实时余额，一键查看",
                    color: .green,
                    colorScheme: colorScheme
                )
            }
        }
    }
}

// 功能卡片
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white)
                .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// 分离快速上手板块
struct QuickStartSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("快速上手")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                StepRow(
                    number: "1",
                    title: "获取OpenID",
                    description: "通过微信小程序抓包获取个人OpenID",
                    colorScheme: colorScheme
                )
                
                StepRow(
                    number: "2",
                    title: "享受便利",
                    description: "自动生成二维码，查询电费等",
                    colorScheme: colorScheme
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white)
                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// 步骤行
struct StepRow: View {
    let number: String
    let title: String
    let description: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
            Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                    Text(number)
                    .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// 作者信息板块
struct AuthorSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.blue)
                Text("关于作者")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Text("IM")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("IcyMichiko")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        Text("独立开发者")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .cornerRadius(8)
            }
            
            Spacer()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "laptopcomputer")
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        Text("热爱编程和创造")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 20)
                        Text("希望技术能让生活更美好")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.5) : Color.white)
                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// 感谢使用板块
struct ThankYouSection: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 16) {
        HStack {
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.pink)
                
                Text("感谢使用")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.pink, .orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Image(systemName: "hands.sparkles.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                Text("感谢你选择慧湖通Lite！")
                    .font(.body)
                    .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                
                Text("如果这个应用对你有帮助，欢迎分享给你的朋友们。如果有任何建议或问题，也欢迎随时反馈~")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                HStack(spacing: 4) {
                    Text("Made with")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("by IcyMichiko")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme == .dark ?
                            [Color(.systemGray6).opacity(0.5), Color(.systemGray5).opacity(0.3)] :
                            [Color.white, Color.pink.opacity(0.05)]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: colorScheme == .dark ? .clear : .pink.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.pink.opacity(0.3), Color.orange.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.bottom, 20)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        AboutView()
    }
}
