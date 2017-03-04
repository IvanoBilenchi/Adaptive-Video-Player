//
//  Created by Ivano Bilenchi on 04/03/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import Foundation

final class Mutex {
    
    // MARK: Private properties
    
    private var mutex = pthread_mutex_t()
    
    // MARK: Lifecycle
    
    init() {
        pthread_mutex_init(&mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    // MARK: Lock
    
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    func withCriticalScope<T>(_ criticalScope: () -> T) -> T {
        lock()
        defer { unlock() }
        return criticalScope()
    }
}
