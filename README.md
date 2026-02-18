# TicTacToi

A SpriteKit-based iOS Tic-Tac-Toe game with animated drawing, win tracking, and a custom loading experience.

## Features

- Animated pen-style `X` and `O` drawing
- Animated win alignment line
- Draw recovery logic:
  - On draw, removes the earliest move from both players and continues
- Persistent score tracking (`X` wins and `O` wins) via `UserDefaults`
- In-game `Reset Score` button
- Animated loading screen with logo, title, and start flow
- Custom app icon and launch screen styling
- Scene lifecycle support (`UIScene` / `SceneDelegate`)

## Requirements

- Xcode 15+ (recommended)
- iOS deployment target: `15.0`

## Run

1. Open `/Users/syed/Desktop/IOS/TicTacToi/TicTacToi.xcodeproj`
2. Select the `TicTacToi` scheme
3. Choose an iPhone simulator or device
4. Build and run

## Gameplay

- Tap a board cell to place your mark
- `X` and `O` alternate turns
- On win:
  - Winner is shown
  - Win line is drawn
  - Score increments and is saved
- Tap after win to start a new round

## Score Reset

- Tap `Reset Score` in-game to clear both players’ saved win totals.

## Repository

- Remote: `git@github.com:sm-abdullah/TicTacToi.git`
