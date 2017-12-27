//
//  Scene.swift
//  Que hay de nuevo
//
//  Created by David Garcia on 12/26/17.
//  Copyright © 2017 David Garcia. All rights reserved.
//

import SpriteKit
import ARKit

class Scene: SKScene {
    
    override func didMove(to view: SKView) {
        // Setup your scene here
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let hit = nodes(at: location)
        hit.first?.removeFromParent()
    }
}
