//
//  GameScene.swift
//  ZombieConga
//
//  Created by xulingjiao on 2019/3/25.
//  Copyright © 2019 Sprite. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    let zombie = SKSpriteNode(imageNamed: "zombie1");
    
    var guardZombie = false;
    
    var lastUpdateTime: TimeInterval = 0;
    var dt: TimeInterval = 0;
    
    let zombieMovePointsPerSec:CGFloat = 480.0;
    
    let catMovePointsPerSec:CGFloat = 480.0
    
    var velocity = CGPoint.zero;
    
    let playableRect:CGRect
    
    var lastTouchLocation: CGPoint = CGPoint.zero
    
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π
    
    let zombieAnimation: SKAction
    
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    
    var lives = 5
    
    var gameOver = false
    
    let cameraMovePointsPerSec: CGFloat = 200.0
    
    override init(size: CGSize) {
        let maxAspectRadio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRadio
        let playableMargin = (size.height - playableHeight) / 2.0
        playableRect = CGRect(x: 0, y: playableMargin, width: size.width, height: playableHeight)
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        super.init(size: size);
    }
    
    // 计算当前的“可见游戏区域”
    var cameraRect : CGRect {
        return CGRect(
            x: getCameraPosition().x - size.width / 2 + (size.width - playableRect.width) / 2,
            y: getCameraPosition().y  - size.height / 2 + (size.height - playableRect.height) / 2,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    func startZombieAnimaltion() {
        if zombie.action(forKey: "animation") == nil {
            zombie.run(SKAction.repeatForever(zombieAnimation), withKey: "animation")
        }
    }
    
    func stopZombileAnimation() {
        zombie.removeAction(forKey: "animation")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func debugDrawPlayableArea() {
        let shape:SKShapeNode = SKShapeNode()
        let path:CGMutablePath = CGMutablePath();
        path.addRect(playableRect);
        shape.path = path;
        shape.strokeColor = SKColor.red;
        shape.lineWidth = 4.0;
        addChild(shape);
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black;
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            addChild(background);
        }
        
        zombie.position = CGPoint(x:  400, y: 400)
        zombie.zPosition = 100
        addChild(zombie);
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnEnemy),SKAction.wait(forDuration: 3.0)])))
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(spawnCat),SKAction.wait(forDuration: 1.0)])))
        
        //debugDrawPlayableArea();
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        
        let cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        //camera?.position = CGPoint(x: size.width/2, y: size.height/2)
        setCameraPostion(position: CGPoint(x: size.width/2, y: size.height/2))
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (lastUpdateTime > 0) {
            dt = currentTime - lastUpdateTime;
        }
        else {
            dt = 0;
        }
        lastUpdateTime = currentTime;
        print("\(dt * 1000) milliseconds since last update");
        guard needStopSprite(sprite: zombie) else {
            stopZombileAnimation()
            boundsCheckZombie()
            loseGame()
            return;
        }
        moveSprite(sprite: zombie, velocity: velocity);
        boundsCheckZombie()
        rotateSprite(sprite: zombie,
                     direction: velocity,
                     rotateRadiansPerSec: zombieRotateRadiansPerSec);
        moveTrain()
        moveCamera()
        loseGame()
        //camera?.position = zombie.position
    }
    
    func loseGame() {
        if lives <= 0 && !gameOver {
            gameOver = true
            showGameOverScene(won: false);
            backgroundMusicPlayer.stop()
        }
    }
    
    func winGame(trainCount: NSInteger){
        if trainCount >= 15 && !gameOver {
            gameOver = true
            showGameOverScene(won: true);
            backgroundMusicPlayer.stop()
        }
    }
    
    func showGameOverScene(won:Bool) {
        let gameOverScene = GameOverScene(size: size, won: won)
        gameOverScene.scaleMode = scaleMode
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        view?.presentScene(gameOverScene, transition: reveal)
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func needStopSprite(sprite: SKSpriteNode) -> Bool {
        let dis = lastTouchLocation - sprite.position;
        if dis.length() <= CGFloat(CGFloat(zombieMovePointsPerSec) * CGFloat(dt)) {
            return false;
        }
        return true;
    }
    
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt);
        sprite.position += amountToMove;
    }
    
    func moveZombieToward(location:CGPoint) {
        startZombieAnimaltion()
        let offset: CGPoint = location - zombie.position;
        let direction: CGPoint = offset / CGFloat(offset.length());
        velocity = direction * zombieMovePointsPerSec;
    }
    
    func sceneTouched(touchLocation:CGPoint) {
        moveZombieToward(location: touchLocation);
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch:UITouch = touches.first else {
            return;
        }
        lastTouchLocation = touch.location(in: self);
        boundsPoint(point: &lastTouchLocation)
        sceneTouched(touchLocation: lastTouchLocation );
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch:UITouch = touches.first else {
            return;
        }
        lastTouchLocation = touch.location(in: self);
        boundsPoint(point: &lastTouchLocation)
        sceneTouched(touchLocation: lastTouchLocation);
    }
    
    func boundsCheckZombie() {
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY);
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY);
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x;
            velocity.x = -velocity.x;
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x;
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y;
            velocity.y = -velocity.y;
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y;
            velocity.y = -velocity.y;
        }
    }
    
    func boundsPoint(point: inout CGPoint) {
        let bottomLeft = CGPoint(x: 0, y: cameraRect.minY);
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY);
        if point.x <= bottomLeft.x {
            point.x = bottomLeft.x;
        }
        if point.y <= bottomLeft.y {
            point.y = bottomLeft.y;
        }
        if point.x >= topRight.x {
            point.x = topRight.x;
        }
        if point.y >= topRight.y {
            point.y = topRight.y;
        }
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec:CGFloat) {
        sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        var amountToRotate = rotateRadiansPerSec * CGFloat(dt)
        amountToRotate = min(amountToRotate, abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy");
        enemy.position = CGPoint(x: cameraRect.maxX + enemy.size.width / 2, y: CGFloat.random(
            min: cameraRect.minY + enemy.size.height / 2,
            max: cameraRect.maxY - enemy.size.height / 2))
        enemy.zPosition = 50
        enemy.name = "enemy"
        addChild(enemy);
        let actionMove = SKAction.moveBy(x: -cameraRect.size.width-enemy.size.width/2, y: 0, duration: 3)
            //SKAction.move(to: CGPoint(x: -enemy.size.width/2+cameraRect.minX, y: enemy.position.y), duration: 4.0);
        let actionRemove = SKAction.removeFromParent()
        enemy.run(SKAction.sequence([actionMove, actionRemove]));
    }
    
    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.position = CGPoint(x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX), y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        cat.setScale(0)
        cat.name = "cat"
        cat.zPosition = 50
        addChild(cat)
        let appear = SKAction.scale(to: 1, duration: 0.5)
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversed()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        let disapppear = SKAction.scale(to: 0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disapppear, removeFromParent]
        cat.run(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        //cat.removeFromParent()
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        cat.run(SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 2.0))
        run(catCollisionSound)
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        enemy.removeFromParent()
        run(enemyCollisionSound)
        loseCats()
        lives -= 1
        guardZombie = true
        blindZombie(blinkTimes: 10, duration: 3.0)
    }
    
    func blindSpriteForever(sprite: SKSpriteNode, blinkTimes: TimeInterval, duration: TimeInterval) {
        // "Blink" action
        sprite.run(SKAction.repeatForever(
            SKAction.customAction(withDuration: duration) { node, elapsedTime in
                let slice = duration / blinkTimes
                let remainder = elapsedTime.truncatingRemainder(dividingBy: CGFloat(slice))
                node.isHidden = remainder > CGFloat(slice / 2)
            }
        ))
    }
    
    func blindZombie(blinkTimes: Int, duration: TimeInterval) {
        let repeatTimes = SKAction.repeat(SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / TimeInterval(blinkTimes)
            let remainder = elapsedTime.truncatingRemainder(dividingBy: CGFloat(slice))
            node.isHidden = remainder > CGFloat(slice / 2)
        }, count: 1);
        let blockAction = SKAction.run {
            self.zombie.isHidden = false
            self.guardZombie = false
        }
        zombie.run(SKAction.sequence([repeatTimes, blockAction]))
    }
    
    func checkCollisions() {
        
        var hitCats: [SKSpriteNode] = []
        enumerateChildNodes(withName: "cat") { node, _ in
            let cat = node as! SKSpriteNode
            if cat.frame.intersects(self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        
        for cat in hitCats {
            zombieHitCat(cat: cat)
        }
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node,_ in
            let enemy = node as! SKSpriteNode
            if enemy.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        if (!guardZombie) {
            for enemy in hitEnemies {
                zombieHitEnemy(enemy: enemy)
            }
        }
        else {
            //todo
        }
    }
    
    func moveTrain() {
        var trainCount = 0
        var targetPosition = zombie.position
        enumerateChildNodes(withName: "train") { (node, _) in
            trainCount += 1
            if !node.hasActions() {
                let actionDuration = 0.3
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * self.catMovePointsPerSec
                let amoutToMove = amountToMovePerSec * CGFloat(actionDuration);
                let moveAction = SKAction.moveBy(x: amoutToMove.x, y: amoutToMove.y, duration: actionDuration)
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        winGame(trainCount: trainCount)
    }
    
    func loseCats() {
        var loseCount = 0
        enumerateChildNodes(withName: "train") { (node, stop) in
            var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -100, max: 100)
            randomSpot.y += CGFloat.random(min: -100, max: 100)
            node.name = ""
            let groupAction = SKAction.group([SKAction.rotate(byAngle: π*4, duration: 1.0), SKAction.move(to: randomSpot, duration: 1.0), SKAction.scale(to: 0, duration: 1.0)])
            let sequenceAction = SKAction.sequence([groupAction, SKAction.removeFromParent()])
            node.run(sequenceAction)
            loseCount += 1
            if loseCount >= 2 {
                stop.initialize(to: true)
            }
        }
    }
    
    func overlapAmount() -> CGFloat {
        guard let view = self.view else {
            return 0
        }
        let scale = view.bounds.size.width/self.size.width
        let scaleHeight = self.size.height * scale
        let scaleOverlap = scaleHeight - view.bounds.size.height
        return scaleOverlap / scale
    }
    
    func getCameraPosition() -> CGPoint {
        return CGPoint(x: camera?.position.x ?? 0, y: camera?.position.y ?? 0 + overlapAmount()/2)
    }
    
    func setCameraPostion(position: CGPoint) {
        camera?.position = CGPoint(x: position.x, y:position.y - overlapAmount()/2)
    }
    
    func backgroundNode() -> SKSpriteNode {
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPoint.zero
        backgroundNode.name = "background"
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPoint.zero
        background1.position = CGPoint.zero
        backgroundNode.addChild(background1)
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPoint.zero
        background2.position = CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        backgroundNode.size = CGSize(width: background1.size.width+background2.size.width, height: background1.size.height)
        return backgroundNode
    }
    
    func moveCamera() {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        camera?.position += amountToMove
        if camera?.position.x ?? 0 > zombie.position.x && lastTouchLocation.length() == 0 {
            zombie.position.x = cameraRect.minX + 400;
        }
        enumerateChildNodes(withName: "background") { node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width < self.cameraRect.origin.x {
                background.position = CGPoint(x: background.position.x + background.size.width * 2, y: background.position.y)
            }
        }
    }
}
