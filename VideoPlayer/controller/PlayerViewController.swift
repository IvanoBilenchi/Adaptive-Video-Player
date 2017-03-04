//
//  Created by Ivano Bilenchi on 04/03/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import AVKit

extension AVPlayerViewController: StreamProxyDelegate {
    
    // MARK: Public properties
    
    var selectionControl: ResolutionSelectionControl? {
        get { return navigationItem.titleView as? ResolutionSelectionControl }
        set { navigationItem.titleView = newValue }
    }
    
    // MARK: StreamProxyDelegate
    
    func streamProxy(_ proxy: StreamProxy, didReceiveMainPlaylist playlist: Playlist) {
        guard let playlist = playlist as? MasterPlaylist else { return }
        let resolutions = Array<Resolution>(playlist.mediaPlaylists.values.flatMap({ $0.resolution })).sorted()
        
        if !resolutions.isEmpty {
            proxy.policy = FixedQualityPolicy(quality: .withResolution(resolutions[0]))
            
            let control = ResolutionSelectionControl(frame: .zero)
            control.resolutions = resolutions
            
            control.resolutionTapHandler = { (res) in
                proxy.policy = FixedQualityPolicy(quality: .withResolution(res))
            }
            
            selectionControl = control
        }
    }
}
