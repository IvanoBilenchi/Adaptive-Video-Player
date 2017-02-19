//
//  Created by Ivano Bilenchi on 18/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation
import GCDWebServers

class StreamProxy: GCDWebServer {
    
    // MARK: Public properties
    
    let remotePlaylist: URL
    
    var localPlaylist: URL? {
        guard let serverURL = serverURL else { return nil }
        return URL.byProxying(remotePlaylist, to: serverURL)
    }
    
    // MARK: Lifecycle
    
    init(remotePlaylist: URL) {
        self.remotePlaylist = remotePlaylist
        super.init()
        
        addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { (req) -> GCDWebServerResponse? in
            return self.sendProxyResult(forRequest: req)
        }
    }
    
    func sendProxyResult(forRequest req: GCDWebServerRequest?) -> GCDWebServerResponse {
        guard let req = req, let proxyRequest = URLRequest(proxying: req, to: remotePlaylist) else {
            return sendError("Invalid request")
        }
        
        let output = URLSession(configuration: .default).synchronousDataTask(with: proxyRequest)
        
        if output.response == nil {
            let dataString = output.data.flatMap({ String(data: $0, encoding: .utf8) })
            let error = "Error: \(output.error?.localizedDescription)\nData: \(dataString)"
            return sendError(error)
        }
        
        return GCDWebServerDataResponse(with: (output.response as! HTTPURLResponse), data: output.data)
    }
    
    func sendError(_ error: String? = nil) -> GCDWebServerResponse {
        let msg = error ?? "An error occured"
        let errorData = msg.data(using: .utf8, allowLossyConversion: true)
        
        let resp = GCDWebServerDataResponse(data: errorData, contentType: "text/plain")!
        resp.statusCode = 500
        return resp
    }
}

// MARK: Private extensions

private extension URL {
    
    static func byProxying(_ url: URL, to host: URL) -> URL? {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.scheme = host.scheme
        components?.host = host.host
        components?.port = host.port
        
        return components?.url
    }
}

private extension URLRequest {
    
    init?(proxying request: GCDWebServerRequest, to remoteHost: URL) {
        guard let newUrl = URL.byProxying(request.url, to: remoteHost) else { return nil }
        
        self.init(url: newUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 320000)
        
        httpMethod = request.method
        allHTTPHeaderFields = request.headers as! [String : String]?
        allHTTPHeaderFields?["Host"] = remoteHost.host
        
        if request.hasBody() {
            httpBody = (request as! GCDWebServerDataRequest).data
        }
    }
}

private extension GCDWebServerDataResponse {
    
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
