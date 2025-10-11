
import SwiftUI
import SwiftData

@available(iOS 17.0, *)
@main
struct HuiHuTong_iOSApp: App {
    private let tracker = Tracker()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppSettings.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("数据库迁移错误: \(error)")
            let url = modelConfiguration.url
            try? FileManager.default.removeItem(at: url)
            
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()
    
    init() {
        tracker.sendTrackingData()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
