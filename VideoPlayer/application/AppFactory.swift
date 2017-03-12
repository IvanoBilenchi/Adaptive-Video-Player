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
        return StreamProxy(remotePlaylistUrl: AppConfig.playlistUrl)
    }()
    
    // MARK: Controller
    
    lazy var rootViewController: UIViewController = {
        let navController = UINavigationController(rootViewController: self.playerViewController)
        navController.navigationBar.barStyle = .black
        return navController
    }()
    
    lazy var playerViewController: AVPlayerViewController = {
        let controller = AVPlayerViewController()
        controller.edgesForExtendedLayout = .init(rawValue: 0)
        
        if let url = self.proxy.localPlaylistUrl {
            let player = AVPlayer(url: url)
            player.currentItem?.preferredForwardBufferDuration = 1.0
            
            controller.player = player
            self.proxy.proxyDelegate = controller
        }
        
        return controller
    }()
}
