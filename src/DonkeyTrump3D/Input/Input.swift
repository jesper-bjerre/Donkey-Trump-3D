import GameController
import UIKit

/// Thread-safe mailbox between the touch controls (main thread) and the game loop
/// (SceneKit render thread). Jump presses are counted so a quick tap is never lost.
final class InputHub {
    private let lock = NSLock()
    private var touch = InputState()
    private var jumpPresses = 0

    func setDirections(left: Bool, right: Bool, up: Bool, down: Bool) {
        lock.lock(); defer { lock.unlock() }
        touch.left = left
        touch.right = right
        touch.up = up
        touch.down = down
    }

    func setJump(_ held: Bool) {
        lock.lock(); defer { lock.unlock() }
        if held && !touch.jumpHeld { jumpPresses += 1 }
        touch.jumpHeld = held
    }

    func clear() {
        lock.lock(); defer { lock.unlock() }
        touch = InputState()
    }

    func snapshot() -> (state: InputState, presses: Int) {
        lock.lock(); defer { lock.unlock() }
        return (touch, jumpPresses)
    }
}

/// Polls MFi / Xbox / PlayStation controllers and a hardware keyboard.
struct ControllerInput {
    var state = InputState()
    var pausePressed = false
    var confirmPressed = false

    private static var lastPause = false
    private static var lastConfirm = false

    static func poll() -> ControllerInput {
        var result = ControllerInput()
        var pause = false
        var confirm = false
        if let pad = GCController.current?.extendedGamepad {
            let stick = pad.leftThumbstick
            result.state.left = pad.dpad.left.isPressed || stick.xAxis.value < -0.4
            result.state.right = pad.dpad.right.isPressed || stick.xAxis.value > 0.4
            result.state.up = pad.dpad.up.isPressed || stick.yAxis.value > 0.5
            result.state.down = pad.dpad.down.isPressed || stick.yAxis.value < -0.5
            result.state.jumpHeld = pad.buttonA.isPressed || pad.buttonB.isPressed
            pause = pad.buttonMenu.isPressed
            confirm = pad.buttonA.isPressed
        }
        if let kb = GCKeyboard.coalesced?.keyboardInput {
            func down(_ codes: GCKeyCode...) -> Bool { codes.contains { kb.button(forKeyCode: $0)?.isPressed == true } }
            result.state.left = result.state.left || down(.leftArrow, .keyA)
            result.state.right = result.state.right || down(.rightArrow, .keyD)
            result.state.up = result.state.up || down(.upArrow, .keyW)
            result.state.down = result.state.down || down(.downArrow, .keyS)
            result.state.jumpHeld = result.state.jumpHeld || down(.spacebar)
            pause = pause || down(.keyP, .escape)
            confirm = confirm || down(.returnOrEnter)
        }
        result.pausePressed = pause && !lastPause
        result.confirmPressed = confirm && !lastConfirm
        lastPause = pause
        lastConfirm = confirm
        return result
    }
}

/// On-screen controls: a floating thumb-stick anywhere on the left half and a big
/// JUMP button (the whole right half is the jump zone). Multi-touch.
final class TouchControlsView: UIView {
    var hub: InputHub?

    private var stickTouch: UITouch?
    private var stickOrigin = CGPoint.zero
    private var jumpTouches = Set<UITouch>()

    private let base = CAShapeLayer()
    private let knob = CAShapeLayer()
    private let jumpRing = CAShapeLayer()
    private let jumpLabel = CATextLayer()
    private let arrows = CAShapeLayer()

    private let baseRadius: CGFloat = 62
    private let knobRadius: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
        for layer in [base, arrows, knob, jumpRing] { self.layer.addSublayer(layer) }
        self.layer.addSublayer(jumpLabel)
        base.fillColor = UIColor(white: 1, alpha: 0.08).cgColor
        base.strokeColor = UIColor(white: 1, alpha: 0.35).cgColor
        base.lineWidth = 2
        knob.fillColor = UIColor(white: 1, alpha: 0.55).cgColor
        knob.strokeColor = UIColor.white.cgColor
        knob.lineWidth = 2
        arrows.fillColor = UIColor(white: 1, alpha: 0.4).cgColor
        jumpRing.fillColor = UIColor(red: 1, green: 0.78, blue: 0.2, alpha: 0.28).cgColor
        jumpRing.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 0.9).cgColor
        jumpRing.lineWidth = 3
        jumpLabel.string = "JUMP"
        jumpLabel.font = UIFont.systemFont(ofSize: 18, weight: .black)
        jumpLabel.fontSize = 18
        jumpLabel.alignmentMode = .center
        jumpLabel.foregroundColor = UIColor.white.cgColor
        jumpLabel.contentsScale = 3
    }

    required init?(coder: NSCoder) { fatalError() }

    private var restingStick: CGPoint {
        CGPoint(x: safeAreaInsets.left + 40 + baseRadius, y: bounds.height - safeAreaInsets.bottom - 34 - baseRadius)
    }

    private var jumpCenter: CGPoint {
        CGPoint(x: bounds.width - safeAreaInsets.right - 44 - 50, y: bounds.height - safeAreaInsets.bottom - 34 - 50)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if stickTouch == nil { drawStick(center: restingStick, knobAt: restingStick) }
        drawJump(pressed: !jumpTouches.isEmpty)
    }

    private func drawStick(center: CGPoint, knobAt: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        base.path = UIBezierPath(arcCenter: center, radius: baseRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        knob.path = UIBezierPath(arcCenter: knobAt, radius: knobRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        let a = UIBezierPath()
        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 2) {
            let dir = CGPoint(x: cos(angle), y: sin(angle))
            let tip = CGPoint(x: center.x + dir.x * (baseRadius - 8), y: center.y + dir.y * (baseRadius - 8))
            let back = CGPoint(x: center.x + dir.x * (baseRadius - 18), y: center.y + dir.y * (baseRadius - 18))
            let side = CGPoint(x: -dir.y * 7, y: dir.x * 7)
            a.move(to: tip)
            a.addLine(to: CGPoint(x: back.x + side.x, y: back.y + side.y))
            a.addLine(to: CGPoint(x: back.x - side.x, y: back.y - side.y))
            a.close()
        }
        arrows.path = a.cgPath
        CATransaction.commit()
    }

    private func drawJump(pressed: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let r: CGFloat = pressed ? 46 : 50
        jumpRing.path = UIBezierPath(arcCenter: jumpCenter, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        jumpRing.fillColor = UIColor(red: 1, green: 0.78, blue: 0.2, alpha: pressed ? 0.6 : 0.28).cgColor
        jumpLabel.frame = CGRect(x: jumpCenter.x - 50, y: jumpCenter.y - 12, width: 100, height: 24)
        CATransaction.commit()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let p = t.location(in: self)
            if p.x < bounds.width * 0.45, stickTouch == nil {
                stickTouch = t
                stickOrigin = p
                updateStick(p)
            } else if p.x >= bounds.width * 0.45 {
                jumpTouches.insert(t)
            }
        }
        publishJump()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let s = stickTouch, touches.contains(s) { updateStick(s.location(in: self)) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }

    private func end(_ touches: Set<UITouch>) {
        for t in touches {
            if t == stickTouch {
                stickTouch = nil
                hub?.setDirections(left: false, right: false, up: false, down: false)
                drawStick(center: restingStick, knobAt: restingStick)
            }
            jumpTouches.remove(t)
        }
        publishJump()
    }

    private func publishJump() {
        hub?.setJump(!jumpTouches.isEmpty)
        drawJump(pressed: !jumpTouches.isEmpty)
    }

    private func updateStick(_ p: CGPoint) {
        var dx = p.x - stickOrigin.x
        var dy = p.y - stickOrigin.y
        let len = hypot(dx, dy)
        // The base follows the thumb when it strays too far.
        if len > baseRadius {
            stickOrigin.x += dx - dx / len * baseRadius
            stickOrigin.y += dy - dy / len * baseRadius
            dx = p.x - stickOrigin.x
            dy = p.y - stickOrigin.y
        }
        let dead: CGFloat = 12
        let horizontalBias = abs(dx) > abs(dy) * 0.6
        hub?.setDirections(
            left: dx < -dead && horizontalBias,
            right: dx > dead && horizontalBias,
            up: dy < -dead * 1.5,
            down: dy > dead * 1.5
        )
        drawStick(center: stickOrigin, knobAt: CGPoint(x: stickOrigin.x + dx, y: stickOrigin.y + dy))
    }
}
