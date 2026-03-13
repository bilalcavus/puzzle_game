import Flutter
import UIKit
import AppTrackingTransparency

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let trackingChannel = FlutterMethodChannel(
        name: "app.tracking/att",
        binaryMessenger: controller.binaryMessenger
      )

      trackingChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "trackingAuthorizationStatus":
          if #available(iOS 14, *) {
            result(Int(ATTrackingManager.trackingAuthorizationStatus.rawValue))
          } else {
            result(-1)
          }
        case "requestTrackingAuthorization":
          if #available(iOS 14, *) {
            DispatchQueue.main.async {
              ATTrackingManager.requestTrackingAuthorization { status in
                result(Int(status.rawValue))
              }
            }
          } else {
            result(-1)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
