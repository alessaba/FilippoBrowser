import SwiftUI
import WatchConnectivity
import UserNotifications

let notificationCenter = UNUserNotificationCenter.current()

@main
struct MyApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	@Environment(\.scenePhase) private var scenePhase
	
	@State var launchPath : String = "/"
	
    var body: some Scene {
        WindowGroup {
			Browser(path: launchPath, presentSheet: (launchPath != "/"), presentRBSheet: false)
			/*.onOpenURL{ url in
					print("Received URL: \(url)")
					if isFolder(url){
						launchPath = url.path
					} else {
						launchPath = url.deletingLastPathComponent().path + "/"
					}
			}
			.onAppear{
				print("Session supported: \(WCSession.isSupported())")
				if WCSession.isSupported(){
					let watchSession = WCSession.default
					let del = WSDelegate()
					watchSession.delegate = del
					watchSession.activate()
				} else {
					print("Device not supported or Apple Watch is not paired.")
				}
			}*/
		}
    }
}


class AppDelegate: UIResponder, UIApplicationDelegate {
	
	let fileManager = FileManager.default
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		
		// Notification Permission request
		notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]){ _,_ in
			print("Notification Authorization Granted.")
		}
		
		return true
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Cleaning tmp directory (not sure it's really necessary for every launch but ok)
		let tempDir = fileManager.temporaryDirectory
		let tempDirContents = try? fileManager.contentsOfDirectory(atPath: tempDir.path)
		if let tempDirContents = tempDirContents{
			for tempFile in tempDirContents{
				try? fileManager.removeItem(atPath: tempDir.appendingPathComponent(tempFile).path)
			}
		}
	}
	
	// MARK: UISceneSession Lifecycle
	
	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		let sceneConf = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
		sceneConf.delegateClass = SceneDelegate.self
		return sceneConf
	}
}
