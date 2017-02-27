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
        let proxy = StreamProxy(remotePlaylistUrl: AppConfig.playlistUrl)
        proxy.policy = self.policy
        return proxy
    }()
    
    lazy var policy: StreamProxyPolicy = FixedQualityPolicy(quality: .max)
    
    // MARK: Controller
    
    lazy var rootViewController: UIViewController = {
        let controller = AVPlayerViewController()
        
        if let url = self.proxy.localPlaylistUrl {
            controller.player = AVPlayer(url: url)
        }
        
        return controller
    }()
}
