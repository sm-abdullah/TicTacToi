//
//  GameScene.swift
//  TicTacToi
//
//  Created by Abdullah Syed on 18.02.26.
//

import SpriteKit
import UIKit

final class GameScene: SKScene {

    private enum Player: String {
        case x = "X"
        case o = "O"
    }
    
    private enum GameMode {
        case friend
        case computer
    }
    
    private enum Difficulty: String {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
    }

    private struct Move {
        let row: Int
        let col: Int
        let player: Player
    }

    private var board = Array(repeating: Array(repeating: Player?.none, count: 3), count: 3)
    private var marks = Array(repeating: Array(repeating: SKNode?.none, count: 3), count: 3)
    private var moveHistory: [Move] = []
    private var currentPlayer: Player = .x
    private var gameEnded = false
    private var messageLabel: SKLabelNode?
    private var modeLabel: SKLabelNode?
    private var scoreLabel: SKLabelNode?
    private var resetScoreButton: SKNode?
    private var modeButton: SKNode?
    private var soundButton: SKNode?
    private var soundIconLabel: SKLabelNode?
    private var winLineNode: SKShapeNode?
    private var selectionOverlay: SKNode?
    private var boardFrame: CGRect = .zero
    private var xWins = 0
    private var oWins = 0
    private let xWinsKey = "score_x_wins"
    private let oWinsKey = "score_o_wins"
    private let soundEnabledKey = "sound_enabled"
    private let gameStrokeColor = SKColor(red: 0.16, green: 0.21, blue: 0.38, alpha: 1.0)
    private let xMoveSound = SKAction.playSoundFileNamed("move_x.wav", waitForCompletion: false)
    private let oMoveSound = SKAction.playSoundFileNamed("move_o.wav", waitForCompletion: false)
    private let winSound = SKAction.playSoundFileNamed("win.wav", waitForCompletion: false)
    private var soundEnabled = true
    private var gameMode: GameMode = .friend
    private var difficulty: Difficulty = .easy
    private var humanPlayer: Player = .x
    private var computerPlayer: Player = .o
    private var isComputerThinking = false
    private var isTurnTransitioning = false
    private var isSelectingMode = true
    private let aiQueue = DispatchQueue(label: "com.tictactoi.ai", qos: .userInitiated)
    private var aiRequestID: UUID?
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()
    var onSceneReady: (() -> Void)?

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1.0)
        loadScores()
        loadSoundPreference()
        setupBoard()
        setupMessageLabel()
        setupModeLabel()
        setupScoreLabel()
        setupResetScoreButton()
        setupModeButton()
        setupSoundButton()
        updateTurnText()
        updateModeText()
        updateScoreText()
        presentModeSelection()
        lightImpact.prepare()
        mediumImpact.prepare()
        successFeedback.prepare()
        DispatchQueue.main.async { [weak self] in
            self?.onSceneReady?()
        }
    }

    private func setupBoard() {
        let boardSize = min(size.width, size.height) * 0.75
        let boardOrigin = CGPoint(x: (size.width - boardSize) / 2, y: (size.height - boardSize) / 2)
        boardFrame = CGRect(origin: boardOrigin, size: CGSize(width: boardSize, height: boardSize))

        let thickness = max(4, boardSize * 0.01)
        let step = boardSize / 3.0

        for index in 1...2 {
            let offset = CGFloat(index) * step

            let verticalPath = CGMutablePath()
            verticalPath.move(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y))
            verticalPath.addLine(to: CGPoint(x: boardOrigin.x + offset, y: boardOrigin.y + boardSize))
            let verticalLine = SKShapeNode(path: verticalPath)
            verticalLine.strokeColor = gameStrokeColor
            verticalLine.lineWidth = thickness
            addChild(verticalLine)

            let horizontalPath = CGMutablePath()
            horizontalPath.move(to: CGPoint(x: boardOrigin.x, y: boardOrigin.y + offset))
            horizontalPath.addLine(to: CGPoint(x: boardOrigin.x + boardSize, y: boardOrigin.y + offset))
            let horizontalLine = SKShapeNode(path: horizontalPath)
            horizontalLine.strokeColor = gameStrokeColor
            horizontalLine.lineWidth = thickness
            addChild(horizontalLine)
        }

    }

    private func setupMessageLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.fontSize = 28
        label.fontColor = SKColor(red: 0.1, green: 0.13, blue: 0.25, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: boardFrame.maxY + 50)
        label.verticalAlignmentMode = .center
        addChild(label)
        messageLabel = label
    }

    private func setupScoreLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.fontSize = 22
        label.fontColor = SKColor(red: 0.18, green: 0.22, blue: 0.38, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: boardFrame.minY - 40)
        label.verticalAlignmentMode = .center
        addChild(label)
        scoreLabel = label
    }
    
    private func setupModeLabel() {
        let label = SKLabelNode(fontNamed: "AvenirNext-Medium")
        label.fontSize = 18
        label.fontColor = SKColor(red: 0.18, green: 0.22, blue: 0.38, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: boardFrame.maxY + 24)
        label.verticalAlignmentMode = .center
        addChild(label)
        modeLabel = label
    }

    private func setupResetScoreButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 180, height: 40), cornerRadius: 12)
        button.fillColor = SKColor(red: 0.18, green: 0.24, blue: 0.42, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.24, green: 0.31, blue: 0.52, alpha: 1.0)
        button.lineWidth = 2
        button.position = CGPoint(x: size.width / 2, y: boardFrame.minY - 82)
        button.name = "reset-score-button"

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "Reset Score"
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "reset-score-button"
        button.addChild(label)

        addChild(button)
        resetScoreButton = button
    }
    
    private func setupModeButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 110, height: 36), cornerRadius: 10)
        button.fillColor = SKColor(red: 0.18, green: 0.24, blue: 0.42, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.24, green: 0.31, blue: 0.52, alpha: 1.0)
        button.lineWidth = 2
        button.position = CGPoint(x: 72, y: size.height - 44)
        button.name = "mode-button"
        
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = "Mode"
        label.fontSize = 17
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = "mode-button"
        button.addChild(label)
        
        addChild(button)
        modeButton = button
    }

    private func setupSoundButton() {
        let button = SKShapeNode(circleOfRadius: 20)
        button.fillColor = SKColor(red: 0.18, green: 0.24, blue: 0.42, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.24, green: 0.31, blue: 0.52, alpha: 1.0)
        button.lineWidth = 2
        button.position = CGPoint(x: size.width - 44, y: size.height - 44)
        button.name = "sound-button"

        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.fontSize = 18
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.fontColor = .white
        label.name = "sound-button"
        button.addChild(label)
        soundIconLabel = label

        addChild(button)
        soundButton = button
        updateSoundButtonUI()
    }

    private func centerPoint(forRow row: Int, col: Int) -> CGPoint {
        let step = boardFrame.width / 3.0
        let x = boardFrame.minX + (CGFloat(col) + 0.5) * step
        let y = boardFrame.maxY - (CGFloat(row) + 0.5) * step
        return CGPoint(x: x, y: y)
    }

    private func rowCol(for point: CGPoint) -> (Int, Int)? {
        guard boardFrame.contains(point) else { return nil }
        let step = boardFrame.width / 3.0
        let col = min(2, max(0, Int((point.x - boardFrame.minX) / step)))
        let row = min(2, max(0, Int((boardFrame.maxY - point.y) / step)))
        return (row, col)
    }

    private func placeMove(row: Int, col: Int) {
        guard board[row][col] == nil, !gameEnded, !isTurnTransitioning else { return }

        let playedPlayer = currentPlayer
        board[row][col] = playedPlayer
        marks[row][col] = createAnimatedMark(for: playedPlayer, row: row, col: col)
        moveHistory.append(Move(row: row, col: col, player: playedPlayer))
        playMoveFeedback(for: playedPlayer)
        isTurnTransitioning = true
        let animationDelay = markAnimationDuration(for: playedPlayer)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) { [weak self] in
            self?.completeTurn(after: playedPlayer)
        }
    }
    
    private func markAnimationDuration(for player: Player) -> TimeInterval {
        if player == .o {
            return 0.34
        }
        // X draws two strokes with a small wait between them.
        return 0.38
    }
    
    private func scheduleComputerTurnIfNeeded(after delay: TimeInterval) {
        guard gameMode == .computer, currentPlayer == computerPlayer, !gameEnded else { return }
        let requestID = UUID()
        aiRequestID = requestID
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            guard self.aiRequestID == requestID, !self.gameEnded, self.currentPlayer == self.computerPlayer else { return }
            self.handleComputerTurnIfNeeded()
        }
    }
    
    private func completeTurn(after playedPlayer: Player) {
        isComputerThinking = false
        if let result = winningResult() {
            gameEnded = true
            aiRequestID = nil
            drawWinLine(for: result.line)
            playWinFeedback()
            if result.player == .x {
                xWins += 1
            } else {
                oWins += 1
            }
            saveScores()
            updateScoreText()
            messageLabel?.text = "\(result.player.rawValue) wins! Tap to restart"
            isTurnTransitioning = false
            return
        }
        
        if isDraw() {
            aiRequestID = nil
            undoLastMoveAfterDraw()
            isTurnTransitioning = false
            scheduleComputerTurnIfNeeded(after: 0.0)
            return
        }
        
        currentPlayer = playedPlayer == .x ? .o : .x
        updateTurnText()
        isTurnTransitioning = false
        scheduleComputerTurnIfNeeded(after: 0.0)
    }

    private func winningResult() -> (player: Player, line: [(Int, Int)])? {
        let lines: [[(Int, Int)]] = [
            [(0, 0), (0, 1), (0, 2)],
            [(1, 0), (1, 1), (1, 2)],
            [(2, 0), (2, 1), (2, 2)],
            [(0, 0), (1, 0), (2, 0)],
            [(0, 1), (1, 1), (2, 1)],
            [(0, 2), (1, 2), (2, 2)],
            [(0, 0), (1, 1), (2, 2)],
            [(0, 2), (1, 1), (2, 0)]
        ]

        for line in lines {
            guard let first = board[line[0].0][line[0].1] else { continue }
            if board[line[1].0][line[1].1] == first && board[line[2].0][line[2].1] == first {
                return (first, line)
            }
        }

        return nil
    }

    private func isDraw() -> Bool {
        for row in board {
            if row.contains(where: { $0 == nil }) {
                return false
            }
        }
        return true
    }

    private func removeMove(_ move: Move) {
        if let idx = moveHistory.lastIndex(where: { $0.row == move.row && $0.col == move.col && $0.player == move.player }) {
            moveHistory.remove(at: idx)
        }
        board[move.row][move.col] = nil
        marks[move.row][move.col]?.removeFromParent()
        marks[move.row][move.col] = nil
    }

    private func removeEarliestMove(for player: Player) {
        guard let earliest = moveHistory.first(where: { $0.player == player }) else { return }
        removeMove(earliest)
    }

    private func undoLastMoveAfterDraw() {
        removeEarliestMove(for: .x)
        removeEarliestMove(for: .o)

        // Continue from X after board is reopened from draw.
        currentPlayer = .x
        updateTurnText()
    }

    private func updateTurnText() {
        if gameMode == .computer {
            if currentPlayer == humanPlayer {
                messageLabel?.text = "Your turn (\(humanPlayer.rawValue))"
            } else {
                messageLabel?.text = "AI turn (\(computerPlayer.rawValue))"
            }
        } else {
            messageLabel?.text = "\(currentPlayer.rawValue) turn"
        }
    }
    
    private func updateModeText() {
        if gameMode == .friend {
            modeLabel?.text = "Mode: Friend"
        } else {
            modeLabel?.text = "Mode: AI (\(difficulty.rawValue))"
        }
    }

    private func updateScoreText() {
        scoreLabel?.text = "Score  X: \(xWins)   O: \(oWins)"
    }

    private func loadScores() {
        let defaults = UserDefaults.standard
        xWins = defaults.integer(forKey: xWinsKey)
        oWins = defaults.integer(forKey: oWinsKey)
    }

    private func saveScores() {
        let defaults = UserDefaults.standard
        defaults.set(xWins, forKey: xWinsKey)
        defaults.set(oWins, forKey: oWinsKey)
    }

    private func loadSoundPreference() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: soundEnabledKey) == nil {
            soundEnabled = true
        } else {
            soundEnabled = defaults.bool(forKey: soundEnabledKey)
        }
    }

    private func saveSoundPreference() {
        UserDefaults.standard.set(soundEnabled, forKey: soundEnabledKey)
    }

    private func toggleSound() {
        soundEnabled.toggle()
        saveSoundPreference()
        updateSoundButtonUI()
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    private func updateSoundButtonUI() {
        soundIconLabel?.text = soundEnabled ? "🔊" : "🔇"
    }

    private func resetScores() {
        xWins = 0
        oWins = 0
        saveScores()
        updateScoreText()
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: Player?.none, count: 3), count: 3)
        moveHistory.removeAll()
        assignRandomSymbolsForRound()
        gameEnded = false
        isComputerThinking = false
        isTurnTransitioning = false
        aiRequestID = nil
        winLineNode?.removeFromParent()
        winLineNode = nil
        for row in 0..<3 {
            for col in 0..<3 {
                marks[row][col]?.removeFromParent()
                marks[row][col] = nil
            }
        }
        updateTurnText()
        handleComputerTurnIfNeeded()
    }
    
    private func assignRandomSymbolsForRound() {
        if gameMode == .computer {
            humanPlayer = Bool.random() ? .x : .o
            computerPlayer = humanPlayer == .x ? .o : .x
            currentPlayer = .x
            if modeLabel != nil {
                modeLabel?.text = "Mode: AI (\(difficulty.rawValue)) • You: \(humanPlayer.rawValue)"
            }
        } else {
            // Friend mode still randomizes which symbol starts each round.
            humanPlayer = .x
            computerPlayer = .o
            currentPlayer = Bool.random() ? .x : .o
            if modeLabel != nil {
                modeLabel?.text = "Mode: Friend • Start: \(currentPlayer.rawValue)"
            }
        }
    }
    
    private func presentModeSelection() {
        selectionOverlay?.removeFromParent()
        isSelectingMode = true
        isComputerThinking = false
        isTurnTransitioning = false
        aiRequestID = nil
        setHUDHidden(true)
        
        let overlay = SKNode()
        overlay.zPosition = 200
        
        let bg = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        bg.fillColor = SKColor(white: 0, alpha: 0.72)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.name = "mode-overlay"
        overlay.addChild(bg)
        
        let card = SKShapeNode(rectOf: CGSize(width: min(size.width * 0.82, 420), height: 340), cornerRadius: 18)
        card.fillColor = SKColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 1.0)
        card.strokeColor = SKColor(red: 0.82, green: 0.86, blue: 0.95, alpha: 1.0)
        card.lineWidth = 2
        card.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(card)
        
        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "Choose Playing Mode"
        title.fontSize = 26
        title.fontColor = gameStrokeColor
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 130)
        overlay.addChild(title)
        
        overlay.addChild(makeSelectionButton(title: "Play with Friend", name: "mode-friend", at: CGPoint(x: size.width / 2, y: size.height / 2 + 56)))
        overlay.addChild(makeSelectionButton(title: "Easy", name: "mode-cpu-easy", at: CGPoint(x: size.width / 2, y: size.height / 2 + 6)))
        overlay.addChild(makeSelectionButton(title: "Medium", name: "mode-cpu-medium", at: CGPoint(x: size.width / 2, y: size.height / 2 - 44)))
        overlay.addChild(makeSelectionButton(title: "Hard", name: "mode-cpu-hard", at: CGPoint(x: size.width / 2, y: size.height / 2 - 94)))
        
        let note = SKLabelNode(fontNamed: "AvenirNext-Medium")
        note.text = "Hard uses best-play AI"
        note.fontSize = 15
        note.fontColor = SKColor(red: 0.29, green: 0.35, blue: 0.53, alpha: 1.0)
        note.position = CGPoint(x: size.width / 2, y: size.height / 2 - 138)
        overlay.addChild(note)
        
        addChild(overlay)
        selectionOverlay = overlay
    }
    
    private func makeSelectionButton(title: String, name: String, at point: CGPoint) -> SKNode {
        let button = SKShapeNode(rectOf: CGSize(width: min(size.width * 0.68, 320), height: 38), cornerRadius: 11)
        button.fillColor = SKColor(red: 0.2, green: 0.27, blue: 0.47, alpha: 1.0)
        button.strokeColor = SKColor(red: 0.26, green: 0.34, blue: 0.56, alpha: 1.0)
        button.lineWidth = 2
        button.position = point
        button.name = name
        
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = title
        label.fontSize = 18
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.name = name
        button.addChild(label)
        return button
    }
    
    private func selectMode(from nodeName: String) {
        switch nodeName {
        case "mode-friend":
            gameMode = .friend
            difficulty = .easy
        case "mode-cpu-easy":
            gameMode = .computer
            difficulty = .easy
        case "mode-cpu-medium":
            gameMode = .computer
            difficulty = .medium
        case "mode-cpu-hard":
            gameMode = .computer
            difficulty = .hard
        default:
            return
        }
        
        selectionOverlay?.removeFromParent()
        selectionOverlay = nil
        isSelectingMode = false
        setHUDHidden(false)
        updateModeText()
        resetGame()
    }
    
    private func setHUDHidden(_ hidden: Bool) {
        let alpha: CGFloat = hidden ? 0.0 : 1.0
        messageLabel?.alpha = alpha
        modeLabel?.alpha = alpha
        scoreLabel?.alpha = alpha
        resetScoreButton?.alpha = alpha
        modeButton?.alpha = alpha
        soundButton?.alpha = alpha
    }

    private func drawWinLine(for line: [(Int, Int)]) {
        guard
            let first = line.first,
            let last = line.last
        else { return }

        let start = centerPoint(forRow: first.0, col: first.1)
        let end = centerPoint(forRow: last.0, col: last.1)

        winLineNode?.removeFromParent()
        let path = CGMutablePath()
        path.move(to: start)
        let node = SKShapeNode(path: path)
        node.strokeColor = gameStrokeColor
        node.lineWidth = max(7, boardFrame.width * 0.025)
        node.lineCap = .round
        addChild(node)
        winLineNode = node

        animateLine(on: node, from: start, to: end, duration: 0.28)
    }

    private func createAnimatedMark(for player: Player, row: Int, col: Int) -> SKNode {
        let cellCenter = centerPoint(forRow: row, col: col)
        let cellSize = boardFrame.width / 3.0

        if player == .o {
            return makeAnimatedCircle(at: cellCenter, cellSize: cellSize, color: gameStrokeColor)
        }
        return makeAnimatedCross(at: cellCenter, cellSize: cellSize, color: gameStrokeColor)
    }

    private func makeAnimatedCircle(at center: CGPoint, cellSize: CGFloat, color: SKColor) -> SKNode {
        let container = SKNode()
        container.position = center

        let radius = cellSize * 0.27
        let circle = SKShapeNode(path: CGMutablePath())
        circle.strokeColor = color
        circle.lineWidth = max(5, cellSize * 0.06)
        circle.lineCap = .round
        circle.fillColor = .clear
        container.addChild(circle)
        addChild(container)

        animateCircle(on: circle, radius: radius, duration: 0.34)
        return container
    }

    private func makeAnimatedCross(at center: CGPoint, cellSize: CGFloat, color: SKColor) -> SKNode {
        let container = SKNode()
        container.position = center

        let delta = cellSize * 0.26
        let lineWidth = max(5, cellSize * 0.06)

        let path1 = CGMutablePath()
        path1.move(to: CGPoint(x: -delta, y: delta))
        let slash1 = SKShapeNode(path: path1)
        slash1.strokeColor = color
        slash1.lineWidth = lineWidth
        slash1.lineCap = .round
        container.addChild(slash1)

        let path2 = CGMutablePath()
        path2.move(to: CGPoint(x: -delta, y: -delta))
        let slash2 = SKShapeNode(path: path2)
        slash2.strokeColor = color
        slash2.lineWidth = lineWidth
        slash2.lineCap = .round
        container.addChild(slash2)

        addChild(container)

        let startA = CGPoint(x: -delta, y: delta)
        let endA = CGPoint(x: delta, y: -delta)
        let startB = CGPoint(x: -delta, y: -delta)
        let endB = CGPoint(x: delta, y: delta)

        animateLine(on: slash1, from: startA, to: endA, duration: 0.2)
        slash2.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.18),
            SKAction.run { [weak self, weak slash2] in
                guard let strongSelf = self, let strongSlash2 = slash2 else { return }
                strongSelf.animateLine(on: strongSlash2, from: startB, to: endB, duration: 0.2)
            }
        ]))

        return container
    }

    private func animateCircle(on node: SKShapeNode, radius: CGFloat, duration: TimeInterval) {
        let startAngle = -CGFloat.pi / 2
        node.run(SKAction.customAction(withDuration: duration) { drawable, elapsed in
            guard let shape = drawable as? SKShapeNode else { return }
            let progress = max(0, min(1, CGFloat(elapsed) / CGFloat(duration)))
            let endAngle = startAngle + (CGFloat.pi * 2 * progress)
            let path = CGMutablePath()
            path.addArc(center: .zero, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            shape.path = path
        })
    }

    private func animateLine(on node: SKShapeNode, from start: CGPoint, to end: CGPoint, duration: TimeInterval) {
        node.run(SKAction.customAction(withDuration: duration) { drawable, elapsed in
            guard let shape = drawable as? SKShapeNode else { return }
            let progress = max(0, min(1, CGFloat(elapsed) / CGFloat(duration)))
            let currentPoint = CGPoint(
                x: start.x + (end.x - start.x) * progress,
                y: start.y + (end.y - start.y) * progress
            )
            let path = CGMutablePath()
            path.move(to: start)
            path.addLine(to: currentPoint)
            shape.path = path
        })
    }

    private func playMoveFeedback(for player: Player) {
        if soundEnabled {
            run(player == .x ? xMoveSound : oMoveSound)
        }
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }

    private func playWinFeedback() {
        if soundEnabled {
            run(winSound)
        }
        successFeedback.notificationOccurred(.success)
        successFeedback.prepare()
    }
    
    private func handleComputerTurnIfNeeded() {
        guard gameMode == .computer, currentPlayer == computerPlayer, !gameEnded, !isTurnTransitioning else { return }
        isComputerThinking = true
        let requestID = UUID()
        aiRequestID = requestID
        let stateSnapshot = board
        let difficultySnapshot = difficulty

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self = self else { return }
            guard self.aiRequestID == requestID, !self.gameEnded, self.currentPlayer == self.computerPlayer else {
                self.isComputerThinking = false
                return
            }

            self.aiQueue.async { [weak self] in
                guard let self = self else { return }
                let move = self.computerMove(on: stateSnapshot, difficulty: difficultySnapshot)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    guard self.aiRequestID == requestID, !self.gameEnded, self.currentPlayer == self.computerPlayer else {
                        self.isComputerThinking = false
                        return
                    }
                    if let move = move {
                        self.placeMove(row: move.0, col: move.1)
                    }
                    self.isComputerThinking = false
                }
            }
        }
    }
    
    private func computerMove(on state: [[Player?]], difficulty: Difficulty) -> (Int, Int)? {
        switch difficulty {
        case .easy:
            return randomAvailableMove(on: state)
        case .medium:
            if let move = immediateWinningMove(for: computerPlayer, on: state) { return move }
            if let move = immediateWinningMove(for: humanPlayer, on: state) { return move }
            return randomAvailableMove(on: state)
        case .hard:
            if let move = bestMoveMinimax(for: computerPlayer, on: state) { return move }
            return randomAvailableMove(on: state)
        }
    }
    
    private func randomAvailableMove(on state: [[Player?]]) -> (Int, Int)? {
        return availableMoves(on: state).randomElement()
    }
    
    private func availableMoves(on state: [[Player?]]) -> [(Int, Int)] {
        var moves: [(Int, Int)] = []
        for row in 0..<3 {
            for col in 0..<3 where state[row][col] == nil {
                moves.append((row, col))
            }
        }
        return moves
    }
    
    private func immediateWinningMove(for player: Player, on state: [[Player?]]) -> (Int, Int)? {
        for move in availableMoves(on: state) {
            var test = state
            test[move.0][move.1] = player
            if winner(on: test) == player {
                return move
            }
        }
        return nil
    }
    
    private func winner(on state: [[Player?]]) -> Player? {
        let lines: [[(Int, Int)]] = [
            [(0, 0), (0, 1), (0, 2)],
            [(1, 0), (1, 1), (1, 2)],
            [(2, 0), (2, 1), (2, 2)],
            [(0, 0), (1, 0), (2, 0)],
            [(0, 1), (1, 1), (2, 1)],
            [(0, 2), (1, 2), (2, 2)],
            [(0, 0), (1, 1), (2, 2)],
            [(0, 2), (1, 1), (2, 0)]
        ]
        for line in lines {
            guard let first = state[line[0].0][line[0].1] else { continue }
            if state[line[1].0][line[1].1] == first && state[line[2].0][line[2].1] == first {
                return first
            }
        }
        return nil
    }
    
    private func bestMoveMinimax(for aiPlayer: Player, on state: [[Player?]]) -> (Int, Int)? {
        let candidateMoves = availableMoves(on: state)
        guard !candidateMoves.isEmpty else { return nil }
        
        var bestScore = Int.min
        var bestMove: (Int, Int)?
        for move in candidateMoves {
            var next = state
            next[move.0][move.1] = aiPlayer
            let score = minimax(on: next, current: .x, ai: aiPlayer, depth: 0)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }
    
    private func minimax(on state: [[Player?]], current: Player, ai: Player, depth: Int) -> Int {
        if let w = winner(on: state) {
            if w == ai {
                return 10 - depth
            }
            return depth - 10
        }
        if availableMoves(on: state).isEmpty {
            return 0
        }
        
        let nextPlayer: Player = current == .x ? .o : .x
        if current == ai {
            var best = Int.min
            for move in availableMoves(on: state) {
                var next = state
                next[move.0][move.1] = current
                best = max(best, minimax(on: next, current: nextPlayer, ai: ai, depth: depth + 1))
            }
            return best
        }
        
        var best = Int.max
        for move in availableMoves(on: state) {
            var next = state
            next[move.0][move.1] = current
            best = min(best, minimax(on: next, current: nextPlayer, ai: ai, depth: depth + 1))
        }
        return best
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        
        if isSelectingMode {
            let touchedNode = atPoint(point)
            if let name = touchedNode.name {
                selectMode(from: name)
            } else if let parentName = touchedNode.parent?.name {
                selectMode(from: parentName)
            }
            return
        }
        
        if gameEnded {
            resetGame()
            return
        }

        if isSoundButtonTap(at: point) {
            toggleSound()
            return
        }
        
        if isModeButtonTap(at: point) {
            presentModeSelection()
            return
        }

        if isResetScoreTap(at: point) {
            resetScores()
            return
        }
        
        if isComputerThinking {
            return
        }
        
        if isTurnTransitioning {
            return
        }
        
        if gameMode == .computer && currentPlayer != humanPlayer {
            return
        }

        guard let (row, col) = rowCol(for: point) else { return }
        placeMove(row: row, col: col)
    }

    private func isResetScoreTap(at point: CGPoint) -> Bool {
        guard let button = resetScoreButton else { return false }
        let touchedNode = atPoint(point)
        if touchedNode.name == "reset-score-button" || touchedNode.parent?.name == "reset-score-button" {
            return true
        }
        if let shape = button as? SKShapeNode {
            return shape.contains(point)
        }
        return false
    }

    private func isSoundButtonTap(at point: CGPoint) -> Bool {
        guard let button = soundButton else { return false }
        let touchedNode = atPoint(point)
        if touchedNode.name == "sound-button" || touchedNode.parent?.name == "sound-button" {
            return true
        }
        if let shape = button as? SKShapeNode {
            return shape.contains(point)
        }
        return false
    }
    
    private func isModeButtonTap(at point: CGPoint) -> Bool {
        guard let button = modeButton else { return false }
        let touchedNode = atPoint(point)
        if touchedNode.name == "mode-button" || touchedNode.parent?.name == "mode-button" {
            return true
        }
        if let shape = button as? SKShapeNode {
            return shape.contains(point)
        }
        return false
    }
}
