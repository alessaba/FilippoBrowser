import SwiftUI
import WatchConnectivity

@main
struct MyApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	@Environment(\.scenePhase) private var scenePhase
	
	@State var launchPath : String = "/"
	
    var body: some Scene {
        WindowGroup {
			Browser(path: launchPath, presentSheet: (launchPath != "/"), presentRBSheet: false)
			.onOpenURL{ url in
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
			}
		}
    }
}


func isFolder(_ url : URL) -> Bool {
	var isFoldr : ObjCBool = false
	FileManager.default.fileExists(atPath: url.path, isDirectory: &isFoldr)
	return isFoldr.boolValue
}

func launchShortcut(_ shortcut : UIApplicationShortcutItem, with scene : UIScene){
	let path = UserDefaults.standard.string(forKey: shortcut.type) ?? "/" // We use the type to reference a path in the User Defaults
	let pathURL = URL(fileURLWithPath: path)
	//sheetBrowser(scene, at: pathURL)
}
