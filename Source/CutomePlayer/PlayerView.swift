//
//  PlayerView.swift
//  edX
//
//  Created by Salman on 09/04/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import AVKit

class PlayerView: UIView {
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
