import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {

  private var splashView: SplashView?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

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
}
