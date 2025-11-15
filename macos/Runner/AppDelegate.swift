import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  
  private let bookmarkChannelName = "com.shakle.secure_bookmarks"
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {

      let channel = FlutterMethodChannel(
        name: bookmarkChannelName,
        binaryMessenger: controller.engine.binaryMessenger
      )

      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleBookmarkCall(call: call, result: result)
      }
    }

    super.applicationDidFinishLaunching(notification)
  }
    
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  private func handleBookmarkCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {

      case "createBookmark":
        guard
          let args = call.arguments as? [String: Any],
          let path = args["path"] as? String
        else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing path", details: nil))
          return
        }

        let url = URL(fileURLWithPath: path)

        do {
          let data = try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
          )
          let base64 = data.base64EncodedString()
          result(base64)
        } catch {
          result(FlutterError(
            code: "BOOKMARK_ERROR",
            message: "Failed to create bookmark: \(error)",
            details: nil
          ))
        }

      case "startAccessing":
        guard
          let args = call.arguments as? [String: Any],
          let base64 = args["bookmark"] as? String,
          let data = Data(base64Encoded: base64)
        else {
          result(FlutterError(code: "BAD_ARGS", message: "Missing bookmark", details: nil))
          return
        }

        var isStale = false
        do {
          let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
          )

          let ok = url.startAccessingSecurityScopedResource()
          result(ok)
        } catch {
          result(FlutterError(
            code: "RESOLVE_ERROR",
            message: "Failed to resolve bookmark: \(error)",
            details: nil
          ))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }
}
