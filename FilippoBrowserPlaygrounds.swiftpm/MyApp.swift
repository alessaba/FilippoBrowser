import SwiftUI

@main
struct MyApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	
    var body: some Scene {
        WindowGroup {
            Browser(path: "/")
        }
    }
}
