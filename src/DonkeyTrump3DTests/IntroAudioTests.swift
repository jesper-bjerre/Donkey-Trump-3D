import AVFoundation
import Testing
@testable import DonkeyTrump3D

@Suite("Intro and menu audio", .serialized)
struct IntroAudioTests {
    @Test func everyCuePlaysOnceAcrossFrameRatesAndStalls() {
        for level in LevelLibrary.layouts {
            let intro = IntroTimeline(level: level)
            let soundtrack = IntroSoundtrack(timeline: intro)
            // The long frame also exercises crossing several cue boundaries at once.
            for dt in [1.0 / 120, 1.0 / 60, 1.0 / 20, 0.73] {
                var played: [IntroSoundCue] = []
                var time = 0.0
                while time < intro.end {
                    let next = min(time + dt, intro.end)
                    played += soundtrack.cues(after: time, through: next)
                    time = next
                }
                #expect(played == soundtrack.cues)
                #expect(Set(played.map(\.sound)) == Set(IntroSound.allCases))
            }
        }
    }

    @Test func footstepsStopForSigningAndImpactsMatchLandings() {
        for level in LevelLibrary.layouts {
            let intro = IntroTimeline(level: level)
            let soundtrack = IntroSoundtrack(timeline: intro)
            for cue in soundtrack.cues where cue.sound == .step || cue.sound == .climb {
                #expect(intro.phase(at: cue.time) == .path)
                #expect(intro.pose(at: cue.time).action == (cue.sound == .step ? .walk : .climb))
            }
            let impacts = soundtrack.cues.filter { $0.sound == .impact }
            #expect(impacts.count == level.girders.count)
            for (order, cue) in impacts.enumerated() {
                let index = level.girders.count - 1 - order
                #expect(intro.tilts(at: cue.time - 0.001)[index] < 1)
                #expect(intro.tilts(at: cue.time + 0.001)[index] == 1)
            }
            let stamp = soundtrack.cues.first { $0.sound == .stamp }
            #expect(stamp?.time == intro.pathEnd + IntroTiming.sign * 0.8)
        }
    }

    @Test func reducedMotionAndSeekingDoNotReplayEarlierSounds() {
        let intro = IntroTimeline(level: LevelLibrary.layouts[0])
        let soundtrack = IntroSoundtrack(timeline: intro)
        let card = soundtrack.cues(after: intro.tiltEnd, through: intro.end)
        #expect(card.map(\.sound) == [.ready])
        #expect(soundtrack.cues(after: intro.end, through: intro.end + 1).isEmpty)
        #expect(soundtrack.cues(after: 4, through: 4).isEmpty)
        #expect(soundtrack.cues(after: 4, through: 0).isEmpty)
        let signing = soundtrack.cues(after: intro.pathEnd, through: intro.signEnd)
        #expect(!signing.contains { [.step, .climb, .drop, .sign].contains($0.sound) })
    }

    @Test func bundledIntroEffectsDecodeAndFitTheirAnimation() throws {
        let limits: [(String, Double)] = [
            ("intro-step", 0.18), ("intro-climb", 0.22), ("intro-drop", IntroTiming.dropPause),
            ("intro-sign", IntroTiming.sign * 0.8), ("intro-stamp", IntroTiming.sign * 0.2),
            ("intro-creak", IntroTiming.tiltPerGirder), ("intro-impact", IntroTiming.tiltPerGirder),
            ("intro-ready", IntroTiming.card - 0.15),
        ]
        for (file, maximumDuration) in limits {
            let url = try #require(Bundle.main.url(forResource: file, withExtension: "wav"))
            let player = try AVAudioPlayer(contentsOf: url)
            #expect(player.duration > 0)
            #expect(player.duration <= maximumDuration)
            #expect(player.prepareToPlay())
        }
    }

    @Test func delayedPreparationDoesNotBlockControlsOrReplayStoppedAudio() async {
        let queue = DispatchQueue(label: "test.delayed-audio")
        queue.suspend()
        let audio = AudioSystem(preparationQueue: queue)
        #expect(!audio.isPrepared)
        audio.play("intro", looping: true)
        audio.play("introStamp")
        audio.startMusic(level: 2)
        audio.stopIntro(); audio.stopMusic()
        let muted = audio.muted
        audio.muted = !muted; audio.muted = muted
        #expect(!audio.isPrepared)
        queue.resume()
        await waitForPreparation(audio)
        #expect(!audio.isPlaying("intro"))
        #expect(!audio.isPlaying("introStamp"))
        #expect(!audio.isPlaying("music"))
    }

    @Test func currentLoopAndPausedMusicSurvivePreparation() async {
        let queue = DispatchQueue(label: "test.paused-audio")
        queue.suspend()
        let audio = AudioSystem(preparationQueue: queue)
        audio.play("intro", looping: true)
        audio.startMusic(level: 1); audio.pauseMusic()
        queue.resume()
        await waitForPreparation(audio)
        #expect(audio.isPlaying("intro"))
        audio.stopIntro()
        #expect(!audio.isPlaying("music"))
        audio.resumeMusic()
        #expect(audio.isPlaying("music"))
        audio.stopMusic()
    }

    @Test func bundledMenuTrackDecodesAsStereoMP3() throws {
        let url = try #require(Bundle.main.url(forResource: "menu-music", withExtension: "mp3"))
        let player = try AVAudioPlayer(contentsOf: url)
        #expect(player.duration > 71 && player.duration < 72)
        #expect(player.numberOfChannels == 2)
        #expect(player.prepareToPlay())
    }

    @Test func menuDoesNotStartAfterLeavingWhileAudioIsLoading() async {
        let queue = DispatchQueue(label: "test.menu-skip")
        queue.suspend()
        let audio = AudioSystem(preparationQueue: queue)
        audio.setMenuMusicActive(true)
        audio.startMenuMusic()
        audio.stopMenuMusic() // Start takes us into the intro before decoding finishes.
        audio.play("intro", looping: true)
        #expect(!audio.isPrepared)
        queue.resume()
        await waitForPreparation(audio)
        #expect(!audio.isPlaying("menuMusic"))
        #expect(audio.isPlaying("intro"))
        audio.stopIntro()
    }

    @Test func menuWaitsForForegroundEvenWhenLoadingOrReturningToTitle() async {
        let queue = DispatchQueue(label: "test.menu-background")
        queue.suspend()
        let audio = AudioSystem(preparationQueue: queue)
        audio.setMenuMusicActive(true)
        audio.startMenuMusic()
        audio.setMenuMusicActive(false)
        queue.resume()
        await waitForPreparation(audio)
        #expect(!audio.isPlaying("menuMusic"))
        audio.setMenuMusicActive(true)
        #expect(audio.isPlaying("menuMusic"))
        audio.setMenuMusicActive(false)
        #expect(!audio.isPlaying("menuMusic"))
        audio.stopMenuMusic()
        audio.startMenuMusic() // A late render-thread title command while inactive.
        #expect(!audio.isPlaying("menuMusic"))
        audio.setMenuMusicActive(true)
        #expect(audio.isPlaying("menuMusic"))
        audio.stopMenuMusic()
        audio.setMenuMusicActive(false); audio.setMenuMusicActive(true)
        #expect(!audio.isPlaying("menuMusic"))
    }

    @Test func menuRespectsSoundSettingAndGameplayTransition() async {
        let queue = DispatchQueue(label: "test.menu-mute")
        queue.suspend()
        let audio = AudioSystem(preparationQueue: queue)
        let originalMute = audio.muted
        defer { audio.stopMenuMusic(); audio.stopMusic(); audio.muted = originalMute }
        audio.muted = true
        audio.setMenuMusicActive(true)
        audio.startMenuMusic()
        queue.resume()
        await waitForPreparation(audio)
        #expect(audio.isPlaying("menuMusic"))
        #expect(audio.menuMusicVolume == 0)
        audio.muted = false
        #expect(audio.menuMusicVolume == 0.35)
        audio.muted = true
        #expect(audio.menuMusicVolume == 0)
        audio.startMusic(level: 0)
        #expect(!audio.isPlaying("menuMusic"))
        #expect(audio.isPlaying("music"))
        audio.stopMusic()
        audio.startMenuMusic()
        #expect(audio.isPlaying("menuMusic"))
        #expect(!audio.isPlaying("music"))
    }

    private func waitForPreparation(_ audio: AudioSystem) async {
        for _ in 0..<1_000 {
            if audio.isPrepared { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(audio.isPrepared)
    }

    @Test func gameAudioUsesPlaybackWithMixing() async {
        await waitForPreparation(AudioSystem.shared)
        let session = AVAudioSession.sharedInstance()
        #expect(session.category == .playback)
        #expect(session.categoryOptions.contains(.mixWithOthers))
    }
}
