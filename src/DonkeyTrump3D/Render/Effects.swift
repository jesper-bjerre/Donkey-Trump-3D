import SceneKit
import UIKit

enum Effects {
    static func snow() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.particleImage = Tex.softDot
        ps.birthRate = 420
        ps.particleLifeSpan = 12
        ps.warmupDuration = 12
        ps.emitterShape = SCNBox(width: 70, height: 0.5, length: 40, chamferRadius: 0)
        ps.particleSize = 0.045
        ps.particleSizeVariation = 0.03
        ps.emittingDirection = SCNVector3(0.15, -1, 0)
        ps.spreadingAngle = 25
        ps.particleVelocity = 1.4
        ps.particleVelocityVariation = 0.6
        ps.particleColor = UIColor(white: 1, alpha: 0.85)
        ps.blendMode = .alpha
        ps.isLightingEnabled = false
        ps.sortingMode = .none
        return ps
    }

    static func burst(color: UIColor, count: CGFloat, speed: CGFloat, life: CGFloat, size: CGFloat, gravity: Bool = true, additive: Bool = true, image: UIImage = Tex.softDot) -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.particleImage = image
        ps.loops = false
        ps.emissionDuration = 0.06
        ps.birthRate = count / 0.06
        ps.particleLifeSpan = life
        ps.particleLifeSpanVariation = life * 0.4
        ps.particleVelocity = speed
        ps.particleVelocityVariation = speed * 0.5
        ps.spreadingAngle = 180
        ps.particleSize = size
        ps.particleSizeVariation = size * 0.5
        ps.particleColor = color
        ps.isAffectedByGravity = gravity
        ps.acceleration = gravity ? SCNVector3(0, -9, 0) : SCNVector3Zero
        ps.blendMode = additive ? .additive : .alpha
        ps.isLightingEnabled = false
        let fade = CAKeyframeAnimation()
        fade.values = [1, 1, 0]
        fade.keyTimes = [0, 0.6, 1]
        ps.propertyControllers = [.opacity: SCNParticlePropertyController(animation: fade)]
        return ps
    }

    static func sparks() -> SCNParticleSystem {
        burst(color: UIColor(hex: 0xffa640), count: 90, speed: 6, life: 0.6, size: 0.09)
    }

    static func dust() -> SCNParticleSystem {
        let ps = burst(color: UIColor(white: 0.95, alpha: 0.7), count: 22, speed: 1.4, life: 0.7, size: 0.22, gravity: false, additive: false)
        ps.spreadingAngle = 70
        ps.emittingDirection = SCNVector3(0, 1, 0)
        return ps
    }

    static func confetti(_ color: UIColor) -> SCNParticleSystem {
        let ps = burst(color: color, count: 55, speed: 5.5, life: 2.4, size: 0.06, gravity: true, additive: false, image: Tex.square)
        ps.emittingDirection = SCNVector3(0, 1, 0)
        ps.spreadingAngle = 55
        ps.acceleration = SCNVector3(0, -6, 0)
        ps.particleAngularVelocity = 400
        ps.particleAngularVelocityVariation = 300
        ps.dampingFactor = 1.2
        ps.isLightingEnabled = false
        return ps
    }

    static func fireTrail() -> SCNParticleSystem {
        let ps = SCNParticleSystem()
        ps.particleImage = Tex.softDot
        ps.birthRate = 160
        ps.particleLifeSpan = 0.35
        ps.particleLifeSpanVariation = 0.1
        ps.emitterShape = SCNSphere(radius: 0.18)
        ps.particleVelocity = 0.4
        ps.spreadingAngle = 180
        ps.particleSize = 0.22
        ps.particleSizeVariation = 0.08
        ps.particleColor = UIColor(hex: 0xff6a1a)
        ps.blendMode = .additive
        ps.isLightingEnabled = false
        let shrink = CAKeyframeAnimation()
        shrink.values = [1, 0.2]
        ps.propertyControllers = [.size: SCNParticlePropertyController(animation: shrink)]
        return ps
    }

    static func floatText(_ text: String, color: UIColor, at position: SCNVector3, in parent: SCNNode, scale: Float = 0.38) {
        let geo = SCNText(string: text, extrusionDepth: 0.15)
        geo.font = UIFont.systemFont(ofSize: 1, weight: .black)
        geo.flatness = 0.05
        geo.materials = [Mat.glow(color, intensity: 1.6)]
        let textNode = SCNNode(geometry: geo)
        let (mn, mx) = textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((mx.x - mn.x) / 2 + mn.x, (mx.y - mn.y) / 2 + mn.y, 0)
        let holder = SCNNode()
        holder.addChildNode(textNode)
        holder.position = position
        holder.scale = SCNVector3(scale * 0.4, scale * 0.4, scale * 0.4)
        holder.constraints = [SCNBillboardConstraint()]
        parent.addChildNode(holder)
        let pop = SCNAction.scale(to: CGFloat(scale), duration: 0.12)
        pop.timingMode = .easeOut
        let rise = SCNAction.moveBy(x: 0, y: 1.3, z: 0, duration: 1.0)
        rise.timingMode = .easeOut
        holder.runAction(.sequence([pop, .group([rise, .sequence([.wait(duration: 0.55), .fadeOut(duration: 0.45)])]), .removeFromParentNode()]))
    }

    static func bubble(_ text: String, fill: UIColor = UIColor(hex: 0xffe45c)) -> SCNNode {
        let plane = SCNPlane(width: 1.1, height: 0.64)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = Tex.speechBubble(text, fill: fill)
        m.isDoubleSided = true
        m.writesToDepthBuffer = false
        plane.materials = [m]
        let n = SCNNode(geometry: plane)
        n.constraints = [SCNBillboardConstraint()]
        n.renderingOrder = 50
        return n
    }
}
