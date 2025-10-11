import SwiftUI
@available(iOS 17.0, *)
struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // 顶部图标和应用名称
                        AppHeaderView(colorScheme: colorScheme)
                            .padding(.top, 40)
                        
                        VStack(spacing: 16) {
                            // 使用教程卡片
                            TutorialCard(colorScheme: colorScheme)
                            
                            // 鸣谢卡片
                            AcknowledgmentCard(colorScheme: colorScheme)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 80)
                    }
                }
                
                // 底部版本号
                Text("v0.0.1-beta")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                (colorScheme == .dark ? Color.black : Color(UIColor.systemBackground))
                    .ignoresSafeArea()
            )
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
struct AppHeaderView: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            // 炫彩应用名称
            Text("慧湖通Lite")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

// 使用教程卡片
struct TutorialCard: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://github.com/PairZhu/HuiHuTong/blob/main/README.md") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                // 问号图标
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("如何使用？")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("查看详细使用教程")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

// 鸣谢卡片
struct AcknowledgmentCard: View {
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: {
            if let url = URL(string: "https://github.com/PairZhu/HuiHuTong") {
                UIApplication.shared.open(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)
                    
                    Text("鸣谢")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("本项目参考了以下开源项目：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        
                        Text("PairZhu/HuiHuTong")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: colorScheme == .dark ? .clear : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        AboutView()
    }
}
