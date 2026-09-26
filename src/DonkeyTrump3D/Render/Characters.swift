import SceneKit
import UIKit

// Original, programmer-built 3D caricatures made of primitives, with a small joint
// rig (hips, shoulders, neck) that is posed procedurally every frame.

private func node(_ geometry: SCNGeometry, _ material: SCNMaterial, at p: SCNVector3 = SCNVector3Zero) -> SCNNode {
    geometry.materials = [material]
    let n = SCNNode(geometry: geometry)
    n.position = p
    return n
}

private func capsule(_ r: CGFloat, _ h: CGFloat, _ m: SCNMaterial, at p: SCNVector3 = SCNVector3Zero) -> SCNNode {
    node(SCNCapsule(capRadius: r, height: max(h, 2 * r + 0.001)), m, at: p)
}

private func sphere(_ r: CGFloat, _ m: SCNMaterial, at p: SCNVector3 = SCNVector3Zero, segments: Int = 32) -> SCNNode {
    let s = SCNSphere(radius: r)
    s.segmentCount = segments
    return node(s, m, at: p)
}

private func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, chamfer: CGFloat = 0, _ m: SCNMaterial, at p: SCNVector3 = SCNVector3Zero) -> SCNNode {
    node(SCNBox(width: w, height: h, length: d, chamferRadius: chamfer), m, at: p)
}

struct HumanoidSpec {
    var legLength: Float
    var legRadius: Float
    var hipWidth: Float
    var torso: (w: Float, h: Float, d: Float)
    var armLength: Float
    var armRadius: Float
    var headRadius: Float
    var suit: SCNMaterial
    var pants: SCNMaterial
    var skin: SCNMaterial
    var shoes: SCNMaterial
}

enum CharacterPose: Equatable {
    case idle, walk, jump, fall, climb, climbIdle, hit, cheer, rage, windup, throwing, sign, carry, carried, wave
}

class Humanoid {
    let root = SCNNode()
    /// Turns the character to face its direction of travel.
    let yawNode = SCNNode()
    /// Bob, lean and tumbles.
    let body = SCNNode()
    let torso = SCNNode()
    let head = SCNNode()
    let armL = SCNNode()
    let armR = SCNNode()
    let legL = SCNNode()
    let legR = SCNNode()
    let spec: HumanoidSpec

    var pose: CharacterPose = .idle
    var phase: Float = 0
    var poseTime: Float = 0
    private(set) var yaw: Float = 0
    var targetYaw: Float = 0
    /// Scales walk cycle speed (world units per second of travel).
    var stride: Float = 1

    var height: Float { spec.legLength + spec.torso.h + spec.headRadius * 2 + 0.03 }

    init(spec: HumanoidSpec) {
        self.spec = spec
        root.addChildNode(yawNode)
        yawNode.addChildNode(body)

        let hipY = spec.legLength
        for (leg, side) in [(legL, Float(-1)), (legR, Float(1))] {
            leg.position = SCNVector3(side * spec.hipWidth / 2, hipY, 0)
            leg.addChildNode(capsule(CGFloat(spec.legRadius), CGFloat(spec.legLength), spec.pants, at: SCNVector3(0, -spec.legLength / 2 + spec.legRadius * 0.4, 0)))
            leg.addChildNode(box(CGFloat(spec.legRadius * 2.3), CGFloat(spec.legRadius * 1.1), CGFloat(spec.legRadius * 3.6), chamfer: CGFloat(spec.legRadius * 0.5), spec.shoes, at: SCNVector3(0, -spec.legLength + spec.legRadius * 0.55, spec.legRadius * 0.8)))
            body.addChildNode(leg)
        }

        torso.position = SCNVector3(0, hipY + spec.torso.h / 2, 0)
        torso.addChildNode(box(CGFloat(spec.torso.w), CGFloat(spec.torso.h), CGFloat(spec.torso.d), chamfer: CGFloat(min(spec.torso.w, spec.torso.d) * 0.42), spec.suit))
        body.addChildNode(torso)

        let shoulderY = hipY + spec.torso.h * 0.88
        for (arm, side) in [(armL, Float(-1)), (armR, Float(1))] {
            arm.position = SCNVector3(side * (spec.torso.w / 2 + spec.armRadius * 0.6), shoulderY, 0)
            arm.addChildNode(capsule(CGFloat(spec.armRadius), CGFloat(spec.armLength), spec.suit, at: SCNVector3(0, -spec.armLength / 2 + spec.armRadius, 0)))
            arm.addChildNode(sphere(CGFloat(spec.armRadius * 1.15), spec.skin, at: SCNVector3(0, -spec.armLength + spec.armRadius * 0.6, 0), segments: 16))
            body.addChildNode(arm)
        }

        head.position = SCNVector3(0, hipY + spec.torso.h + 0.03 + spec.headRadius, 0)
        head.addChildNode(sphere(CGFloat(spec.headRadius), spec.skin))
        head.addChildNode(capsule(CGFloat(spec.headRadius * 0.45), CGFloat(spec.headRadius * 0.9), spec.skin, at: SCNVector3(0, -spec.headRadius * 0.9, 0)))
        body.addChildNode(head)

        root.enumerateHierarchy { n, _ in n.castsShadow = true }
    }

    func set(_ newPose: CharacterPose) {
        if newPose != pose {
            pose = newPose
            poseTime = 0
        }
    }

    /// `speed` is horizontal/vertical travel speed in world units per second.
    func update(dt: Float, speed: Float = 0) {
        poseTime += dt
        let turnRate: Float = 10
        var delta = targetYaw - yaw
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        yaw += delta * min(1, dt * turnRate)
        yawNode.eulerAngles.y = yaw

        switch pose {
        case .walk, .carry:
            phase += dt * max(speed, 0.5) * 7.5 * stride
        case .climb:
            phase += dt * max(speed, 0.5) * 9
        default:
            phase += dt * 3
        }
        apply()
    }

    private func lerp(_ n: SCNNode, x: Float = 0, y: Float = 0, z: Float = 0, rate: Float = 0.35) {
        let e = n.eulerAngles
        n.eulerAngles = SCNVector3(e.x + (x - e.x) * rate, e.y + (y - e.y) * rate, e.z + (z - e.z) * rate)
    }

    func apply() {
        let s = sin(phase)
        var bodyY: Float = 0
        var bodyRoll: Float = 0
        var bodyPitch: Float = 0
        switch pose {
        case .idle:
            bodyY = sin(phase * 0.7) * 0.012
            lerp(legL); lerp(legR)
            lerp(armL, x: 0.05, z: -0.08 - sin(phase * 0.7) * 0.03)
            lerp(armR, x: 0.05, z: 0.08 + sin(phase * 0.7) * 0.03)
            lerp(head, x: sin(phase * 0.5) * 0.04)
        case .walk:
            bodyY = abs(s) * 0.045
            lerp(legL, x: s * 0.75, rate: 0.6)
            lerp(legR, x: -s * 0.75, rate: 0.6)
            lerp(armL, x: -s * 0.65, z: -0.12, rate: 0.6)
            lerp(armR, x: s * 0.65, z: 0.12, rate: 0.6)
            lerp(head, x: 0.05)
            bodyPitch = 0.06
        case .jump:
            lerp(legL, x: -0.9, rate: 0.5)
            lerp(legR, x: 0.35, rate: 0.5)
            lerp(armL, x: -0.4, z: -2.2, rate: 0.45)
            lerp(armR, x: -0.4, z: 2.2, rate: 0.45)
            lerp(head, x: -0.15)
        case .fall:
            lerp(legL, x: -0.3); lerp(legR, x: 0.3)
            lerp(armL, z: -1.4 + s * 0.2); lerp(armR, z: 1.4 - s * 0.2)
        case .climb, .climbIdle:
            let c = pose == .climb ? s : 0
            lerp(armL, x: -2.7 + c * 0.45, rate: 0.5)
            lerp(armR, x: -2.7 - c * 0.45, rate: 0.5)
            lerp(legL, x: -0.45 - c * 0.45, rate: 0.5)
            lerp(legR, x: -0.45 + c * 0.45, rate: 0.5)
            lerp(head, x: -0.25)
            bodyY = c * 0.03
        case .hit:
            bodyRoll = poseTime * 14
            bodyY = max(0, sin(min(poseTime, 1.2) * 2.6) * 0.9)
            lerp(armL, z: -2.4, rate: 0.5); lerp(armR, z: 2.4, rate: 0.5)
            lerp(legL, x: -0.6); lerp(legR, x: 0.6)
        case .cheer:
            bodyY = abs(sin(phase * 2.2)) * 0.28
            lerp(armL, z: -2.6 + sin(phase * 4) * 0.25, rate: 0.5)
            lerp(armR, z: 2.6 - sin(phase * 4) * 0.25, rate: 0.5)
            lerp(legL, x: -0.2); lerp(legR, x: 0.2)
            lerp(head, x: -0.2)
        case .rage:
            // Chest-thumping tantrum.
            let r = sin(phase * 5.5)
            bodyY = abs(sin(phase * 2.75)) * 0.12
            lerp(armL, x: -1.3 + r * 0.5, z: -0.5, rate: 0.6)
            lerp(armR, x: -1.3 - r * 0.5, z: 0.5, rate: 0.6)
            lerp(legL, x: r * 0.25); lerp(legR, x: -r * 0.25)
            lerp(head, x: -0.15 + r * 0.08)
            bodyRoll = r * 0.05
        case .windup:
            lerp(armL, x: -2.9, z: -0.25, rate: 0.35)
            lerp(armR, x: -2.9, z: 0.25, rate: 0.35)
            lerp(legL, x: 0.25); lerp(legR, x: -0.25)
            lerp(head, x: -0.2)
            bodyPitch = -0.12
        case .throwing:
            lerp(armL, x: -1.1, z: -0.2, rate: 0.7)
            lerp(armR, x: -1.1, z: 0.2, rate: 0.7)
            lerp(head, x: 0.15)
            bodyPitch = 0.22
        case .sign:
            lerp(armL, x: -0.9, z: -0.15)
            lerp(armR, x: -1.2 + sin(phase * 9) * 0.15, z: 0.35 + sin(phase * 6) * 0.1, rate: 0.6)
            lerp(head, x: 0.35)
            lerp(legL); lerp(legR)
        case .carry:
            bodyY = abs(s) * 0.04
            lerp(legL, x: s * 0.6, rate: 0.6)
            lerp(legR, x: -s * 0.6, rate: 0.6)
            lerp(armL, x: -2.5, z: -0.35, rate: 0.5)
            lerp(armR, x: s * 0.6, z: 0.15, rate: 0.6)
        case .carried:
            lerp(armL, z: -1.8 + s * 0.8, rate: 0.6)
            lerp(armR, z: 1.8 - s * 0.8, rate: 0.6)
            lerp(legL, x: -0.4 + s * 0.6, rate: 0.6)
            lerp(legR, x: -0.4 - s * 0.6, rate: 0.6)
        case .wave:
            bodyY = abs(sin(phase * 1.6)) * 0.03
            lerp(armR, x: 0, z: 2.6 + sin(phase * 5) * 0.35, rate: 0.5)
            lerp(armL, z: -0.15)
            lerp(legL); lerp(legR)
            lerp(head, z: sin(phase * 2.5) * 0.08)
        }
        body.position = SCNVector3(0, bodyY, 0)
        body.eulerAngles = SCNVector3(bodyPitch, 0, pose == .hit ? bodyRoll : bodyRoll)
    }
}

// MARK: - Jumpman Løkke

final class LokkeCharacter: Humanoid {
    init() {
        super.init(spec: HumanoidSpec(
            legLength: 0.42, legRadius: 0.07, hipWidth: 0.17,
            torso: (0.40, 0.42, 0.26), armLength: 0.36, armRadius: 0.055, headRadius: 0.135,
            suit: Mat.navySuit, pants: Mat.navyPants, skin: Mat.skinLokke, shoes: Mat.shoes
        ))
        stride = 1.1
        let t = spec.torso
        // Shirt, tie
        torso.addChildNode(box(0.12, 0.16, 0.02, Mat.shirtBlue, at: SCNVector3(0, t.h / 2 - 0.08, t.d / 2 - 0.005)))
        torso.addChildNode(box(0.045, 0.22, 0.02, chamfer: 0.01, Mat.tieGreen, at: SCNVector3(0, t.h / 2 - 0.15, t.d / 2 + 0.008)))
        // Receding grey hair: back and sides of the head only.
        let hair = sphere(0.143, Mat.hairGrey, at: SCNVector3(0, 0.012, -0.03))
        hair.scale = SCNVector3(1.02, 0.92, 0.95)
        head.addChildNode(hair)
        // Face
        let r = spec.headRadius
        for side: Float in [-1, 1] {
            let lens = SCNTorus(ringRadius: 0.038, pipeRadius: 0.007)
            let rim = node(lens, Mat.glassesFrame, at: SCNVector3(side * 0.052, 0.01, r - 0.006))
            rim.eulerAngles.x = .pi / 2
            head.addChildNode(rim)
            head.addChildNode(sphere(0.014, Mat.pupil, at: SCNVector3(side * 0.05, 0.012, r - 0.02), segments: 12))
            head.addChildNode(box(0.06, 0.01, 0.01, Mat.glassesFrame, at: SCNVector3(side * 0.11, 0.015, r - 0.05)))
        }
        head.addChildNode(box(0.03, 0.008, 0.01, Mat.glassesFrame, at: SCNVector3(0, 0.014, r + 0.004)))
        head.addChildNode(sphere(0.022, Mat.skinLokke, at: SCNVector3(0, -0.02, r + 0.005), segments: 12))
        let smile = node(SCNTorus(ringRadius: 0.035, pipeRadius: 0.006), Mat.mouth, at: SCNVector3(0, -0.045, r - 0.02))
        smile.scale = SCNVector3(1, 0.5, 0.4)
        smile.eulerAngles.x = .pi / 2
        head.addChildNode(smile)
        root.enumerateHierarchy { n, _ in n.castsShadow = true }
    }
}

// MARK: - Donkey Trump (the boss)

final class BossCharacter: Humanoid {
    let hair = SCNNode()
    let heldBarrel: SCNNode
    let mouthNode: SCNNode
    let pen: SCNNode

    init() {
        heldBarrel = BarrelNodeFactory.make()
        mouthNode = SCNNode()
        pen = SCNNode()
        super.init(spec: HumanoidSpec(
            legLength: 0.5, legRadius: 0.13, hipWidth: 0.36,
            torso: (0.92, 0.76, 0.6), armLength: 0.62, armRadius: 0.11, headRadius: 0.26,
            suit: Mat.bossSuit, pants: Mat.bossSuit, skin: Mat.skinBoss, shoes: Mat.shoes
        ))
        stride = 0.8
        let t = spec.torso
        // Shirt V and the famously long red tie.
        torso.addChildNode(box(0.26, 0.3, 0.02, Mat.shirtWhite, at: SCNVector3(0, t.h / 2 - 0.15, t.d / 2 - 0.04)))
        torso.addChildNode(box(0.1, 0.07, 0.04, chamfer: 0.015, Mat.tieRed, at: SCNVector3(0, t.h / 2 - 0.06, t.d / 2 - 0.02)))
        let tie = box(0.11, 0.78, 0.025, chamfer: 0.01, Mat.tieRed, at: SCNVector3(0, t.h / 2 - 0.47, t.d / 2 - 0.01))
        torso.addChildNode(tie)
        // Belly
        let belly = sphere(0.38, Mat.bossSuit, at: SCNVector3(0, -0.12, 0.1))
        belly.scale = SCNVector3(1.15, 0.9, 0.75)
        torso.addChildNode(belly)
        tie.position.z = t.d / 2 + 0.13
        tie.eulerAngles.x = -0.12

        let r = spec.headRadius
        // Hair: a golden swoop that bounces when he rages.
        hair.position = SCNVector3(0, r * 0.5, -0.01)
        let cap = sphere(CGFloat(r * 1.08), Mat.hairGold)
        cap.scale = SCNVector3(1.08, 0.55, 1.12)
        hair.addChildNode(cap)
        let swoop = capsule(CGFloat(r * 0.3), CGFloat(r * 1.7), Mat.hairGold, at: SCNVector3(r * 0.1, r * 0.08, r * 0.72))
        swoop.eulerAngles = SCNVector3(0, 0, Float.pi / 2 + 0.25)
        hair.addChildNode(swoop)
        let flick = capsule(CGFloat(r * 0.2), CGFloat(r * 0.9), Mat.hairGold, at: SCNVector3(r * 1.02, -r * 0.05, r * 0.25))
        flick.eulerAngles = SCNVector3(0.2, 0, 0.9)
        hair.addChildNode(flick)
        for side: Float in [-1, 1] {
            let sideHair = sphere(CGFloat(r * 0.42), Mat.hairGold, at: SCNVector3(side * r * 0.86, -r * 0.35, -r * 0.2))
            sideHair.scale = SCNVector3(0.6, 1, 1.1)
            hair.addChildNode(sideHair)
        }
        head.addChildNode(hair)
        // Angry face
        for side: Float in [-1, 1] {
            let eye = sphere(CGFloat(r * 0.2), Mat.eyeWhite, at: SCNVector3(side * r * 0.36, r * 0.08, r * 0.86), segments: 16)
            eye.scale = SCNVector3(1.3, 0.7, 0.6)
            head.addChildNode(eye)
            head.addChildNode(sphere(CGFloat(r * 0.08), Mat.pupil, at: SCNVector3(side * r * 0.33, r * 0.07, r * 0.97), segments: 12))
            let brow = box(CGFloat(r * 0.5), CGFloat(r * 0.1), CGFloat(r * 0.12), chamfer: 0.01, Mat.brows, at: SCNVector3(side * r * 0.36, r * 0.3, r * 0.9))
            brow.eulerAngles.z = side * 0.45
            head.addChildNode(brow)
        }
        let nose = sphere(CGFloat(r * 0.18), Mat.skinBoss, at: SCNVector3(0, -r * 0.06, r * 1.0), segments: 16)
        head.addChildNode(nose)
        // Shouting mouth
        mouthNode.position = SCNVector3(0, -r * 0.45, r * 0.84)
        let m = sphere(CGFloat(r * 0.3), Mat.mouth, segments: 16)
        m.scale = SCNVector3(1.1, 0.6, 0.45)
        mouthNode.addChildNode(m)
        let teeth = box(CGFloat(r * 0.36), CGFloat(r * 0.06), CGFloat(r * 0.06), Mat.teeth, at: SCNVector3(0, r * 0.1, r * 0.1))
        mouthNode.addChildNode(teeth)
        head.addChildNode(mouthNode)
        // Tan-line cheeks
        for side: Float in [-1, 1] {
            let cheek = sphere(CGFloat(r * 0.25), Mat.pbr(UIColor(hex: 0xf7a063), rough: 0.5), at: SCNVector3(side * r * 0.62, -r * 0.2, r * 0.66), segments: 12)
            cheek.scale = SCNVector3(1, 0.8, 0.5)
            head.addChildNode(cheek)
        }

        // Barrel prop held overhead during the wind-up.
        heldBarrel.isHidden = true
        heldBarrel.position = SCNVector3(0, spec.legLength + t.h + 0.75, 0.35)
        body.addChildNode(heldBarrel)

        // Giant signing pen.
        let penBody = capsule(0.03, 0.34, Mat.pbr(UIColor(hex: 0x111111), metal: 0.6, rough: 0.2))
        pen.addChildNode(penBody)
        pen.addChildNode(capsule(0.032, 0.08, Mat.pbr(UIColor(hex: 0xd4af37), metal: 1, rough: 0.2), at: SCNVector3(0, 0.12, 0)))
        pen.position = SCNVector3(0, -spec.armLength, 0.05)
        pen.eulerAngles.x = .pi / 2
        pen.isHidden = true
        armR.addChildNode(pen)
        root.enumerateHierarchy { n, _ in n.castsShadow = true }
    }

    override func apply() {
        super.apply()
        // Hair flops, mouth yells.
        switch pose {
        case .rage, .cheer:
            hair.eulerAngles.x = sin(phase * 5.5) * 0.18
            mouthNode.scale = SCNVector3(1, 1 + abs(sin(phase * 5.5)) * 0.8, 1)
        case .windup:
            hair.eulerAngles.x = -0.12
            mouthNode.scale = SCNVector3(1, 1.6, 1)
        case .throwing:
            hair.eulerAngles.x = 0.25
            mouthNode.scale = SCNVector3(1.1, 2, 1)
        case .walk, .carry:
            hair.eulerAngles.x = sin(phase * 2) * 0.1
            mouthNode.scale = SCNVector3(1, 0.7, 1)
        default:
            hair.eulerAngles.x *= 0.9
            mouthNode.scale = SCNVector3(1, 0.8 + abs(sin(phase * 0.8)) * 0.3, 1)
        }
        heldBarrel.isHidden = pose != .windup
        pen.isHidden = pose != .sign
    }
}

// MARK: - Motzfeldt

final class MotzfeldtCharacter: Humanoid {
    init() {
        super.init(spec: HumanoidSpec(
            legLength: 0.4, legRadius: 0.055, hipWidth: 0.13,
            torso: (0.34, 0.38, 0.22), armLength: 0.33, armRadius: 0.045, headRadius: 0.13,
            suit: Mat.motzWhite, pants: Mat.bootBrown, skin: Mat.skinMotz, shoes: Mat.bootBrown
        ))
        stride = 1.2
        let t = spec.torso
        // Red skirt
        let skirt = node(SCNCone(topRadius: 0.17, bottomRadius: 0.26, height: 0.3), Mat.motzRed, at: SCNVector3(0, -t.h / 2 - 0.1, 0))
        skirt.scale = SCNVector3(1, 1, 0.75)
        torso.addChildNode(skirt)
        // Greenland flag emblem on the chest.
        let flagMat = Mat.pbr(Tex.greenlandFlag, rough: 0.6)
        let emblem = node(SCNPlane(width: 0.17, height: 0.113), flagMat, at: SCNVector3(0, 0.03, t.d / 2 + 0.012))
        torso.addChildNode(emblem)
        // Long dark hair
        let r = spec.headRadius
        let crown = sphere(CGFloat(r * 1.08), Mat.hairDark, at: SCNVector3(0, r * 0.12, -r * 0.14))
        crown.scale = SCNVector3(1.05, 1, 1)
        head.addChildNode(crown)
        let back = box(CGFloat(r * 1.9), CGFloat(r * 2.4), CGFloat(r * 0.6), chamfer: CGFloat(r * 0.28), Mat.hairDark, at: SCNVector3(0, -r * 0.7, -r * 0.62))
        head.addChildNode(back)
        let fringe = capsule(CGFloat(r * 0.3), CGFloat(r * 1.8), Mat.hairDark, at: SCNVector3(0, r * 0.62, r * 0.6))
        fringe.eulerAngles.z = .pi / 2
        head.addChildNode(fringe)
        for side: Float in [-1, 1] {
            head.addChildNode(sphere(CGFloat(r * 0.11), Mat.pupil, at: SCNVector3(side * r * 0.34, r * 0.05, r * 0.92), segments: 12))
        }
        let mouth = sphere(CGFloat(r * 0.14), Mat.pbr(UIColor(hex: 0x9c2d3a), rough: 0.4), at: SCNVector3(0, -r * 0.42, r * 0.9), segments: 12)
        mouth.scale = SCNVector3(1.2, 0.8, 0.5)
        head.addChildNode(mouth)
        root.enumerateHierarchy { n, _ in n.castsShadow = true }
    }
}
