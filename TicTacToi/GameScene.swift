//
//  GameScene.swift
//  TicTacToi
//
//  Created by Abdullah Syed on 18.02.26.
//

import SpriteKit

final class GameScene: SKScene {

    private enum Player: String {
        case x = "X"
        case o = "O"
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
    private var scoreLabel: SKLabelNode?
    private var resetScoreButton: SKNode?
    private var winLineNode: SKShapeNode?
    private var boardFrame: CGRect = .zero
    private var xWins = 0
    private var oWins = 0
    private let xWinsKey = "score_x_wins"
    private let oWinsKey = "score_o_wins"
    private let gameStrokeColor = SKColor(red: 0.16, green: 0.21, blue: 0.38, alpha: 1.0)
    var onSceneReady: (() -> Void)?

    override func didMove(to view: SKView) {
        removeAllChildren()
        backgroundColor = SKColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1.0)
        loadScores()
        setupBoard()
        setupMessageLabel()
        setupScoreLabel()
        setupResetScoreButton()
        updateTurnText()
        updateScoreText()
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
        guard board[row][col] == nil, !gameEnded else { return }

        board[row][col] = currentPlayer
        marks[row][col] = createAnimatedMark(for: currentPlayer, row: row, col: col)
        moveHistory.append(Move(row: row, col: col, player: currentPlayer))

        if let result = winningResult() {
            gameEnded = true
            drawWinLine(for: result.line)
            if result.player == .x {
                xWins += 1
            } else {
                oWins += 1
            }
            saveScores()
            updateScoreText()
            messageLabel?.text = "\(result.player.rawValue) wins! Tap to restart"
            return
        }

        if isDraw() {
            undoLastMoveAfterDraw()
            return
        }

        currentPlayer = currentPlayer == .x ? .o : .x
        updateTurnText()
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
        messageLabel?.text = "\(currentPlayer.rawValue) turn"
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

    private func resetScores() {
        xWins = 0
        oWins = 0
        saveScores()
        updateScoreText()
    }

    private func resetGame() {
        board = Array(repeating: Array(repeating: Player?.none, count: 3), count: 3)
        moveHistory.removeAll()
        currentPlayer = .x
        gameEnded = false
        winLineNode?.removeFromParent()
        winLineNode = nil
        for row in 0..<3 {
            for col in 0..<3 {
                marks[row][col]?.removeFromParent()
                marks[row][col] = nil
            }
        }
        updateTurnText()
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }

        if isResetScoreTap(at: point) {
            resetScores()
            return
        }

        if gameEnded {
            resetGame()
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
}
