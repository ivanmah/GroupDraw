//
//  AppDelegate.swift
//  GroupDraw
//
//  Created by Ivan Mah on 10/6/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)

        if let window = window {
            let navigationController = UINavigationController()
            navigationController.viewControllers = [ViewController()]

            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }

        return true
    }
}

