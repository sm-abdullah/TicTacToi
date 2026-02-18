//
//  SceneDelegate.swift
//  TicTacToi
//
//  Created by Codex on 18.02.26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if window == nil {
            let window = UIWindow(windowScene: windowScene)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            window.rootViewController = storyboard.instantiateInitialViewController()
            self.window = window
        }
        window?.windowScene = windowScene
        window?.makeKeyAndVisible()
    }
}
