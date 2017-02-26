//
//  Created by Ivano Bilenchi on 26/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

/// Segment replacement policies
protocol StreamProxyPolicy: class {
    func streamProxy(_ proxy: StreamProxy, replacementForSegment segment: Segment) -> Segment
}

/// This policy always returns segments of a fixed quality
class FixedQualityPolicy: StreamProxyPolicy {
    
    enum Quality {
        case min, mid, max
    }
    
    // MARK: Public properties
    
    let quality: Quality
    
    // MARK: Private properties
    
    private let qualityComparator: (MediaPlaylist, MediaPlaylist) -> Bool = { (p1, p2) in
        if let res1 = p1.resolution, let res2 = p2.resolution {
            return res1 < res2
        } else {
            return false
        }
    }
    
    // MARK: Lifecycle
    
    init(quality: Quality) {
        self.quality = quality
    }
    
    // MARK: StreamProxyPolicy
    
    func streamProxy(_ proxy: StreamProxy, replacementForSegment segment: Segment) -> Segment {
        
        var newSegment: Segment?
        
        if let playlist = proxy.playlist as? MasterPlaylist {
            
            var mediaPlaylist: MediaPlaylist?
            
            switch quality {
            case .min:
                mediaPlaylist = playlist.mediaPlaylists.min(by: qualityComparator)
            case .max:
                mediaPlaylist = playlist.mediaPlaylists.max(by: qualityComparator)
            case .mid:
                if !playlist.mediaPlaylists.isEmpty {
                    let playlists = playlist.mediaPlaylists.sorted(by: qualityComparator)
                    let midIdx = Int(ceil(Double(playlists.count) / 2.0))
                    mediaPlaylist = playlists[midIdx]
                }
            }
            
            newSegment = mediaPlaylist?.segment(withSequence: segment.sequence)
        }
        
        return newSegment ?? segment
    }
}
