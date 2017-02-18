//
//  Created by Ivano Bilenchi on 18/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class AppFactory {
    
    // MARK: Controller
    
    lazy var rootViewController: UIViewController = {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!)
        controller.player = player
        return controller
    }()
}
