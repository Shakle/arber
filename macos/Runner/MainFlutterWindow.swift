import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {

  private var splashView: SplashView?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    setUpWindow()

    // Splash color: RGB(209, 230, 246)
    let splashColor = NSColor(
      red: 209.0 / 255.0,
      green: 230.0 / 255.0,
      blue: 246.0 / 255.0,
      alpha: 1.0
    )

    // Create and put splash above content
    if let contentView = self.contentView {
      let splash = SplashView(frame: contentView.bounds, color: splashColor)
      splash.autoresizingMask = [.width, .height] // чтобы растягивался с окном
      contentView.addSubview(splash)
      self.splashView = splash
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    // Run fade transition
    NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification,
      object: self,
      queue: .main
    ) { [weak self] _ in
      self?.splashView?.fadeOutAndRemove()
    }
  }

  /// Hidden title bar with the window buttons, 1050 x 750 (at least 1000 x 700),
  /// centered on the screen under the cursor: what window_manager 0.5's
  /// WindowOptions did. Windows does the same in windows/runner/main.cpp.
  private func setUpWindow() {
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    minSize = NSSize(width: 1000, height: 700)

    let size = NSSize(width: 1050, height: 750)
    let cursor = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { NSMouseInRect(cursor, $0.frame, false) } ?? NSScreen.main
    guard let area = screen?.visibleFrame else {
      setContentSize(size)
      center()
      return
    }
    setFrame(
      NSRect(
        x: (area.midX - size.width / 2).rounded(),
        y: (area.midY - size.height / 2).rounded(),
        width: size.width,
        height: size.height),
      display: true)
  }
}
