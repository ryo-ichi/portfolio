//
//  AppDelegate.swift
//  Rainy Day APP
//
//  Created by 松原涼一 on 2023/06/30.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging

var refToken: String? // クラス外に宣言 グローバル変数にして他ファイル他クラスから参照可能する

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()

        // クラスAppDelegateはUNUserNotificationCenterDelegateプロトコルに実装内容を委譲されている
        UNUserNotificationCenter.current().delegate = self

        // クラスAppDelegateはMessagingDelegateプロトコルに実装内容を委譲されている
        Messaging.messaging().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        application.registerForRemoteNotifications() //リモート登録

        Thread.sleep(forTimeInterval: 1.0) // 1秒間スリープ
        return true
    }

    //有効なFCMトークンの提供
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }

    // リモート登録が成功後に実行 デバイストークン取得 成功時にマッピング処理
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        Messaging.messaging().apnsToken = deviceToken // 登録成功時にマッピング処理(APNsトークンを設定)

        Messaging.messaging().token { token, error in // FCMトークン取得とアプリ情報をサーバーへ送信
            if let error = error { // トークン取得失敗
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token { // トークン取得成功
                print("FCM registration token: \(token)")

                //正常にトークン取得できた場合はサーバーへ保存　カスタムメソッドを作ってサーバーにdeviceTokenを送信
                ref.child("allDevices/\(token)")
                refToken = token
//                print("testTokenの値は\(refToken)")
            }
        }
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}

// UNUserNotificationCenterDelegate プロトコルを適用して通知を受信するための extension
extension AppDelegate: UNUserNotificationCenterDelegate {
    // アプリがフォアグラウンドで通知を受信したときの処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 通知 表示設定
        completionHandler([.banner, .sound])
    }

    // アプリがバックグラウンドまたは閉じている状態で通知を受信したときの処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 通知を受信したときの処理（ユーザーが通知をタップした際にバッジをクリア）
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }
}
// Firebase Messagingからのメッセージを受信するためのextension
extension AppDelegate: MessagingDelegate {
}
