import AVFoundation
import UIKit

/// Original synthesized effects and gameplay loop, plus the owner-supplied menu
/// soundtrack. Every call is safe
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
    private var menuMusic: AVAudioPlayer?
    private var menuMusicRequested = false
    private var menuMusicActive = false
    private var prepared = false
    // Only current loops survive preparation. One-shot cues are never queued.
    private var requestedLoops: [String: Float] = [:]
    private var requestedMusicLevel: Int?
    private var musicPaused = false

    var isPrepared: Bool {
        lock.lock(); defer { lock.unlock() }
        return prepared
    }

    #if DEBUG
    func isPlaying(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if key == "menuMusic" { return menuMusic?.isPlaying == true }
        return key == "music" ? music?.isPlaying == true : voices[key]?.contains { $0.isPlaying } == true
    }

    var menuMusicVolume: Float? {
        lock.lock(); defer { lock.unlock() }
        return menuMusic?.volume
    }
    #endif
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
            menuMusic?.volume = newValue ? 0 : 0.35
        }
    }

    init(preparationQueue: DispatchQueue = DispatchQueue(label: "com.hyldenbrandt.donkeytrump3d.audio-preparation", qos: .utility)) {
        isMuted = UserDefaults.standard.bool(forKey: "muted")
        // Audio is optional at launch. Never prepare players or activate the
        // audio session on the UI thread, or hold the playback lock while loading.
        preparationQueue.async { [self] in prepareAudio() }
    }

    private func prepareAudio() {
        // Game audio stays audible with the physical silent switch enabled.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        // Publish the loading/menu track first; it need not wait for all effects.
        // Decode/prepare outside the lock so controls and scene startup stay free.
        if let url = Bundle.main.url(forResource: "menu-music", withExtension: "mp3"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            lock.lock()
            menuMusic = player
            player.volume = isMuted ? 0 : 0.35
            if menuMusicRequested && menuMusicActive { player.play() }
            lock.unlock()
        }
        var loadedVoices: [String: [AVAudioPlayer]] = [:]
        for (key, spec) in AudioSystem.files {
            guard let url = Bundle.main.url(forResource: spec.file, withExtension: "wav") else { continue }
            loadedVoices[key] = (0..<spec.voices).compactMap { _ in
                let player = try? AVAudioPlayer(contentsOf: url)
                player?.enableRate = true
                player?.volume = 0
                player?.prepareToPlay()
                return player
            }
        }
        var loadedMusic: AVAudioPlayer?
        if let url = Bundle.main.url(forResource: "music-loop", withExtension: "wav") {
            loadedMusic = try? AVAudioPlayer(contentsOf: url)
            loadedMusic?.numberOfLoops = -1
            loadedMusic?.enableRate = true
            loadedMusic?.volume = 0
            loadedMusic?.prepareToPlay()
        }
        lock.lock(); defer { lock.unlock() }
        voices = loadedVoices; music = loadedMusic
        for (key, pool) in voices {
            pool.forEach { $0.volume = isMuted ? 0 : AudioSystem.files[key]?.volume ?? 0 }
        }
        music?.volume = isMuted ? 0 : 0.22
        prepared = true
        // Stop/skip/mute/pause can run while preparation is in progress. Apply
        // only their latest intent; never replay an intro that has already ended.
        for (key, rate) in requestedLoops {
            let player = voices[key]?.first
            player?.rate = rate; player?.numberOfLoops = -1; player?.play()
        }
        if let level = requestedMusicLevel {
            music?.rate = min(1.6, 1 + Float(max(0, level)) * 0.08)
            if !musicPaused { music?.play() }
        }
    }

    func play(_ key: String, rate: Float = 1, looping: Bool = false) {
        lock.lock(); defer { lock.unlock() }
        if looping { requestedLoops[key] = rate }
        else { requestedLoops.removeValue(forKey: key) }
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
        requestedLoops.removeValue(forKey: key)
        voices[key]?.forEach { $0.stop() }
    }

    func stopIntro() {
        lock.lock(); defer { lock.unlock() }
        for key in ["intro"] + IntroSound.allCases.map(\.rawValue) {
            requestedLoops.removeValue(forKey: key)
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
        menuMusicRequested = false
        menuMusic?.stop()
        requestedMusicLevel = level; musicPaused = false
        guard let music else { return }
        music.rate = min(1.6, 1 + Float(max(0, level)) * 0.08)
        music.volume = isMuted ? 0 : 0.22
        music.currentTime = 0
        music.play()
    }

    func stopMusic() {
        lock.lock(); defer { lock.unlock() }
        requestedMusicLevel = nil; musicPaused = false
        music?.stop()
    }

    func pauseMusic() {
        lock.lock(); defer { lock.unlock() }
        musicPaused = true
        music?.pause()
    }

    func resumeMusic() {
        lock.lock(); defer { lock.unlock() }
        musicPaused = false
        if requestedMusicLevel != nil, let music, !music.isPlaying { music.play() }
    }

    /// One continuous track across loading, title and title overlays.
    func startMenuMusic() {
        lock.lock(); defer { lock.unlock() }
        if !menuMusicRequested { menuMusic?.currentTime = 0 }
        menuMusicRequested = true
        if menuMusicActive, let menuMusic, !menuMusic.isPlaying { menuMusic.play() }
    }

    func stopMenuMusic() {
        lock.lock(); defer { lock.unlock() }
        menuMusicRequested = false
        menuMusic?.stop()
    }

    /// Scene activity is independent of the render thread's title/intro intent.
    /// A late load or queued return to title cannot start music in the background.
    func setMenuMusicActive(_ active: Bool) {
        lock.lock(); defer { lock.unlock() }
        menuMusicActive = active
        if active && menuMusicRequested {
            if let menuMusic, !menuMusic.isPlaying { menuMusic.play() }
        } else { menuMusic?.pause() }
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
