import SceneKit
import UIKit

enum BarrelNodeFactory {
    static let radius: CGFloat = 0.26
    static let length: CGFloat = 0.56

    private static let template: SCNNode = {
        let root = SCNNode()
        let body = SCNNode()
        body.eulerAngles.x = .pi / 2
        let cyl = SCNCylinder(radius: radius, height: length)
        cyl.radialSegmentCount = 28
        let side = Mat.pbr(Tex.barrelSide, rough: 0.72)
        side.normal.intensity = 0.4
        let cap = Mat.pbr(Tex.barrelCap, rough: 0.7)
        cyl.materials = [side, cap, cap]
        body.geometry = cyl
        for y: Float in [-0.2, 0, 0.2] {
            let hoop = SCNTorus(ringRadius: radius + (y == 0 ? 0.012 : 0.004), pipeRadius: 0.018)
            hoop.ringSegmentCount = 28
            hoop.pipeSegmentCount = 8
            hoop.materials = [Mat.hoop]
            let h = SCNNode(geometry: hoop)
            h.position.y = y
            body.addChildNode(h)
        }
        root.addChildNode(body.flattenedClone())
        root.enumerateHierarchy { n, _ in n.castsShadow = true }
        return root
    }()

    static func make() -> SCNNode { template.clone() }
}

enum WorldBuilder {
    // MARK: Girders & ladders

    static let girderDepth: Float = 1.3
    static let girderHeight: Float = 0.36

    /// A red steel truss girder along `segment`, top surface on the segment line.
    /// Built along +x around its midpoint; `place` positions and tilts it.
    static func girder(_ segment: Segment) -> SCNNode {
        let a = WorldSpace.point(segment.x1, segment.y1)
        let b = WorldSpace.point(segment.x2, segment.y2)
        let length = hypot(b.x - a.x, b.y - a.y)
        let proto = SCNNode()
        let half = length / 2
        let depth = girderDepth
        let h = girderHeight

        func bar(_ w: Float, _ hh: Float, _ d: Float, _ m: SCNMaterial, _ p: SCNVector3, angle: Float = 0) {
            let n = SCNNode(geometry: SCNBox(width: CGFloat(w), height: CGFloat(hh), length: CGFloat(d), chamferRadius: 0.008))
            n.geometry?.materials = [m]
            n.position = p
            n.eulerAngles.z = angle
            proto.addChildNode(n)
        }

        // Deck the characters walk on.
        bar(length, 0.07, depth, Mat.girderRed, SCNVector3(0, -0.035, 0))
        for z in [-depth / 2 + 0.05, depth / 2 - 0.05] {
            bar(length, 0.09, 0.09, Mat.girderRed, SCNVector3(0, -0.1, z))
            bar(length, 0.08, 0.08, Mat.girderRed, SCNVector3(0, -h, z))
            // Classic zig-zag truss web.
            let count = max(2, Int((length / 0.46).rounded()))
            let step = length / Float(count)
            for i in 0..<count {
                let x0 = -half + Float(i) * step
                let up = i % 2 == 0
                let yA: Float = up ? -h : -0.1
                let yB: Float = up ? -0.1 : -h
                let dx = step, dy = yB - yA
                bar(hypot(dx, dy), 0.05, 0.05, Mat.girderRed, SCNVector3(x0 + step / 2, (yA + yB) / 2, z), angle: atan2(dy, dx))
            }
            bar(0.06, h, 0.06, Mat.girderRed, SCNVector3(-half + 0.03, -h / 2 - 0.05, z))
            bar(0.06, h, 0.06, Mat.girderRed, SCNVector3(half - 0.03, -h / 2 - 0.05, z))
        }
        // Rivets along the front edge.
        let rivet = SCNSphere(radius: 0.022)
        rivet.segmentCount = 8
        rivet.materials = [Mat.rivet]
        var x = -half + 0.12
        while x < half - 0.1 {
            let r = SCNNode(geometry: rivet)
            r.position = SCNVector3(x, -0.035, depth / 2 + 0.002)
            proto.addChildNode(r)
            x += 0.3
        }

        let flat = proto.flattenedClone()
        flat.castsShadow = true
        let container = SCNNode()
        container.addChildNode(flat)
        container.setValue(length, forKey: "baseLength")
        place(container, on: segment)
        return container
    }

    /// Moves a girder built by `girder(_:)` onto a (possibly tilting) segment.
    static func place(_ node: SCNNode, on segment: Segment) {
        let a = WorldSpace.point(segment.x1, segment.y1)
        let b = WorldSpace.point(segment.x2, segment.y2)
        let length = hypot(b.x - a.x, b.y - a.y)
        let base = (node.value(forKey: "baseLength") as? Float) ?? length
        node.position = SCNVector3((a.x + b.x) / 2, (a.y + b.y) / 2, 0)
        node.eulerAngles.z = atan2(b.y - a.y, b.x - a.x)
        node.scale = SCNVector3(length / base, 1, 1)
    }

    static let ladderZ: Float = -0.36

    static func ladder(_ l: LevelLadder) -> SCNNode {
        let top = WorldSpace.y(l.y)
        let bottom = WorldSpace.y(l.y + l.height)
        let x = WorldSpace.x(l.snapX)
        let node = SCNNode()
        let height = top - bottom + 0.55 // rails continue above the deck as handholds
        for side: Float in [-1, 1] {
            let rail = SCNNode(geometry: SCNCylinder(radius: 0.032, height: CGFloat(height)))
            rail.geometry?.materials = [Mat.ladderSteel]
            rail.position = SCNVector3(side * 0.2, bottom + height / 2, 0)
            node.addChildNode(rail)
        }
        let rungGeo = SCNCylinder(radius: 0.022, height: 0.4)
        rungGeo.materials = [Mat.ladderSteel]
        var y = bottom + 0.2
        while y < top + 0.3 {
            let rung = SCNNode(geometry: rungGeo)
            rung.eulerAngles.z = .pi / 2
            rung.position = SCNVector3(0, y, 0)
            node.addChildNode(rung)
            y += 0.26
        }
        let flat = node.flattenedClone()
        flat.position = SCNVector3(x, 0, ladderZ)
        flat.castsShadow = true
        return flat
    }

    // MARK: Environment

    /// Static set dressing: ground, sea, icebergs, mountains, Nuuk, crane, tower frame, sign.
    static func environment(into root: SCNNode) -> (aurora: [SCNMaterial], beacons: [SCNNode], craneJib: SCNNode, sign: SCNNode) {
        // Snowy plateau the tower stands on.
        let land = SCNNode(geometry: SCNBox(width: 90, height: 2, length: 40, chamferRadius: 0.6))
        let snow = Mat.pbr(Tex.snowGround, rough: 0.85)
        snow.diffuse.wrapS = .repeat
        snow.diffuse.wrapT = .repeat
        snow.diffuse.contentsTransform = SCNMatrix4MakeScale(12, 6, 1)
        land.geometry?.materials = [snow]
        land.position = SCNVector3(0, -1, 4)
        root.addChildNode(land)

        // Concrete foundation under the ground floor girder.
        let foundation = SCNNode(geometry: SCNBox(width: 21, height: 0.5, length: 2.2, chamferRadius: 0.05))
        foundation.geometry?.materials = [Mat.concrete]
        foundation.position = SCNVector3(0, 0.15, -0.2)
        root.addChildNode(foundation)

        // Icy sea: a reflective floor that mirrors the aurora.
        let sea = SCNFloor()
        sea.reflectivity = 0.35
        sea.reflectionFalloffEnd = 60
        sea.reflectionResolutionScaleFactor = 0.4
        let water = Mat.pbr(UIColor(hex: 0x061423), metal: 0.2, rough: 0.12)
        sea.materials = [water]
        let seaNode = SCNNode(geometry: sea)
        seaNode.position = SCNVector3(0, -0.9, 0)
        root.addChildNode(seaNode)

        // Icebergs
        var rng = SeededRandom(seed: 42)
        let ice = Mat.pbr(UIColor(hex: 0x8fb4c8), rough: 0.35, clearCoat: 0.4)
        ice.transparency = 1
        for i in 0..<16 {
            let size = Float(1.5 + rng.next() * 3.5)
            let berg = SCNNode(geometry: MeshBuilder.iceberg(seed: UInt64(i + 1), size: size))
            berg.geometry?.materials = [ice]
            let side: Float = rng.next() < 0.5 ? -1 : 1
            berg.position = SCNVector3(side * Float(8 + rng.next() * 70), -0.9, Float(-34 - rng.next() * 90))
            berg.eulerAngles.y = Float(rng.next() * 6)
            root.addChildNode(berg)
        }

        // Distant snowy mountains
        let rock = Mat.pbr(UIColor(hex: 0x1b2433), rough: 0.9)
        let peak = Mat.pbr(UIColor(hex: 0xe6eef8), rough: 0.7)
        for i in 0..<11 {
            let h = CGFloat(22 + rng.next() * 40)
            let r = h * CGFloat(0.9 + rng.next() * 0.6)
            let mountain = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: r, height: h))
            mountain.geometry?.materials = [rock]
            let cap = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: r * 0.36, height: h * 0.36))
            cap.geometry?.materials = [peak]
            cap.position.y = Float(h * 0.32 + 0.05)
            mountain.addChildNode(cap)
            mountain.position = SCNVector3(Float(i - 5) * 34 + Float(rng.next() * 16), Float(h / 2) - 1, Float(-170 - rng.next() * 50))
            root.addChildNode(mountain)
        }

        // Colorful Nuuk houses with lit windows, on both sides of the tower.
        let houses = SCNNode()
        let colors: [UInt32] = [0xc8102e, 0xf2b71e, 0x1f6fb8, 0x2d8a4e, 0xe36a2a, 0x8b1a3d]
        let windowLit = Mat.glow(UIColor(hex: 0xffc56b), intensity: 2.2)
        let roof = Mat.pbr(UIColor(hex: 0x2a2a30), rough: 0.6)
        for i in 0..<26 {
            let side: Float = i % 2 == 0 ? -1 : 1
            let x = side * Float(15 + rng.next() * 32)
            let z = Float(-7 - rng.next() * 14)
            let w = CGFloat(1.6 + rng.next() * 1.4), hgt = CGFloat(1.2 + rng.next() * 1.1), d = CGFloat(1.4 + rng.next())
            let house = SCNNode(geometry: SCNBox(width: w, height: hgt, length: d, chamferRadius: 0.02))
            house.geometry?.materials = [Mat.pbr(UIColor(hex: colors[i % colors.count]), rough: 0.7)]
            house.position = SCNVector3(x, Float(hgt / 2), z)
            house.eulerAngles.y = Float(rng.next() - 0.5) * 0.6
            let r = SCNNode(geometry: SCNPyramid(width: w * 1.1, height: hgt * 0.55, length: d * 1.1))
            r.geometry?.materials = [roof]
            r.position.y = Float(hgt / 2)
            house.addChildNode(r)
            for wx in [-0.3, 0.3] where rng.next() < 0.8 {
                let win = SCNNode(geometry: SCNPlane(width: 0.3, height: 0.36))
                win.geometry?.materials = [windowLit]
                win.position = SCNVector3(Float(w) * Float(wx), 0.05, Float(d / 2) + 0.01)
                house.addChildNode(win)
            }
            houses.addChildNode(house)
        }
        root.addChildNode(houses)

        // Tower frame behind the girders: columns and cross bracing.
        let frame = SCNNode()
        let columnXs: [Float] = [-10.3, -5.15, 0, 5.15, 10.3]
        for x in columnXs {
            let col = SCNNode(geometry: SCNBox(width: 0.34, height: 15.2, length: 0.34, chamferRadius: 0.02))
            col.geometry?.materials = [Mat.steelGrey]
            col.position = SCNVector3(x, 7.6, -1.05)
            frame.addChildNode(col)
        }
        for i in 0..<(columnXs.count - 1) {
            for level in 0..<5 {
                let y0 = Float(level) * 3 + 0.4
                let dx = columnXs[i + 1] - columnXs[i]
                for flip: Float in [-1, 1] {
                    let len = hypot(dx, 3)
                    let brace = SCNNode(geometry: SCNBox(width: CGFloat(len), height: 0.08, length: 0.08, chamferRadius: 0))
                    brace.geometry?.materials = [Mat.steelGrey]
                    brace.position = SCNVector3(columnXs[i] + dx / 2, y0 + 1.5, -1.1)
                    brace.eulerAngles.z = flip * atan2(3, dx)
                    frame.addChildNode(brace)
                }
            }
        }
        let frameFlat = frame.flattenedClone()
        frameFlat.castsShadow = true
        root.addChildNode(frameFlat)

        // Neon sign on the roof.
        let sign = SCNNode()
        let text = SCNText(string: "TRUMP TOWER", extrusionDepth: 0.25)
        text.font = UIFont.systemFont(ofSize: 1, weight: .black)
        text.flatness = 0.02
        text.chamferRadius = 0.04
        let gold = Mat.pbr(UIColor(hex: 0xf5c542), metal: 1, rough: 0.22, emission: UIColor(hex: 0xffb020), emissionIntensity: 0.9)
        text.materials = [gold, gold, Mat.pbr(UIColor(hex: 0xb8860b), metal: 1, rough: 0.3)]
        let textNode = SCNNode(geometry: text)
        let (minB, maxB) = textNode.boundingBox
        textNode.pivot = SCNMatrix4MakeTranslation((maxB.x - minB.x) / 2 + minB.x, minB.y, 0)
        textNode.scale = SCNVector3(1.35, 1.35, 1.35)
        sign.addChildNode(textNode)
        let sub = SCNText(string: "NUUK · GREENLAND", extrusionDepth: 0.1)
        sub.font = UIFont.systemFont(ofSize: 1, weight: .heavy)
        sub.flatness = 0.05
        sub.materials = [Mat.glow(UIColor(hex: 0xff3b3b), intensity: 2.4)]
        let subNode = SCNNode(geometry: sub)
        let (sMin, sMax) = subNode.boundingBox
        subNode.pivot = SCNMatrix4MakeTranslation((sMax.x - sMin.x) / 2 + sMin.x, sMin.y, 0)
        subNode.scale = SCNVector3(0.5, 0.5, 0.5)
        subNode.position = SCNVector3(0, -0.72, 0.1)
        sign.addChildNode(subNode)
        sign.position = SCNVector3(0, 15.4, -1.4)
        root.addChildNode(sign)

        // Tower crane with a rotating jib and blinking beacons.
        let crane = SCNNode()
        let latticeMat = Mat.pbr(UIColor(hex: 0xf2b71e), metal: 0.5, rough: 0.45)
        latticeMat.transparent.contents = Tex.lattice
        latticeMat.transparencyMode = .aOne
        latticeMat.isDoubleSided = true
        latticeMat.diffuse.wrapS = .repeat
        latticeMat.diffuse.wrapT = .repeat
        latticeMat.transparent.wrapS = .repeat
        latticeMat.transparent.wrapT = .repeat
        latticeMat.transparent.contentsTransform = SCNMatrix4MakeScale(1, 22, 1)
        let mast = SCNNode(geometry: SCNBox(width: 1, height: 22, length: 1, chamferRadius: 0))
        mast.geometry?.materials = [latticeMat]
        mast.position = SCNVector3(0, 11, 0)
        crane.addChildNode(mast)
        let jib = SCNNode()
        jib.position = SCNVector3(0, 22.4, 0)
        let jibMat = latticeMat.copy() as! SCNMaterial
        jibMat.transparent.contentsTransform = SCNMatrix4MakeScale(26, 1, 1)
        let arm = SCNNode(geometry: SCNBox(width: 26, height: 0.8, length: 0.8, chamferRadius: 0))
        arm.geometry?.materials = [jibMat]
        arm.position = SCNVector3(-7, 0, 0)
        jib.addChildNode(arm)
        let counterweight = SCNNode(geometry: SCNBox(width: 2, height: 1.2, length: 1.2, chamferRadius: 0.05))
        counterweight.geometry?.materials = [Mat.concrete]
        counterweight.position = SCNVector3(4.5, -0.6, 0)
        jib.addChildNode(counterweight)
        let cabin = SCNNode(geometry: SCNBox(width: 1.3, height: 1.1, length: 1.2, chamferRadius: 0.1))
        cabin.geometry?.materials = [Mat.craneYellow]
        cabin.position = SCNVector3(0, -1, 0.9)
        jib.addChildNode(cabin)
        let cable = SCNNode(geometry: SCNCylinder(radius: 0.02, height: 9))
        cable.geometry?.materials = [Mat.steelGrey]
        cable.position = SCNVector3(-15, -4.5, 0)
        jib.addChildNode(cable)
        let hook = BarrelNodeFactory.make()
        hook.position = SCNVector3(-15, -9.2, 0)
        hook.eulerAngles.x = .pi / 2
        jib.addChildNode(hook)
        crane.addChildNode(jib)
        var beacons: [SCNNode] = []
        for (parent, p) in [(crane, SCNVector3(0, 23.1, 0)), (jib, SCNVector3(-19.8, 0.5, 0))] {
            let beacon = SCNNode(geometry: SCNSphere(radius: 0.22))
            beacon.geometry?.materials = [Mat.glow(UIColor(hex: 0xff2020), intensity: 4)]
            beacon.position = p
            parent.addChildNode(beacon)
            beacons.append(beacon)
        }
        crane.position = SCNVector3(17, 0, -7)
        crane.eulerAngles.y = 0.3
        root.addChildNode(crane)

        // Aurora curtains far behind everything.
        var auroraMaterials: [SCNMaterial] = []
        for (i, spec) in [(z: Float(-150), y: Float(48), w: CGFloat(420), h: CGFloat(90), seed: Float(0)), (z: -175, y: 62, w: 480, h: 110, seed: 3.7)].enumerated() {
            let plane = SCNPlane(width: spec.w, height: spec.h)
            let m = auroraMaterial(seed: spec.seed + Float(i))
            plane.materials = [m]
            auroraMaterials.append(m)
            let n = SCNNode(geometry: plane)
            n.position = SCNVector3(0, spec.y, spec.z)
            n.castsShadow = false
            n.renderingOrder = -10
            root.addChildNode(n)
        }

        return (auroraMaterials, beacons, jib, sign)
    }

    static func auroraMaterial(seed: Float) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = Tex.square
        m.isDoubleSided = true
        m.blendMode = .add
        m.writesToDepthBuffer = false
        m.readsFromDepthBuffer = true
        m.shaderModifiers = [.fragment: """
        #pragma arguments
        float4 tintA;
        float4 tintB;
        float seed;
        #pragma transparent
        #pragma body
        float2 uv = _surface.diffuseTexcoord;
        float t = scn_frame.time * 0.06 + seed;
        float x = uv.x * 7.0;
        float line = 0.62
            + sin(x * 0.9 + t * 1.7) * 0.10
            + sin(x * 2.3 - t * 1.1 + seed) * 0.05
            + sin(x * 5.1 + t * 2.3) * 0.015;
        float d = uv.y - line;
        float above = clamp(-d, 0.0, 1.0);
        float band = exp(-max(d, 0.0) * max(d, 0.0) * 900.0) * exp(-above * 3.4);
        float rays = 0.55 + 0.45 * sin(x * 38.0 + sin(x * 5.0 + t * 3.0) * 4.0);
        float fade = smoothstep(0.0, 0.18, uv.x) * smoothstep(1.0, 0.82, uv.x);
        float glow = band * rays * fade;
        float3 col = mix(tintA.rgb, tintB.rgb, clamp(above * 3.0, 0.0, 1.0));
        _output.color = float4(col * glow * 1.35, glow);
        """]
        return m
    }

    static func setAurora(_ materials: [SCNMaterial], theme: Theme) {
        for (i, m) in materials.enumerated() {
            let a = i == 0 ? theme.aurora : theme.aurora2
            let b = i == 0 ? theme.aurora2 : theme.aurora
            m.setValue(NSValue(scnVector4: a.vector4), forKey: "tintA")
            m.setValue(NSValue(scnVector4: b.vector4), forKey: "tintB")
            m.setValue(NSNumber(value: Float(i) * 2.3), forKey: "seed")
        }
    }
}

extension UIColor {
    var vector4: SCNVector4 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SCNVector4(Float(r), Float(g), Float(b), Float(a))
    }
}

enum MeshBuilder {
    /// A flat-shaded low-poly iceberg: a perturbed, subdivided icosahedron cut at the waterline.
    static func iceberg(seed: UInt64, size: Float) -> SCNGeometry {
        var rng = SeededRandom(seed: seed &* 2654435761)
        let t: Float = (1 + sqrt(5)) / 2
        var verts: [SIMD3<Float>] = [
            [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0],
            [0, -1, t], [0, 1, t], [0, -1, -t], [0, 1, -t],
            [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
        ].map { simd_normalize($0) }
        var faces: [(Int, Int, Int)] = [
            (0, 11, 5), (0, 5, 1), (0, 1, 7), (0, 7, 10), (0, 10, 11),
            (1, 5, 9), (5, 11, 4), (11, 10, 2), (10, 7, 6), (7, 1, 8),
            (3, 9, 4), (3, 4, 2), (3, 2, 6), (3, 6, 8), (3, 8, 9),
            (4, 9, 5), (2, 4, 11), (6, 2, 10), (8, 6, 7), (9, 8, 1),
        ]
        // One subdivision.
        var cache: [Int: Int] = [:]
        func mid(_ a: Int, _ b: Int) -> Int {
            let key = min(a, b) << 16 | max(a, b)
            if let i = cache[key] { return i }
            verts.append(simd_normalize((verts[a] + verts[b]) / 2))
            cache[key] = verts.count - 1
            return verts.count - 1
        }
        var sub: [(Int, Int, Int)] = []
        for (a, b, c) in faces {
            let ab = mid(a, b), bc = mid(b, c), ca = mid(c, a)
            sub += [(a, ab, ca), (b, bc, ab), (c, ca, bc), (ab, bc, ca)]
        }
        faces = sub
        let stretch = SIMD3<Float>(1 + Float(rng.next()) * 0.6, 0.55 + Float(rng.next()) * 0.7, 1 + Float(rng.next()) * 0.4)
        verts = verts.map { v in
            let n = 0.75 + Float(rng.next()) * 0.45
            var p = v * n * stretch * size
            p.y = max(p.y, -0.3 * size)
            return p
        }
        var positions: [SCNVector3] = []
        var normals: [SCNVector3] = []
        for (a, b, c) in faces {
            let pa = verts[a], pb = verts[b], pc = verts[c]
            let n = simd_normalize(simd_cross(pb - pa, pc - pa))
            for p in [pa, pb, pc] {
                positions.append(SCNVector3(p.x, p.y, p.z))
                normals.append(SCNVector3(n.x, n.y, n.z))
            }
        }
        let indices = (0..<Int32(positions.count)).map { $0 }
        return SCNGeometry(
            sources: [SCNGeometrySource(vertices: positions), SCNGeometrySource(normals: normals)],
            elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
        )
    }
}
