import SwiftUI
import WatchConnectivity
import UserNotifications


@main
struct MyApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
	@State var launchPath : String = "/"
	
    var body: some Scene {
        WindowGroup {
			Browser(path: launchPath, presentSheet: (launchPath != "/"), presentRBSheet: false)
		}
    }
}


/*
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
 */
