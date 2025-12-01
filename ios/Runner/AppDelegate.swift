import Flutter
import UIKit
import GoogleMaps
// import PaymobSDK  // Temporarily disabled - TODO: Update to latest SDK

@main
@objc class AppDelegate: FlutterAppDelegate { // PaymobSDKDelegate temporarily removed
    var sdkResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyBmgoMQ8JDBPhHBjDwrPw01Z9vKpP-ueS4")
        GeneratedPluginRegistrant.register(with: self)

        // Set up Flutter Method Channel for Paymob SDK
        let controller = window?.rootViewController as! FlutterViewController
        let nativeChannel = FlutterMethodChannel(
            name: "paymob_sdk_flutter",
            binaryMessenger: controller.binaryMessenger
        )

        nativeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "payWithPaymob",
               let args = call.arguments as? [String: Any] {
                self.sdkResult = result
                self.callNativeSDK(arguments: args, VC: controller)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Function to call native PaymobSDK
    private func callNativeSDK(arguments: [String: Any], VC: FlutterViewController) {
        // Paymob SDK temporarily disabled - TODO: Re-enable after protocol update
        print("PaymobSDK: Currently disabled - payment functionality unavailable")
        self.sdkResult?("Error")
        self.sdkResult = nil
    }
}

// MARK: - PaymobSDKDelegate Methods (Temporarily Disabled)
// TODO: Re-enable and update delegate methods when Paymob SDK is re-integrated
/*
extension AppDelegate {
    @objc public func transactionRejected() {
        print("PaymobSDK: Transaction Rejected")
        self.sdkResult?("Rejected")
        self.sdkResult = nil
    }

    @objc public func transactionAccepted(transactionDetails: Any?) {
        print("PaymobSDK: Transaction Successful")
        self.sdkResult?("Successfull")
        self.sdkResult = nil
    }

    @objc public func transactionPending() {
        print("PaymobSDK: Transaction Pending")
        self.sdkResult?("Pending")
        self.sdkResult = nil
    }

    @objc public func userDidCancel() {
        print("PaymobSDK: User Cancelled")
        self.sdkResult?("Cancelled")
        self.sdkResult = nil
    }
}
*/
