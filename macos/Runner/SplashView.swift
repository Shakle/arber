import Cocoa

class SplashView: NSView {

    override var isOpaque: Bool { true }

    init(frame: NSRect, color: NSColor) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = color.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fadeOutAndRemove(duration: Double = 0.35, delay: Double = 0.05) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = duration
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 0
            } completionHandler: {
                self.removeFromSuperview()
            }
        }
    }
}
