import Cocoa
import FlutterMacOS
import directory_bookmarks

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let mainWindow = mainFlutterWindow else { return }
    guard let controller = mainWindow.contentViewController as? FlutterViewController else { return }
    DirectoryBookmarksPlugin.register(with: controller.registrar(forPlugin: "DirectoryBookmarksPlugin"))
    super.applicationDidFinishLaunching(notification)
  }
    
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
