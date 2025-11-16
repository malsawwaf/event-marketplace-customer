import Flutter
import UIKit
import PaymobSDK

@main
@objc class AppDelegate: FlutterAppDelegate, PaymobSDKDelegate {
    var sdkResult: FlutterResult?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
        // Initialize Paymob SDK
        let paymob = PaymobSDK()
        paymob.delegate = self

        // Customize the SDK
        if let appName = arguments["appName"] as? String {
            paymob.paymobSDKCustomization.appName = appName
        }

        if let buttonBackgroundColor = arguments["buttonBackgroundColor"] as? NSNumber {
            let colorInt = buttonBackgroundColor.intValue
            let alpha = CGFloat((colorInt >> 24) & 0xFF) / 255.0
            let red = CGFloat((colorInt >> 16) & 0xFF) / 255.0
            let green = CGFloat((colorInt >> 8) & 0xFF) / 255.0
            let blue = CGFloat(colorInt & 0xFF) / 255.0

            let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            paymob.paymobSDKCustomization.buttonBackgroundColor = color
        }

        if let buttonTextColor = arguments["buttonTextColor"] as? NSNumber {
            let colorInt = buttonTextColor.intValue
            let alpha = CGFloat((colorInt >> 24) & 0xFF) / 255.0
            let red = CGFloat((colorInt >> 16) & 0xFF) / 255.0
            let green = CGFloat((colorInt >> 8) & 0xFF) / 255.0
            let blue = CGFloat(colorInt & 0xFF) / 255.0

            let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            paymob.paymobSDKCustomization.buttonTextColor = color
        }

        if let saveCardDefault = arguments["saveCardDefault"] as? Bool {
            paymob.paymobSDKCustomization.saveCardDefault = saveCardDefault
        }

        if let showSaveCard = arguments["showSaveCard"] as? Bool {
            paymob.paymobSDKCustomization.showSaveCard = showSaveCard
        }

        // Call Paymob SDK with publicKey and clientSecret
        if let publicKey = arguments["publicKey"] as? String,
           let clientSecret = arguments["clientSecret"] as? String {
            do {
                try paymob.presentPayVC(VC: VC, PublicKey: publicKey, ClientSecret: clientSecret)
            } catch let error {
                print("PaymobSDK Error: \(error.localizedDescription)")
                self.sdkResult?("Error")
                self.sdkResult = nil
            }
            return
        }

        // If keys are missing
        self.sdkResult?("Error")
        self.sdkResult = nil
    }
}

// MARK: - PaymobSDKDelegate Methods
extension AppDelegate {
    public func transactionRejected() {
        print("PaymobSDK: Transaction Rejected")
        self.sdkResult?("Rejected")
        self.sdkResult = nil
    }

    public func transactionAccepted(transactionDetails: Any?) {
        print("PaymobSDK: Transaction Successful")
        self.sdkResult?("Successfull")
        self.sdkResult = nil
    }

    public func transactionPending() {
        print("PaymobSDK: Transaction Pending")
        self.sdkResult?("Pending")
        self.sdkResult = nil
    }
}
