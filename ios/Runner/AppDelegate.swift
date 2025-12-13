import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key: 네이티브 파일이므로 환경 변수 사용 불가. 필요시 Info.plist나 빌드 설정으로 주입 필요
    GMSServices.provideAPIKey("AIzaSyADP6VfQKeMMJP1aDPpJAPBTczfFp5cMTc")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
