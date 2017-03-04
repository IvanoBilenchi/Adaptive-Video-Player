//
//  Created by Ivano Bilenchi on 25/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

/// Playlists can be either master or media
enum PlaylistType {
    case master, media
}

/// Models master playlists
final class MasterPlaylist: Playlist {
    
    // MARK: Public properties
    
    let url: URL
    var type: PlaylistType { return .master }
    let mediaPlaylists: [URL: MediaPlaylist]
    
    // MARK: Lifecycle
    
    init(url: URL, mediaPlaylists: [URL: MediaPlaylist]) {
        self.url = url
        self.mediaPlaylists = mediaPlaylists
    }
    
    // MARK: Public methods
    
    func segment(withUrl url: URL) -> Segment? {
        var segment: Segment?
        
        for playlist in mediaPlaylists.values {
            segment = playlist.segment(withUrl: url)
            
            if segment != nil {
                break
            }
        }
        
        return segment
    }
}

/// Models media playlists
final class MediaPlaylist: Playlist {
    
    // MARK: Public properties
    
    let url: URL
    var type: PlaylistType { return .media }
    
    var resolution: Resolution?
    
    // MARK: Private properties
    
    private var segmentsByUrl = [URL: Segment]()
    private var segmentsBySequence = [UInt: Segment]()
    
    // MARK: Lifecycle
    
    init(url: URL, resolution: Resolution? = nil) {
        self.url = url
        self.resolution = resolution
    }
    
    // MARK: Public methods
    
    func segment(withUrl url: URL) -> Segment? {
        return segmentsByUrl[url]
    }
    
    func segment(withSequence sequence: UInt) -> Segment? {
        return segmentsBySequence[sequence]
    }
    
    func addSegment(_ segment: Segment) {
        segmentsByUrl[segment.url] = segment
        segmentsBySequence[segment.sequence] = segment
    }
    
    func addSegments<T: Sequence>(_ segments: T) where T.Iterator.Element == Segment {
        for segment in segments {
            addSegment(segment)
        }
    }
}

/// Models HLS playlists
protocol Playlist {
    var url: URL { get }
    var type: PlaylistType { get }
    
    func segment(withUrl url: URL) -> Segment?
}

/// Models video resolutions
struct Resolution {
    
    static let zero = Resolution(width: 0, height: 0)
    
    let width: UInt
    let height: UInt
}

extension Resolution: CustomStringConvertible {
    
    var description: String {
        return "\(width)x\(height)"
    }
}

extension Resolution: Comparable {
    
    static func == (lhs: Resolution, rhs: Resolution) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height
    }
    
    static func < (lhs: Resolution, rhs: Resolution) -> Bool {
        return (lhs.width + lhs.height) < (rhs.width + rhs.height)
    }
}
