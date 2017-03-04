//
//  Created by Ivano Bilenchi on 04/03/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import UIKit

class ResolutionSelectionControl: UISegmentedControl {
    
    // MARK: Public properties
    
    var resolutions: [Resolution] = [.zero] {
        didSet {
            guard !resolutions.isEmpty else { fatalError("Resolutions array cannot be empty.") }
            
            removeAllSegments()
            for resolution in resolutions {
                insertSegment(withTitle: resolution.description, at: numberOfSegments, animated: false)
            }
            
            selectedSegmentIndex = 0
            sizeToFit()
        }
    }
    
    var selectedResolution: Resolution {
        get { return resolutions[selectedSegmentIndex] }
        set { selectedSegmentIndex = resolutions.index(of: newValue)! }
    }
    
    var resolutionTapHandler: ((_ newResolution: Resolution) -> Void)?
    
    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        defer { resolutions = [.zero] }
        addTarget(self, action: #selector(changedResolution), for: .valueChanged)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Private methods
    
    @objc private func changedResolution() {
        resolutionTapHandler?(selectedResolution)
    }
}
