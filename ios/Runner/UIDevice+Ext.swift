//
//  UIDevice+Ext.swift
//  Runner
//
//  Created by Hemming on 2025/7/29.
//

import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

extension UIDevice {
    
    /// 获取设备标识符（IDFA）
    static func getDeviceIdentifier(completion: @escaping (String) -> Void) {
        if #available(iOS 14.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                if status == .authorized {
                    completion(UIDevice.getAdvertisingId())
                } else {
                    completion("")
                }
            }
        } else {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                completion(UIDevice.getAdvertisingId())
            } else {
                completion("")
            }
        }
    }
    
    /// 获取广告标识符
    static func getAdvertisingId() -> String {
        let adIdentifier = ASIdentifierManager.shared().advertisingIdentifier
        return adIdentifier.uuidString
    }
    
    /// 获取设备类型
    static func getDeviceType() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = machineMirror
            .children.reduce("") { identifier, element in
                guard let value = element.value as? Int8,
                      value != 0 else {
                    return identifier
                }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
        return identifier
    }
}


