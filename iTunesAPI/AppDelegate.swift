//
//  AppDelegate.swift
//  testItunesApi
//
//  Created by Sergey Kopytov on 22.02.2018.
//  Copyright © 2018 Sergey Kopytov. All rights reserved.
//

import UIKit
import Kingfisher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //added tint color
        UINavigationBar.appearance().tintColor = UIColor.orange
        
        //configure cache settings
        ImageCache.default.maxDiskCacheSize = 52428800
        ImageCache.default.maxCachePeriodInSecond = 259200
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // clear memory cache, if app was terminated
        ImageCache.default.clearMemoryCache()
    }
}

