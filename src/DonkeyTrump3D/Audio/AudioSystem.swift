import AVFoundation
import UIKit

/// Sound effects, jingles and the background loop, from the web game's original
/// synthesized WAVs and original arcade-style intro effects. Every call is safe
/// when audio is missing: sound never blocks play.
final class AudioSystem {
    static let shared = AudioSystem()

    private static let files: [String: (file: String, volume: Float, voices: Int)] = [
        "step": ("step", 0.25, 3),
        "jump": ("jump", 0.45, 2),
        "score": ("score", 0.5, 3),
        "throw": ("throw", 0.45, 3),
        "hit": ("hit", 0.6, 1),
        "rescue": ("rescue", 0.6, 1),
        "retry": ("retry", 0.5, 1),
        "levelStart": ("level-start", 0.55, 1),
        "gameOver": ("game-over", 0.55, 1),
        "victory": ("victory", 0.55, 1),
        "intro": ("intro", 0.55, 1),
        "introStep": ("intro-step", 0.45, 2),
        "introClimb": ("intro-climb", 0.35, 2),
        "introDrop": ("intro-drop", 0.45, 1),
        "introSign": ("intro-sign", 0.4, 1),
        "introStamp": ("intro-stamp", 0.55, 1),
        "introCreak": ("intro-creak", 0.35, 2),
        "introImpact": ("intro-impact", 0.6, 2),
        "introReady": ("intro-ready", 0.5, 1),
    ]

    private let lock = NSLock()
    private var voices: [String: [AVAudioPlayer]] = [:]
    private var music: AVAudioPlayer?
    private var lastStep = 0.0
    private var stepFlip = false

    private var isMuted: Bool

    var muted: Bool {
        get {
            lock.lock(); defer { lock.unlock() }
            return isMuted
        }
        set {
            lock.lock(); defer { lock.unlock() }
            isMuted = newValue
            UserDefaults.standard.set(newValue, forKey: "muted")
            // Silence active jingles and looping intro audio immediately as well.
            for (key, pool) in voices {
                pool.forEach { $0.volume = newValue ? 0 : AudioSystem.files[key]?.volume ?? 0 }
            }
            music?.volume = newValue ? 0 : 0.22
        }
    }

    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "muted")
        // Game audio stays audible with the Ring/Silent switch set to silent.
        // The in-game mute toggle still controls all sound, and other apps can mix.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for (key, spec) in AudioSystem.files {
            guard let url = Bundle.main.url(forResource: spec.file, withExtension: "wav") else { continue }
            voices[key] = (0..<spec.voices).compactMap { _ in
                let p = try? AVAudioPlayer(contentsOf: url)
                p?.enableRate = true
                p?.volume = isMuted ? 0 : spec.volume
                p?.prepareToPlay()
                return p
            }
        }
        if let url = Bundle.main.url(forResource: "music-loop", withExtension: "wav") {
            music = try? AVAudioPlayer(contentsOf: url)
            music?.numberOfLoops = -1
            music?.enableRate = true
            music?.volume = isMuted ? 0 : 0.22
            music?.prepareToPlay()
        }
    }

    func play(_ key: String, rate: Float = 1, looping: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        // Keep a muted loop in sync so unmuting can reveal the current phrase.
        guard (!isMuted || looping), let pool = voices[key] else { return }
        let player = pool.first { !$0.isPlaying } ?? pool.first
        player?.currentTime = 0
        player?.rate = rate
        player?.numberOfLoops = looping ? -1 : 0
        player?.play()
    }

    func stop(_ key: String) {
        lock.lock(); defer { lock.unlock() }
        voices[key]?.forEach { $0.stop() }
    }

    func stopIntro() {
        lock.lock(); defer { lock.unlock() }
        for key in ["intro"] + IntroSound.allCases.map(\.rawValue) {
            voices[key]?.forEach { $0.stop() }
        }
    }

    /// Throttled footstep that alternates pitch between left and right steps.
    func step(now: Double, interval: Double = 0.17) {
        guard now - lastStep >= interval else { return }
        lastStep = now
        stepFlip.toggle()
        play("step", rate: stepFlip ? 1 : 1.15)
    }

    /// Later levels play the loop faster to raise the tension.
    func startMusic(level: Int) {
        lock.lock(); defer { lock.unlock() }
        guard let music else { return }
        music.rate = min(1.6, 1 + Float(max(0, level)) * 0.08)
        music.volume = isMuted ? 0 : 0.22
        music.currentTime = 0
        music.play()
    }

    func stopMusic() {
        lock.lock(); defer { lock.unlock() }
        music?.stop()
    }

    func pauseMusic() {
        lock.lock(); defer { lock.unlock() }
        music?.pause()
    }

    func resumeMusic() {
        lock.lock(); defer { lock.unlock() }
        if let music, !music.isPlaying, music.currentTime > 0 { music.play() }
    }
}

enum Haptics {
    static var enabled: Bool {
        get { UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "haptics") }
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1) {
        guard enabled else { return }
        DispatchQueue.main.async { UIImpactFeedbackGenerator(style: style).impactOccurred(intensity: intensity) }
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        DispatchQueue.main.async { UINotificationFeedbackGenerator().notificationOccurred(type) }
    }
}
