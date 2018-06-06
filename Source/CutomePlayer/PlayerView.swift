//
//  PlayerView.swift
//  edX
//
//  Created by Salman on 09/04/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import AVKit

//Apple recommends a convenient way of using AVPlayerLayer in iOS as the backing layer for a UIView, in this way we can update playerLayer constraints
class PlayerView: UIView {
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
