//
//  Created by Ivano Bilenchi on 27/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

extension URL {
    
    /// Creates a new URL by changing the host of an existing URL
    func proxying(toHost host: URL) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: true)
        
        components?.scheme = host.scheme
        components?.host = host.host
        components?.port = host.port
        
        return components?.url
    }
    
    /// Creates a new URL by getting the scheme and host of the current URL
    func hostUrl() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        
        return components.url
    }
}
