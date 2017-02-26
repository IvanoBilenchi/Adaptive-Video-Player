//
//  Created by Ivano Bilenchi on 25/02/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

/// Models HLS segments.
class Segment {
    
    // MARK: Public properties
    
    let url: URL
    let sequence: UInt
    let duration: Float
    
    // MARK: Lifecycle
    
    init(url: URL, sequence: UInt, duration: Float) {
        self.url = url
        self.sequence = sequence
        self.duration = duration
    }
}
