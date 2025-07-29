import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册自定义keychain插件
    let controller = window?.rootViewController as! FlutterViewController
    let keychainChannel = FlutterMethodChannel(name: "keychain_service", binaryMessenger: controller.binaryMessenger)
    keychainChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleKeychainMethod(call: call, result: result)
    }
    
    // 注册Photos权限插件
    let photosChannel = FlutterMethodChannel(name: "photos_permission", binaryMessenger: controller.binaryMessenger)
    photosChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handlePhotosPermissionMethod(call: call, result: result)
    }
    
    // 注册IDFA插件
    let idfaChannel = FlutterMethodChannel(name: "idfa_service", binaryMessenger: controller.binaryMessenger)
    idfaChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleIDFAMethod(call: call, result: result)
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func handleKeychainMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
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
  
  // MARK: - Photos Permission Methods
  
  private func handlePhotosPermissionMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestPhotosAddPermission":
      requestPhotosAddPermission(result: result)
    case "checkPhotosAddPermission":
      checkPhotosAddPermission(result: result)
    case "openAppSettings":
      openAppSettings(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func requestPhotosAddPermission(result: @escaping FlutterResult) {
    let status: PHAuthorizationStatus
    
    // iOS 14+ 支持 .addOnly 权限
    if #available(iOS 14, *) {
      status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    } else {
      // iOS 13 使用传统权限
      status = PHPhotoLibrary.authorizationStatus()
    }
    
    if status == .notDetermined {
      if #available(iOS 14, *) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { authorizationStatus in
          DispatchQueue.main.async {
            result(self.authorizationStatusToString(authorizationStatus))
          }
        }
      } else {
        PHPhotoLibrary.requestAuthorization { authorizationStatus in
          DispatchQueue.main.async {
            result(self.authorizationStatusToString(authorizationStatus))
          }
        }
      }
    } else {
      result(authorizationStatusToString(status))
    }
  }
  
  private func checkPhotosAddPermission(result: @escaping FlutterResult) {
    let status: PHAuthorizationStatus
    
    // iOS 14+ 支持 .addOnly 权限
    if #available(iOS 14, *) {
      status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    } else {
      // iOS 13 使用传统权限
      status = PHPhotoLibrary.authorizationStatus()
    }
    
    result(authorizationStatusToString(status))
  }
  
  private func openAppSettings(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        if UIApplication.shared.canOpenURL(settingsUrl) {
          UIApplication.shared.open(settingsUrl) { success in
            result(success)
          }
        } else {
          result(false)
        }
      } else {
        result(false)
      }
    }
  }
  
  private func authorizationStatusToString(_ status: PHAuthorizationStatus) -> String {
    switch status {
    case .authorized:
      return "authorized"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "notDetermined"
    default:
      // iOS 14+ 才有 .limited 状态
      if #available(iOS 14, *) {
        if status == .limited {
          return "limited"
        }
      }
      return "unknown"
    }
  }
  
  // MARK: - IDFA Methods
  
  private func handleIDFAMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDeviceIdentifier":
      UIDevice.getDeviceIdentifier { idfa in
        result(idfa)
      }
      
    case "getAdvertisingId":
      let idfa = UIDevice.getAdvertisingId()
      result(idfa)
      
    case "getDeviceType":
      let deviceType = UIDevice.getDeviceType()
      result(deviceType)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
