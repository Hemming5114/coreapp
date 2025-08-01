import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var photosChannel: FlutterMethodChannel?
  private var keychainChannel: FlutterMethodChannel?
  private var purchaseChannel: FlutterMethodChannel?
  private var idfaChannel: FlutterMethodChannel?
  private let purchaseManager = FlutterPurchaseManager.shared
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Keychain service channel
    keychainChannel = FlutterMethodChannel(name: "keychain_service", binaryMessenger: controller.binaryMessenger)
    keychainChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleKeychainMethodCall(call: call, result: result)
    }
    
    // Photos permission channel
    photosChannel = FlutterMethodChannel(name: "photos_permission", binaryMessenger: controller.binaryMessenger)
    photosChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handlePhotosMethodCall(call: call, result: result)
    }
    
    // Native Purchase channel
    purchaseChannel = FlutterMethodChannel(name: "native_purchase_channel", binaryMessenger: controller.binaryMessenger)
    purchaseChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handlePurchaseMethodCall(call: call, result: result)
    }
    
    // IDFA service channel
    idfaChannel = FlutterMethodChannel(name: "idfa_service", binaryMessenger: controller.binaryMessenger)
    idfaChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleIDFAMethodCall(call: call, result: result)
    }
    
    // Set purchase manager delegate
    purchaseManager.delegate = self
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Keychain methods
  private func handleKeychainMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "saveToKeychain":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String,
            let value = args["value"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let success = saveToKeychain(key: key, value: value)
      result(success)
      
    case "getFromKeychain":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let value = getFromKeychain(key: key)
      result(value)
      
    case "deleteFromKeychain":
      guard let args = call.arguments as? [String: Any],
            let key = args["key"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      
      let success = deleteFromKeychain(key: key)
      result(success)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func saveToKeychain(key: String, value: String) -> Bool {
    let data = value.data(using: .utf8)!
    
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecValueData as String: data,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    ]
    
    // 先删除已存在的项
    SecItemDelete(query as CFDictionary)
    
    // 添加新项
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }
  
  private func getFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    
    guard status == errSecSuccess,
          let data = result as? Data,
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    
    return string
  }
  
  private func deleteFromKeychain(key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key
    ]
    
    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }

  // Photos permission methods
  private func handlePhotosMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPhotosAddPermission":
      requestPhotosAddPermission(result: result)
    case "checkPhotosAddPermission":
      checkPhotosAddPermission(result: result)
    case "getPhotosPermissionStatus":
      getPhotosPermissionStatus(result: result)
    case "openAppSettings":
      openAppSettings(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func requestPhotosAddPermission(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized, .limited:
            result("authorized")
          case .denied:
            result("denied")
          case .restricted:
            result("restricted")
          case .notDetermined:
            result("notDetermined")
          @unknown default:
            result("unknown")
          }
        }
      }
    } else {
      PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
          switch status {
          case .authorized:
            result("authorized")
          case .denied:
            result("denied")
          case .restricted:
            result("restricted")
          case .notDetermined:
            result("notDetermined")
          @unknown default:
            result("unknown")
          }
        }
      }
    }
  }
  
  private func checkPhotosAddPermission(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized, .limited:
        result(true)
      default:
        result(false)
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      result(status == .authorized)
    }
  }
  
  private func getPhotosPermissionStatus(result: @escaping FlutterResult) {
    if #available(iOS 14, *) {
      let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      switch status {
      case .authorized:
        result("authorized")
      case .limited:
        result("limited")
      case .denied:
        result("denied")
      case .restricted:
        result("restricted")
      case .notDetermined:
        result("notDetermined")
      @unknown default:
        result("unknown")
      }
    } else {
      let status = PHPhotoLibrary.authorizationStatus()
      switch status {
      case .authorized:
        result("authorized")
      case .denied:
        result("denied")
      case .restricted:
        result("restricted")
      case .notDetermined:
        result("notDetermined")
      @unknown default:
        result("unknown")
      }
    }
  }
  
  private func openAppSettings(result: @escaping FlutterResult) {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
      result(false)
      return
    }
    
    if UIApplication.shared.canOpenURL(settingsUrl) {
      UIApplication.shared.open(settingsUrl) { success in
        result(success)
      }
    } else {
      result(false)
    }
  }
  
  // MARK: - IDFA Methods
  private func handleIDFAMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceIdentifier":
      UIDevice.getDeviceIdentifier { idfa in
        result(idfa)
      }
    case "getAdvertisingId":
      let advertisingId = UIDevice.getAdvertisingId()
      result(advertisingId)
    case "getDeviceType":
      let deviceType = UIDevice.getDeviceType()
      result(deviceType)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Purchase Methods
  private func handlePurchaseMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "canMakePayments":
      let canMake = purchaseManager.canMakePayments()
      result(canMake)
      
    case "requestProductInfo":
      guard let args = call.arguments as? [String: Any],
            let productIds = args["productIds"] as? [String] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for requestProductInfo", details: nil))
        return
      }
      
      // 目前只处理第一个产品ID，后续可以扩展支持批量
      if let firstProductId = productIds.first {
        purchaseManager.requestProductInformation(productId: firstProductId) { success, errorMessage in
          if success {
            result([["productId": firstProductId, "success": true]])
          } else {
            result(FlutterError(code: "PRODUCT_INFO_FAILED", message: errorMessage ?? "Failed to get product info", details: nil))
          }
        }
      } else {
        result([])
      }
      
    case "purchaseProduct":
      guard let args = call.arguments as? [String: Any],
            let productId = args["productId"] as? String,
            let isConsumable = args["isConsumable"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for purchaseProduct", details: nil))
        return
      }
      
      purchaseManager.startPurchaseFlow(productId: productId, isConsumable: isConsumable) { success, errorMessage in
        if success {
          result(true)
        } else {
          result(FlutterError(code: "PURCHASE_FAILED", message: errorMessage ?? "Purchase failed", details: nil))
        }
      }
      
    case "finishTransaction":
      guard let args = call.arguments as? [String: Any],
            let transactionId = args["transactionId"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for finishTransaction", details: nil))
        return
      }
      
      purchaseManager.finishTransactionWithId(transactionId)
      result(true)
      
    case "restorePurchases":
      purchaseManager.restoreCompletedTransactions()
      result(true)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - PurchaseManagerDelegate
extension AppDelegate: PurchaseManagerDelegate {
  
  func onProductsReceived(_ products: [[String: Any]]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onProductsReceived", arguments: products)
    }
  }
  
  func onPurchaseUpdated(_ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onPurchaseUpdated", arguments: data)
    }
  }
  
  func onPurchaseCompleted(_ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onPurchaseCompleted", arguments: data)
    }
  }
  
  func onPurchaseFailed(_ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onPurchaseFailed", arguments: data)
    }
  }
  
  func onPurchaseRestored(_ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onPurchaseRestored", arguments: data)
    }
  }
  
  func onPurchaseDeferred(_ data: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.purchaseChannel?.invokeMethod("onPurchaseDeferred", arguments: data)
    }
  }
}
