//
//  Created by Ivano Bilenchi on 18/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class AppFactory {
    
    // MARK: Model
    
    lazy var proxy: StreamProxy = {
        return StreamProxy(remotePlaylist: AppConfig.playlistUrl)
    }()
    
    // MARK: Controller
    
    lazy var rootViewController: UIViewController = {
        let controller = AVPlayerViewController()
        
        if let playlistUrl = self.proxy.localPlaylist {
            let player = AVPlayer(url: playlistUrl)
            controller.player = player
        }
        
        return controller
    }()
}
