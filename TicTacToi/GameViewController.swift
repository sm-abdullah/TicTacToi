//
//  GameViewController.swift
//  TicTacToi
//
//  Created by Abdullah Syed on 18.02.26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private var loadingOverlay: UIView?
    private var loadingSubtitleLabel: UILabel?
    private var startButton: UIButton?
    private var sceneIsReady = false
    private var minLoadingTimePassed = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1)

        guard let skView = self.view as? SKView else { return }

        skView.backgroundColor = view.backgroundColor ?? .black
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        presentLoadingScreen()
        presentGameScene(on: skView)
    }

    private func presentGameScene(on skView: SKView) {
        let scene = GameScene(size: skView.bounds.size)
        scene.onSceneReady = { [weak self] in
            self?.sceneDidBecomeReady()
        }
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    private func presentLoadingScreen() {
        let overlay = UIView(frame: view.bounds)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.isOpaque = true

        let gradient = CAGradientLayer()
        gradient.frame = overlay.bounds
        gradient.colors = [
            UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1).cgColor,
            UIColor(red: 0.15, green: 0.21, blue: 0.41, alpha: 1).cgColor,
            UIColor(red: 0.26, green: 0.33, blue: 0.58, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        overlay.layer.addSublayer(gradient)

        let glow = UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 220))
        glow.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY - 40)
        glow.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        glow.backgroundColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.28)
        glow.layer.cornerRadius = 110
        overlay.addSubview(glow)

        let iconView = UIImageView(image: UIImage(systemName: "pencil.and.scribble"))
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.tintColor = UIColor(white: 1, alpha: 0.95)
        iconView.contentMode = .scaleAspectFit
        overlay.addSubview(iconView)

        let title = UILabel()
        title.text = "TicTacToi"
        title.font = UIFont(name: "AvenirNext-Heavy", size: 52) ?? UIFont.boldSystemFont(ofSize: 52)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false
        title.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
        title.alpha = 0
        overlay.addSubview(title)

        let subtitle = UILabel()
        subtitle.text = "Loading board..."
        subtitle.font = UIFont(name: "AvenirNext-DemiBold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        subtitle.textColor = UIColor(white: 0.9, alpha: 0.95)
        subtitle.textAlignment = .center
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.alpha = 0
        overlay.addSubview(subtitle)
        loadingSubtitleLabel = subtitle

        let button = UIButton(type: .system)
        button.setTitle("Start Game", for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 20) ?? UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1)
        button.backgroundColor = UIColor(white: 1, alpha: 0.95)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 22, bottom: 10, right: 22)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0
        button.isEnabled = false
        button.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        overlay.addSubview(button)
        startButton = button

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            iconView.bottomAnchor.constraint(equalTo: title.topAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
            title.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -20),
            subtitle.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            button.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            button.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 20)
        ])

        view.addSubview(overlay)
        loadingOverlay = overlay

        UIView.animate(withDuration: 0.55, delay: 0, options: [.curveEaseOut], animations: {
            title.alpha = 1
            subtitle.alpha = 1
            title.transform = .identity
        })

        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 0.95
        pulse.toValue = 1.07
        pulse.duration = 1.05
        pulse.autoreverses = true
        pulse.repeatCount = .greatestFiniteMagnitude
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        glow.layer.add(pulse, forKey: "glowPulse")

        let shimmer = CABasicAnimation(keyPath: "opacity")
        shimmer.fromValue = 0.75
        shimmer.toValue = 1
        shimmer.duration = 0.8
        shimmer.autoreverses = true
        shimmer.repeatCount = .greatestFiniteMagnitude
        title.layer.add(shimmer, forKey: "titleShimmer")

        let bob = CABasicAnimation(keyPath: "transform.translation.y")
        bob.fromValue = -4
        bob.toValue = 4
        bob.duration = 0.9
        bob.autoreverses = true
        bob.repeatCount = .greatestFiniteMagnitude
        bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconView.layer.add(bob, forKey: "iconBob")

        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        rotate.fromValue = -0.06
        rotate.toValue = 0.06
        rotate.duration = 1.2
        rotate.autoreverses = true
        rotate.repeatCount = .greatestFiniteMagnitude
        rotate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconView.layer.add(rotate, forKey: "iconTilt")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.minLoadingTimePassed = true
            self?.tryDismissLoadingScreen()
        }
    }

    private func dismissLoadingScreen() {
        guard let overlay = loadingOverlay else { return }
        loadingOverlay = nil
        loadingSubtitleLabel = nil
        startButton = nil
        UIView.animate(withDuration: 0.35, delay: 0, options: [.curveEaseIn], animations: {
            overlay.alpha = 0
        }, completion: { _ in
            overlay.removeFromSuperview()
        })
    }

    private func sceneDidBecomeReady() {
        sceneIsReady = true
        loadingSubtitleLabel?.text = "Ready. Tap Start or wait..."
        startButton?.isEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.startButton?.alpha = 1
        }
        tryDismissLoadingScreen()
    }

    private func tryDismissLoadingScreen() {
        guard sceneIsReady, minLoadingTimePassed else { return }
        dismissLoadingScreen()
    }

    @objc
    private func startButtonTapped() {
        guard sceneIsReady else { return }
        minLoadingTimePassed = true
        dismissLoadingScreen()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
