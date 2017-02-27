//
//  Created by Ivano Bilenchi on 25/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

/// HLS namespace
fileprivate struct HLS {
    
    /// HLS tags
    fileprivate struct Tag {
        static let head = "#EXTM3U"
        static let mediaInitialization = "#EXT-X-MAP"
        static let mediaSegment = "#EXTINF"
        static let mediaSegmentSequence = "#EXT-X-MEDIA-SEQUENCE"
        static let variantStream = "#EXT-X-STREAM-INF"
        static let iFrameStream = "#EXT-X-I-FRAME-STREAM-INF"
        
        /// HLS tag parser handler
        typealias Handler = (_ contents: String?, _ attributes: Attributes) -> ()
    }
    
    /// Models attributes of HLS tags
    fileprivate struct Attributes {
        let named: [String: String]
        let anonymous: [String]
        
        static func empty() -> Attributes {
            return Attributes(named: [String: String](), anonymous: [String]())
        }
    }
}

/// The playlist parser may need to retrieve and parse
/// additional playlists referenced in master files.
protocol MediaPlaylistProvider: class {
    func mediaPlaylistData(at url: URL) -> String?
}

/// Parser for HLS playlists
class PlaylistParser {
    
    // MARK: Public properties
    
    weak var provider: MediaPlaylistProvider?
    
    // MARK: Private properties
    
    private var dir: URL!
    private var sequence: UInt = 0
    private var segments = [UInt: Segment]()
    private var mediaPlaylists = [URL: MediaPlaylist]()
    
    private let quotes = CharacterSet(charactersIn: "\"")
    
    // MARK: Handlers
    
    private lazy var mediaInitializationHandler: HLS.Tag.Handler = { [unowned self] (contents, attributes) in
        guard let url = attributes.named["URI"].flatMap({ self.absoluteUrl(from: $0) }) else {
                return
        }
        
        self.segments[0] = Segment(url: url, sequence: 0, duration: 0.0)
    }
    
    private lazy var mediaSegmentHandler: HLS.Tag.Handler = { [unowned self] (contents, attributes) in
        guard let url = contents.flatMap({ self.absoluteUrl(from: $0) }),
            let durationAttr = attributes.anonymous.first, let duration = Float(durationAttr) else {
                return
        }
        
        let sequence = self.sequence
        self.segments[sequence] = Segment(url: url, sequence: sequence, duration: duration)
        self.sequence += 1
    }
    
    private lazy var mediaSegmentSequenceHandler: HLS.Tag.Handler = { [unowned self] (contents, attributes) in
        guard let sequenceAttr = attributes.anonymous.first, let sequence = UInt(sequenceAttr) else {
                return
        }
        
        self.sequence = sequence
    }
    
    private lazy var variantStreamHandler: HLS.Tag.Handler = { [unowned self] (contents, attributes) in
        guard let url = contents.flatMap({ self.absoluteUrl(from: $0) }) else {
            return
        }
        
        self.parseMediaPlaylist(at: url, withAttributes: attributes)
    }
    
    private lazy var iFrameStreamHandler: HLS.Tag.Handler = { [unowned self] (contents, attributes) in
        guard let url = attributes.named["URI"].flatMap({ self.absoluteUrl(from: $0) }) else {
            return
        }
        
        self.parseMediaPlaylist(at: url, withAttributes: attributes)
    }
    
    private lazy var handlers: [String: HLS.Tag.Handler] = [HLS.Tag.mediaInitialization: self.mediaInitializationHandler,
                                                            HLS.Tag.mediaSegment: self.mediaSegmentHandler,
                                                            HLS.Tag.mediaSegmentSequence: self.mediaSegmentSequenceHandler,
                                                            HLS.Tag.variantStream: self.variantStreamHandler,
                                                            HLS.Tag.iFrameStream: self.iFrameStreamHandler]
    
    // MARK: Public methods
    
    func parsePlaylist(withUrl url: URL, fromString string: String) -> Playlist? {
        cleanup()
        
        let absoluteUrl = url.absoluteURL
        self.dir = absoluteUrl.deletingLastPathComponent()
        
        guard string.hasPrefix(HLS.Tag.head) else {
            return nil
        }
        
        var playlistLines = string.components(separatedBy: .newlines)
        
        for (idx, line) in playlistLines.enumerated() where line.hasPrefix("#") {
            let components = line.characters.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
            let count = components.count
            
            guard count > 0 else { continue }
            
            // Get tag
            let tag = String(components[0])
            
            // Eventually parse attributes
            let attributes = count > 1 ? parseAttributes(fromString: String(components[1])) : HLS.Attributes.empty()
            
            // Attempt to get next contents line
            var contents: String?
            var lookAhead = idx+1
            
            while lookAhead < playlistLines.count && contents == nil {
                let nextLine = playlistLines[lookAhead]
                
                if !nextLine.hasPrefix("#") {
                    contents = nextLine
                }
                
                lookAhead += 1
            }
            
            // Invoke actual tag parsing handler
            handlers[tag]?(contents, attributes)
        }
        
        // Create playlist object based on parsed data
        var playlist: Playlist
        
        if mediaPlaylists.isEmpty {
            let mediaPlaylist = MediaPlaylist(url: absoluteUrl)
            mediaPlaylist.addSegments(self.segments.values)
            
            playlist = mediaPlaylist
        } else {
            playlist = MasterPlaylist(url: absoluteUrl, mediaPlaylists: mediaPlaylists)
        }
        
        return playlist
    }
    
    // MARK: Private methods
    
    private func absoluteUrl(from string: String) -> URL? {
        var url: URL?
        
        if string.hasPrefix("http://") || string.hasPrefix("https://") {
            url = URL(string: string)
        } else {
            url = URL(string: string, relativeTo: self.dir)?.absoluteURL
        }
        
        return url
    }
    
    private func parseMediaPlaylist(at url: URL, withAttributes attributes: HLS.Attributes) {
        guard self.mediaPlaylists[url] == nil, let string = self.provider?.mediaPlaylistData(at: url) else {
            return
        }
        
        // Parse media playlists referenced in the master file
        let parser = PlaylistParser()
        parser.provider = self.provider
        
        if let mediaPlaylist = parser.parsePlaylist(withUrl: url, fromString: string) as? MediaPlaylist {
            mediaPlaylist.resolution = attributes.named["RESOLUTION"].flatMap { self.parseResolution(fromString: $0) }
            self.mediaPlaylists[url] = mediaPlaylist
        }
    }
    
    private func parseAttributes(fromString string: String) -> HLS.Attributes {
        guard string.characters.count > 0 else { return HLS.Attributes.empty() }
        
        var namedAttrs = [String: String]()
        var anonAttrs = [String]()
        
        for attrString in string.components(separatedBy: ",") {
            let components = attrString.components(separatedBy: "=")
            let count = components.count
            
            if count == 2 {
                namedAttrs[components[0]] = components[1].trimmingCharacters(in: quotes)
            } else if count == 1 {
                anonAttrs.append(components[0])
            }
        }
        
        return HLS.Attributes(named: namedAttrs, anonymous: anonAttrs)
    }
    
    private func parseResolution(fromString string: String) -> Resolution? {
        let components = string.components(separatedBy: "x")
        if components.count == 2, let width = UInt(components[0]), let height = UInt(components[1]) {
            return Resolution(width: width, height: height)
        } else {
            return nil
        }
    }
    
    private func cleanup() {
        dir = nil
        sequence = 0
        segments.removeAll()
        mediaPlaylists.removeAll()
    }
}
