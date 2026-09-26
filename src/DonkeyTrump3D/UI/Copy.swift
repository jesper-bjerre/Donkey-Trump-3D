import Foundation

/// All player-facing English copy in one place, for the native iPhone game.
enum Copy {
    static let title = "DONKEY TRUMP"
    static let tagline = "Climb. Dodge. Rescue Motzfeldt."
    static let start = "Start Game"
    static let howTo = "How to Play"
    static let parody = "An original satirical parody. Not affiliated with any game publisher or politician."
    static let accountFree = "No account. No tracking. Just play."

    static let howToGoal = "Climb the girders and reach Motzfeldt at the top. The levels never end, and every rescue makes the barrels faster. Watch out: some are hurled straight at you!"
    static let howToLines: [(icon: String, text: String)] = [
        ("hand.draw", "Left thumb: drag anywhere on the left half to move"),
        ("arrow.up.and.down", "Push up or down on a ladder to climb (hold up mid-jump to grab one)"),
        ("arrowshape.up.fill", "Right thumb: tap anywhere on the right half to jump over barrels"),
        ("gamecontroller.fill", "Game controllers and keyboards work too: A / Space jumps, Menu / P pauses"),
        ("stairs", "You cannot jump from one floor to the next. Use the ladders."),
        ("star.fill", "+100 per barrel jumped, +1000 per rescue. A hit retries the level and keeps your score."),
    ]
    static let privacy = "No accounts or tracking. Your personal best and settings stay on this iPhone. If you choose to submit a highscore, your chosen name and score are public. Failed submissions are not queued or sent later."
    static let highscoreUnconfirmed = "We couldn't confirm whether your score was saved."
    static let highscoreUnavailable = "Highscores are unavailable. Your personal best is saved on this iPhone."
    static let publicScoreNotice = "Your name and score will be public. You do not need to use your real name."

    static let objective = "Rescue Motzfeldt!"
    static let ladderHint = "Use the ladders — you can't jump between floors"

    static let paused = "Paused"
    static let resume = "Resume"
    static let restart = "Restart from Level 1"
    static let toTitle = "Return to Title"

    static let lifeLost = "Ouch! A barrel got you."
    static let retrying = "Try again..."
    static let gameOver = "GAME OVER"
    static let finalScore = "Final score"
    static let levelReached = "Level reached"
    static let newBest = "NEW BEST!"
    static let playAgain = "Play Again"

    static let rescued = "Motzfeldt rescued!"
    static let nextFaster = "Get ready: the next level is faster..."

    static let orderTitle = "EXECUTIVE ORDER"
    static let orderText = "ALL GIRDERS SLANTED.\nEFFECTIVE IMMEDIATELY."
    static let orderSeal = "The White House · Nuuk Annex"
    static let cardGoal = "Jumpman Løkke, rescue Motzfeldt!"
    static let skip = "Skip"
}
