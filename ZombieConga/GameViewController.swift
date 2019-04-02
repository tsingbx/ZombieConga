//
//  GameViewController.swift
//  ZombieConga
//
//  Created by xulingjiao on 2019/3/25.
//  Copyright © 2019 Sprite. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let scene = MainMenuScene(size:CGSize(width: 2048, height: 1536));
        scene.scaleMode = .aspectFill
        let skView = self.view as! SKView;
        skView.showsFPS = true;
        skView.showsNodeCount = true;
        skView.ignoresSiblingOrder = true;
        skView.presentScene(scene);
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
