import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }
    GeneratedPluginRegistrant.register(with: self)
    setUpBadgeChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 앱 아이콘 배지 카운트 설정. flutter_local_notifications는 화면에 알림을
  // 띄우지 않고 배지 숫자만 조용히 갱신하는 API가 없어(호출하면 알림이 실제로
  // 전달됨) UIApplication API를 직접 호출하는 네이티브 채널을 둔다.
  private func setUpBadgeChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "com.dobino.feple/badge",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setBadgeCount",
            let args = call.arguments as? [String: Any],
            let count = args["count"] as? Int
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIApplication.shared.applicationIconBadgeNumber = count
      result(nil)
    }
  }
}
