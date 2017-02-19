//
//  Created by Ivano Bilenchi on 24/01/17.
//  Copyright © 2017 Ivano Bilenchi. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Private properties
    
    let factory = AppFactory()
    
    // MARK: UIApplicationDelegate

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        factory.proxy.start(withPort: AppConfig.serverPort, bonjourName: nil)
        
        window.rootViewController = factory.rootViewController
        window.makeKeyAndVisible()
        
        self.window = window
        
        return true
    }
}
