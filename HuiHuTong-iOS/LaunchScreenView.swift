
import SwiftUI

@available(iOS 17.0, *)
struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("慧湖通Lite")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue)
                    )
                
                Text("慧湖通Lite")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("二维码秒开")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        LaunchScreenView()
    } else {
        Text("需要 iOS 17.0 或更高版本")
    }
}
