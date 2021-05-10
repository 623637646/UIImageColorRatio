//
//  AppDelegate.swift
//  UIImageColorRatioExample
//
//  Created by Yanni Wang on 10/5/21.
//

import UIKit
import ZLPhotoBrowser

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ZLPhotoConfiguration.default().allowTakePhoto = false
        ZLPhotoConfiguration.default().maxSelectCount = 1
        ZLPhotoConfiguration.default().allowEditImage = false
        ZLPhotoConfiguration.default().allowSelectOriginal = false
        ZLPhotoConfiguration.default().allowTakePhotoInLibrary = false
        ZLPhotoConfiguration.default().allowSelectVideo = false
        
        self.window = UIWindow.init(frame: UIScreen.main.bounds)
        self.window?.rootViewController = ViewController.init()
        self.window?.makeKeyAndVisible()
        
        return true
    }


}

