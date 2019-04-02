//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by xulingjiao on 2019/4/1.
//  Copyright © 2019 Sprite. All rights reserved.
//

import Foundation

import SpriteKit

class MainMenuScene: SKScene {
    
    override init(size: CGSize) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: size.width/2.0, y: size.height/2.0)
        addChild(background)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        let reveal = SKTransition.doorsOpenHorizontal(withDuration: 1.5)
        self.view?.presentScene(gameScene, transition: reveal)
    }
}
