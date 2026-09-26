import SceneKit
import UIKit

/// Level pixels (800 x 600, y down) to world units (20 x 15, y up), gameplay plane z = 0.
enum WorldSpace {
    static let scale: Float = 1 / 40

    static func point(_ x: Double, _ y: Double, z: Float = 0) -> SCNVector3 {
        SCNVector3(Float(x - 400) * scale, Float(600 - y) * scale, z)
    }

    static func x(_ x: Double) -> Float { Float(x - 400) * scale }
    static func y(_ y: Double) -> Float { Float(600 - y) * scale }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

enum Mat {
    static func pbr(_ color: Any, metal: CGFloat = 0, rough: CGFloat = 0.6, emission: Any? = nil, emissionIntensity: CGFloat = 1, clearCoat: CGFloat = 0) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.metalness.contents = metal
        m.roughness.contents = rough
        if let emission {
            m.emission.contents = emission
            m.emission.intensity = emissionIntensity
        }
        if clearCoat > 0 {
            m.clearCoat.contents = clearCoat
            m.clearCoatRoughness.contents = 0.15
        }
        return m
    }

    static func glow(_ color: UIColor, intensity: CGFloat = 1) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = color
        m.emission.contents = color
        m.emission.intensity = intensity
        return m
    }

    // Characters
    static let skinLokke = pbr(UIColor(hex: 0xf1c7a3), rough: 0.55)
    static let skinBoss = pbr(UIColor(hex: 0xf08a3c), rough: 0.5, clearCoat: 0.3)
    static let skinMotz = pbr(UIColor(hex: 0xdcb08c), rough: 0.55)
    static let navySuit = pbr(UIColor(hex: 0x1f2d52), rough: 0.78)
    static let navyPants = pbr(UIColor(hex: 0x17213d), rough: 0.8)
    static let bossSuit = pbr(UIColor(hex: 0x1d2a4d), rough: 0.72)
    static let shoes = pbr(UIColor(hex: 0x111111), metal: 0.1, rough: 0.3, clearCoat: 0.8)
    static let shirtBlue = pbr(UIColor(hex: 0xa9c9ef), rough: 0.7)
    static let shirtWhite = pbr(UIColor(hex: 0xf4f4f4), rough: 0.7)
    static let tieGreen = pbr(UIColor(hex: 0x2c7a3f), rough: 0.4)
    static let tieRed = pbr(UIColor(hex: 0xd11f2f), rough: 0.35, clearCoat: 0.4)
    static let hairGrey = pbr(UIColor(hex: 0x8a8f98), rough: 0.9)
    static let hairGold = pbr(UIColor(hex: 0xf2cf4a), metal: 0.15, rough: 0.45, clearCoat: 0.6)
    static let hairDark = pbr(UIColor(hex: 0x23201f), rough: 0.7)
    static let glassesFrame = pbr(UIColor(hex: 0x222222), metal: 0.8, rough: 0.3)
    static let eyeWhite = pbr(UIColor(hex: 0xfdf6ec), rough: 0.3)
    static let pupil = pbr(UIColor(hex: 0x141414), rough: 0.2)
    static let mouth = pbr(UIColor(hex: 0x7a1f24), rough: 0.5)
    static let teeth = pbr(UIColor.white, rough: 0.3)
    static let brows = pbr(UIColor(hex: 0xe8c14a), rough: 0.7)
    static let motzWhite = pbr(UIColor(hex: 0xfafafa), rough: 0.75)
    static let motzRed = pbr(UIColor(hex: 0xc8102e), rough: 0.6)
    static let bootBrown = pbr(UIColor(hex: 0x3a2a22), rough: 0.6)

    // Structure
    static let girderRed = pbr(UIColor(hex: 0xc62a1e), metal: 0.55, rough: 0.42)
    static let girderDark = pbr(UIColor(hex: 0x7c1812), metal: 0.6, rough: 0.5)
    static let rivet = pbr(UIColor(hex: 0xe0e0e0), metal: 1, rough: 0.25)
    static let ladderSteel = pbr(UIColor(hex: 0x3ad6e0), metal: 0.7, rough: 0.3)
    static let steelGrey = pbr(UIColor(hex: 0x4a5566), metal: 0.85, rough: 0.35)
    static let craneYellow = pbr(UIColor(hex: 0xf2b71e), metal: 0.5, rough: 0.45)
    static let concrete = pbr(UIColor(hex: 0x8d949e), rough: 0.9)
    static let hoop = pbr(UIColor(hex: 0x9aa5b1), metal: 1, rough: 0.3)
}

enum Tex {
    static func image(_ size: CGSize, opaque: Bool = false, _ draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = opaque
        return UIGraphicsImageRenderer(size: size, format: format).image { draw($0.cgContext) }
    }

    /// Equirectangular night sky: deep blue zenith, glowing horizon, stars and a moon.
    static func sky(_ theme: Theme) -> UIImage {
        let size = CGSize(width: 2048, height: 1024)
        return image(size, opaque: true) { c in
            let colors = [theme.skyTop.cgColor, theme.skyMid.cgColor, theme.skyHorizon.cgColor, UIColor(hex: 0x05070d).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.32, 0.5, 0.56])!
            c.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [.drawsAfterEndLocation])
            var rng = SeededRandom(seed: 7)
            for _ in 0..<1400 {
                let x = rng.next() * size.width
                let y = pow(rng.next(), 1.6) * size.height * 0.47
                let r = 0.4 + rng.next() * 1.3
                c.setFillColor(UIColor(white: 1, alpha: 0.35 + rng.next() * 0.65).cgColor)
                c.fillEllipse(in: CGRect(x: x, y: y, width: r, height: r))
            }
            // Moon with a soft halo.
            let moon = CGPoint(x: size.width * 0.3, y: size.height * 0.2)
            for i in stride(from: 60, to: 0, by: -4) {
                c.setFillColor(UIColor(white: 1, alpha: 0.012).cgColor)
                c.fillEllipse(in: CGRect(x: moon.x - CGFloat(i) * 1.6, y: moon.y - CGFloat(i) * 1.6, width: CGFloat(i) * 3.2, height: CGFloat(i) * 3.2))
            }
            c.setFillColor(UIColor(hex: 0xf4f1e4).cgColor)
            c.fillEllipse(in: CGRect(x: moon.x - 22, y: moon.y - 22, width: 44, height: 44))
            c.setFillColor(UIColor(hex: 0xd9d4c3).cgColor)
            c.fillEllipse(in: CGRect(x: moon.x - 8, y: moon.y - 10, width: 9, height: 8))
            c.fillEllipse(in: CGRect(x: moon.x + 6, y: moon.y + 4, width: 7, height: 6))
        }
    }

    /// Small bright gradient used as the image-based lighting environment.
    static func environment(_ theme: Theme) -> UIImage {
        let size = CGSize(width: 512, height: 256)
        return image(size, opaque: true) { c in
            let colors = [theme.skyMid.cgColor, theme.aurora.withAlphaComponent(1).cgColor, UIColor(hex: 0x8fa3bf).cgColor, UIColor(hex: 0xdfe8f5).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.35, 0.52, 1])!
            c.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
            // A warm key "window" so metals pick up a highlight.
            c.setFillColor(UIColor(hex: 0xffd9a0).cgColor)
            c.fill(CGRect(x: 300, y: 70, width: 60, height: 30))
        }
    }

    static let barrelSide: UIImage = image(CGSize(width: 512, height: 256), opaque: true) { c in
        c.setFillColor(UIColor(hex: 0x9b6531).cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 512, height: 256))
        var rng = SeededRandom(seed: 3)
        for i in 0..<16 {
            let x = CGFloat(i) * 32
            let shade = 0.82 + rng.next() * 0.3
            c.setFillColor(UIColor(red: 0.6 * shade, green: 0.38 * shade, blue: 0.18 * shade, alpha: 1).cgColor)
            c.fill(CGRect(x: x, y: 0, width: 31, height: 256))
            c.setStrokeColor(UIColor(hex: 0x4a2c12, alpha: 0.7).cgColor)
            c.setLineWidth(2)
            c.stroke(CGRect(x: x, y: -2, width: 32, height: 260))
            // Grain lines
            c.setStrokeColor(UIColor(hex: 0x6b421d, alpha: 0.35).cgColor)
            c.setLineWidth(1)
            for _ in 0..<4 {
                let gx = x + 4 + rng.next() * 24
                c.move(to: CGPoint(x: gx, y: 0))
                c.addCurve(to: CGPoint(x: gx + 3, y: 256), control1: CGPoint(x: gx - 4, y: 80), control2: CGPoint(x: gx + 6, y: 170))
                c.strokePath()
            }
        }
        // Stencilled satire on every barrel.
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50, weight: .black).withTraits(.traitCondensed),
            .foregroundColor: UIColor(hex: 0x1a0f06, alpha: 0.82),
            .paragraphStyle: paragraph,
        ]
        UIGraphicsPushContext(c)
        ("TARIFFS" as NSString).draw(in: CGRect(x: 0, y: 96, width: 256, height: 70), withAttributes: attrs)
        ("TARIFFS" as NSString).draw(in: CGRect(x: 256, y: 96, width: 256, height: 70), withAttributes: attrs)
        UIGraphicsPopContext()
    }

    static let barrelCap: UIImage = image(CGSize(width: 256, height: 256), opaque: true) { c in
        c.setFillColor(UIColor(hex: 0x8a5a2b).cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
        c.setStrokeColor(UIColor(hex: 0x4a2c12).cgColor)
        c.setLineWidth(6)
        for x in stride(from: 40, to: 256, by: 44) {
            c.move(to: CGPoint(x: x, y: 0)); c.addLine(to: CGPoint(x: x, y: 256)); c.strokePath()
        }
        c.setStrokeColor(UIColor(hex: 0xc9d1d9).cgColor)
        c.setLineWidth(10)
        c.strokeEllipse(in: CGRect(x: 60, y: 60, width: 136, height: 136))
        c.setFillColor(UIColor(hex: 0x4a2c12).cgColor)
        c.fillEllipse(in: CGRect(x: 114, y: 114, width: 28, height: 28))
    }

    static let softDot: UIImage = image(CGSize(width: 64, height: 64)) { c in
        let colors = [UIColor.white.cgColor, UIColor(white: 1, alpha: 0).cgColor] as CFArray
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
        c.drawRadialGradient(g, startCenter: CGPoint(x: 32, y: 32), startRadius: 0, endCenter: CGPoint(x: 32, y: 32), endRadius: 32, options: [])
    }

    static let square: UIImage = image(CGSize(width: 16, height: 16)) { c in
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
    }

    /// Greenland's flag (Erfalasorput): white over red with a counterchanged disc.
    static let greenlandFlag: UIImage = image(CGSize(width: 256, height: 170), opaque: true) { c in
        let red = UIColor(hex: 0xc8102e).cgColor
        c.setFillColor(UIColor.white.cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 256, height: 85))
        c.setFillColor(red)
        c.fill(CGRect(x: 0, y: 85, width: 256, height: 85))
        let disc = CGRect(x: 40, y: 28, width: 114, height: 114)
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: 0, width: 256, height: 85))
        c.setFillColor(red)
        c.fillEllipse(in: disc)
        c.restoreGState()
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: 85, width: 256, height: 85))
        c.setFillColor(UIColor.white.cgColor)
        c.fillEllipse(in: disc)
        c.restoreGState()
    }

    static func speechBubble(_ text: String, fill: UIColor = UIColor(hex: 0xffe45c), ink: UIColor = UIColor(hex: 0x2b1a10)) -> UIImage {
        image(CGSize(width: 256, height: 150)) { c in
            let body = UIBezierPath(roundedRect: CGRect(x: 8, y: 8, width: 240, height: 100), cornerRadius: 34)
            body.move(to: CGPoint(x: 70, y: 104))
            body.addLine(to: CGPoint(x: 52, y: 144))
            body.addLine(to: CGPoint(x: 108, y: 104))
            c.setFillColor(fill.cgColor)
            c.addPath(body.cgPath)
            c.fillPath()
            c.setStrokeColor(ink.cgColor)
            c.setLineWidth(6)
            c.addPath(body.cgPath)
            c.strokePath()
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            UIGraphicsPushContext(c)
            (text as NSString).draw(in: CGRect(x: 8, y: 22, width: 240, height: 80), withAttributes: [
                .font: UIFont.systemFont(ofSize: 58, weight: .black),
                .foregroundColor: ink,
                .paragraphStyle: paragraph,
            ])
            UIGraphicsPopContext()
        }
    }

    static let snowGround: UIImage = image(CGSize(width: 512, height: 512), opaque: true) { c in
        c.setFillColor(UIColor(hex: 0xe8eef6).cgColor)
        c.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
        var rng = SeededRandom(seed: 11)
        for _ in 0..<900 {
            let r = 2 + rng.next() * 10
            c.setFillColor(UIColor(red: 0.8, green: 0.86, blue: 0.95, alpha: 0.25).cgColor)
            c.fillEllipse(in: CGRect(x: rng.next() * 512, y: rng.next() * 512, width: r, height: r))
        }
    }

    /// Lattice pattern with alpha, for crane masts and back bracing.
    static let lattice: UIImage = image(CGSize(width: 128, height: 128)) { c in
        c.setStrokeColor(UIColor.white.cgColor)
        c.setLineWidth(12)
        c.stroke(CGRect(x: 6, y: 6, width: 116, height: 116))
        c.setLineWidth(8)
        c.move(to: CGPoint(x: 0, y: 0)); c.addLine(to: CGPoint(x: 128, y: 128))
        c.move(to: CGPoint(x: 128, y: 0)); c.addLine(to: CGPoint(x: 0, y: 128))
        c.strokePath()
    }
}

extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let d = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: d, size: pointSize)
    }
}

/// Per-layout look: each of the three authored layouts gets its own sky and aurora.
struct Theme {
    var skyTop: UIColor
    var skyMid: UIColor
    var skyHorizon: UIColor
    var aurora: UIColor
    var aurora2: UIColor

    static let all: [Theme] = [
        Theme(skyTop: UIColor(hex: 0x02040c), skyMid: UIColor(hex: 0x0b1a36), skyHorizon: UIColor(hex: 0x1d4a5a), aurora: UIColor(hex: 0x2dffa0), aurora2: UIColor(hex: 0x22b8ff)),
        Theme(skyTop: UIColor(hex: 0x05030e), skyMid: UIColor(hex: 0x1a0f3a), skyHorizon: UIColor(hex: 0x4a2266), aurora: UIColor(hex: 0xb46bff), aurora2: UIColor(hex: 0xff5fd2)),
        Theme(skyTop: UIColor(hex: 0x0a0306), skyMid: UIColor(hex: 0x2a0d18), skyHorizon: UIColor(hex: 0x6a2a1a), aurora: UIColor(hex: 0xff7a3d), aurora2: UIColor(hex: 0xffd24a)),
    ]

    static func forLayout(_ index: Int) -> Theme { all[index % all.count] }
}
