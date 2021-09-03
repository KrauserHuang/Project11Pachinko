//
//  GameScene.swift
//  Project11Pachinko
//
//  Created by Tai Chin Huang on 2021/9/3.
//

import SpriteKit

class GameScene: SKScene {
    
    var balls = ["ballBlue", "ballCyan", "ballGreen", "ballGrey", "ballPurple", "ballRed", "ballYellow"]
    
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var editLabel: SKLabelNode!
    var editingMode: Bool = false {
        didSet {
            if editingMode {
                editLabel.text = "Done"
            } else {
                editLabel.text = "Edit"
            }
        }
    }
    
    var lifeLabel: SKLabelNode!
    var life = 5 {
        didSet {
            lifeLabel.text = "Life: \(life)"
        }
    }
    
    override func didMove(to view: SKView) {
        // 增加實體在整個畫面上，就像一個框將所有東西包起來
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.contactDelegate = self
        // SKSpriteNode等於UIKit的UIImage，可載入圖片
        let background = SKSpriteNode(imageNamed: "background")
        // 根據GameScene.sks anchor X/Y的相對位置來給定座標
        background.position = CGPoint(x: 512, y: 384)
        // .replace代表不做任何修改，直接採用圖片
        background.blendMode = .replace
        // z軸放到-1讓其他物件在背景之前
        background.zPosition = -1
        // like addSubView
        addChild(background)
        
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.position = CGPoint(x: 980, y: 700)
        addChild(scoreLabel)
        
        editLabel = SKLabelNode(fontNamed: "Chalkduster")
        editLabel.text = "Edit"
        editLabel.position = CGPoint(x: 80, y: 700)
        addChild(editLabel)
        
        lifeLabel = SKLabelNode(fontNamed: "Chalkduster")
        lifeLabel.text = "Life: 5"
        lifeLabel.horizontalAlignmentMode = .center
        lifeLabel.position = CGPoint(x: 450, y: 700)
        addChild(lifeLabel)
        
        makeSlot(at: CGPoint(x: 128, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 384, y: 0), isGood: false)
        makeSlot(at: CGPoint(x: 640, y: 0), isGood: true)
        makeSlot(at: CGPoint(x: 896, y: 0), isGood: false)
        
        makeBouncer(at: CGPoint(x: 0, y: 0))
        makeBouncer(at: CGPoint(x: 256, y: 0))
        makeBouncer(at: CGPoint(x: 512, y: 0))
        makeBouncer(at: CGPoint(x: 768, y: 0))
        makeBouncer(at: CGPoint(x: 1024, y: 0))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 只記錄第一下點擊的數據
        guard let touch = touches.first else { return }
        // 回傳點選位置的座標
        let location = touch.location(in: self)
        
        let object = nodes(at: location)
        if object.contains(editLabel) {
            editingMode.toggle()
        } else {
            if editingMode {
                let size = CGSize(width: Int.random(in: 16...128), height: 16)
                let box = SKSpriteNode(color: UIColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: 1), size: size)
                box.name = "box"
                box.zRotation = CGFloat.random(in: 0...3)
                box.physicsBody = SKPhysicsBody(rectangleOf: box.size)
                box.physicsBody?.isDynamic = false
                box.position = location
                addChild(box)
            } else {
                guard life > 0 else { return }
                life -= 1
                let ball = SKSpriteNode(imageNamed: balls.randomElement()!)
                ball.name = "ball"
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ball.size.width / 2)
                // 將所有ball所碰撞物體的資訊都告訴我
                ball.physicsBody?.contactTestBitMask = ball.physicsBody!.collisionBitMask
                // 設定彈跳係數
                ball.physicsBody?.restitution = 0.4
                ball.position.x = location.x
                ball.position.y = (view?.frame.height)!
//                ball.position = location
                addChild(ball)
            }
        }
    }
    
    func makeBouncer(at position: CGPoint) {
        let bouncer = SKSpriteNode(imageNamed: "bouncer")
        bouncer.position = position
        bouncer.physicsBody = SKPhysicsBody(circleOfRadius: bouncer.size.width / 2.0)
        // 有動態效果(物體碰撞他會彈開)，false -> 並不會因為受物體碰撞而被移動
        bouncer.physicsBody?.isDynamic = false
        addChild(bouncer)
    }
    
    func makeSlot(at position: CGPoint, isGood: Bool) {
        var slotBase: SKSpriteNode
        var slotGlow: SKSpriteNode
        
        if isGood {
            slotBase = SKSpriteNode(imageNamed: "slotBaseGood")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowGood")
            slotBase.name = "good"
        } else {
            slotBase = SKSpriteNode(imageNamed: "slotBaseBad")
            slotGlow = SKSpriteNode(imageNamed: "slotGlowBad")
            slotBase.name = "bad"
        }
        
        slotBase.position = position
        slotGlow.position = position
        // 在base建立一個矩形實體，並且不能被移動
        slotBase.physicsBody = SKPhysicsBody(rectangleOf: slotBase.size)
        slotBase.physicsBody?.isDynamic = false
        
        addChild(slotBase)
        addChild(slotGlow)
        
        let spin = SKAction.rotate(byAngle: .pi, duration: 10)
        let spinForever = SKAction.repeatForever(spin)
        slotGlow.run(spinForever)
    }
}
//MARK: - 建立實體物體碰撞代理
extension GameScene: SKPhysicsContactDelegate {
    // 當球與其他物體碰撞，主要拿來偵測他是碰撞到good/bad slotBase
    func collisionBetween(ball: SKNode, object: SKNode) {
        if object.name == "good" {
            destroy(ball: ball)
            score += 1
            life += 1
        } else if object.name == "bad" {
            destroy(ball: ball)
            score -= 1
        } else if object.name == "box" {
            score += 1
            object.removeFromParent()
        }
    }
    // 將球從遊戲中移除
    func destroy(ball: SKNode) {
        if let fireParticles = SKEmitterNode(fileNamed: "FireParticles") {
            fireParticles.position = ball.position
            addChild(fireParticles)
        }
        ball.removeFromParent()
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA.name == "ball" {
            collisionBetween(ball: nodeA, object: nodeB)
        } else if nodeB.name == "ball" {
            collisionBetween(ball: nodeB, object: nodeA)
        }
    }
}
