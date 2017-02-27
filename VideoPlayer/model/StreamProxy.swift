//
//  Created by Ivano Bilenchi on 18/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation
import GCDWebServers

/// HTTP namespace
struct HTTP {
    
    /// HTTP methods
    struct Method {
        static let get = "GET"
        static let post = "POST"
    }
    
    /// HTTP response codes
    struct ResponseCode {
        static let ok = 200
        static let badRequest = 400
        static let internalServerError = 500
    }
}

/// Streaming proxy, forwards local requests to the remote playlist host.
/// Allows full control of playlist and segment payloads.
class StreamProxy: GCDWebServer {
    
    // MARK: Public properties
    
    weak var policy: StreamProxyPolicy?
    
    private(set) var playlist: Playlist
    
    var remotePlaylistUrl: URL {
        return playlist.url
    }
    
    var localPlaylistUrl: URL {
        return playlist.url.proxying(toHost: serverURL)!
    }
    
    // MARK: Private properties
    
    private var playlistParsed = false
    private let remoteHostUrl: URL
    
    // MARK: Lifecycle
    
    init(remotePlaylistUrl: URL) {
        
        // Dummy playlist, will be replaced with actual playlist after the first request
        self.playlist = MediaPlaylist(url: remotePlaylistUrl)
        self.remoteHostUrl = remotePlaylistUrl.hostUrl()!
        
        super.init()
        
        // Default handler
        addDefaultHandler(forMethod: HTTP.Method.get, request: GCDWebServerRequest.self) { [unowned self] (request) -> GCDWebServerResponse? in
            guard let urlRequest = URLRequest(proxying: request, toHost: self.remoteHostUrl) else {
                return self.errorResponse(withStatusCode: HTTP.ResponseCode.badRequest)
            }
            return self.defaultResponse(forRequest: urlRequest)
        }
        
        // Playlist handler
        addHandler(forMethod: HTTP.Method.get, pathRegex: "^.*\\.m3u8$", request: GCDWebServerRequest.self) { [unowned self] (request) -> GCDWebServerResponse? in
            guard let urlRequest = URLRequest(proxying: request, toHost: self.remoteHostUrl) else {
                return self.errorResponse(withStatusCode: HTTP.ResponseCode.badRequest)
            }
            return self.playlistResponse(forRequest: urlRequest)
        }
        
        // Segment handler
        addHandler(forMethod: HTTP.Method.get, pathRegex: "^.*\\.(ts|m4s|mp4)$", request: GCDWebServerRequest.self) { [unowned self] (request) -> GCDWebServerResponse? in
            guard let urlRequest = URLRequest(proxying: request, toHost: self.remoteHostUrl) else {
                return self.errorResponse(withStatusCode: HTTP.ResponseCode.badRequest)
            }
            return self.segmentResponse(forRequest: urlRequest)
        }
    }
    
    // MARK: Proxy responses
    
    /// Default request handler, return the remote server response as-is
    private func defaultResponse(forRequest request: URLRequest) -> GCDWebServerResponse {
        return response(forRequest: request).gcdResponse
    }
    
    /// Playlist request handler
    private func playlistResponse(forRequest request: URLRequest) -> GCDWebServerResponse {
        
        let response = self.response(forRequest: request)
        
        // Parse and store the first playlist
        if !playlistParsed, let string = response.data.flatMap({ String(data: $0, encoding: .utf8) }) {
            let parser = PlaylistParser()
            parser.provider = self
            
            if let playlist = parser.parsePlaylist(withUrl: request.url!, fromString: string) {
                self.playlist = playlist
                playlistParsed = true
            }
        }
        
        return response.gcdResponse
    }
    
    /// Segment request handler
    private func segmentResponse(forRequest request: URLRequest) -> GCDWebServerResponse {
        
        var newRequest = request
        
        if let segment = playlist.segment(withUrl: request.url!),
            let newSegment = policy?.streamProxy(self, replacementForSegment: segment) {
            newRequest.url = newSegment.url
        }
        
        return response(forRequest: newRequest).gcdResponse
    }
    
    /// Returns an error response
    private func errorResponse(withStatusCode code: Int, message: String? = nil) -> GCDWebServerResponse {
        let msg = message ?? HTTPURLResponse.localizedString(forStatusCode: code)
        let errorData = msg.data(using: .utf8, allowLossyConversion: true)
        
        let response = GCDWebServerDataResponse(data: errorData, contentType: "text/plain")!
        response.statusCode = code
        return response
    }
    
    /// Forwards a request to the remote host and returns its response
    private func response(forRequest request: URLRequest) -> (gcdResponse: GCDWebServerResponse, data: Data?) {
        let output = URLSession(configuration: .default).synchronousDataTask(with: request)
        
        guard let response = output.response as? HTTPURLResponse else {
            let dataString = output.data.flatMap({ String(data: $0, encoding: .utf8) })
            let errorMsg = "Error: \(output.error?.localizedDescription)\nData: \(dataString)"
            return (errorResponse(withStatusCode: HTTP.ResponseCode.internalServerError, message: errorMsg), nil)
        }
        
        return (GCDWebServerDataResponse(with: response, data: output.data), output.data)
    }
}

extension StreamProxy: MediaPlaylistProvider {
    
    func mediaPlaylistData(at url: URL) -> String? {
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 32000)
        let output = URLSession(configuration: .default).synchronousDataTask(with: request)
        return output.data.flatMap { String(data: $0, encoding: .utf8) }
    }
}

// MARK: Private extensions

private extension URLRequest {
    
    /// Creates an URLRequest by proxying a GCDWebServerRequest to a new host
    init?(proxying request: GCDWebServerRequest?, toHost host: URL) {
        if let request = request, let newUrl = request.url.proxying(toHost: host) {
            self.init(proxying: request, to: newUrl)
        } else {
            return nil
        }
    }
    
    /// Creates an URLRequest by proxying a GCDWebServerRequest to a new URL
    init(proxying request: GCDWebServerRequest, to otherUrl: URL) {
        self.init(url: otherUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 320000)
        
        httpMethod = request.method
        allHTTPHeaderFields = request.headers as! [String : String]?
        allHTTPHeaderFields?["Host"] = otherUrl.host
        
        if request.hasBody() {
            httpBody = (request as! GCDWebServerDataRequest).data
        }
    }
}

private extension GCDWebServerDataResponse {
    
    /// Creates a GCDWebServerDataResponse from an HTTPURLResponse
    convenience init(with response: HTTPURLResponse, data: Data?) {
        let contentType = response.allHeaderFields["Content-Type"] as? String ?? "application/x-unknown"
        self.init(data: data ?? Data(), contentType: contentType)
        statusCode = response.statusCode
        
        for (key, value) in response.allHeaderFields {
            guard let key = key as? String, let value = value as? String else { continue }
            setValue(value, forAdditionalHeader: key)
        }
        
        setValue(nil, forAdditionalHeader: "Content-Encoding")
    }
}
