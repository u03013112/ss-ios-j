//
//  SimpleManager.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/9.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation
import NetworkExtension

public let kLoginSuccess = "kProxyServiceVPNStatusNotification"
public let kVPNStatusNotification = "kVPNStatusNotification"

private let kToken = "kToken"
private let kUsername = "kUsername"
private let kIsPacMod = "kIsPacMod"

open class SimpleManager {
    public static let sharedManager = SimpleManager()
    
    fileprivate init() {
        token = UserDefaults.standard.string(forKey: kToken) ?? ""
        username = UserDefaults.standard.string(forKey: kUsername) ?? ""
        isPACMod = UserDefaults.standard.bool(forKey: kIsPacMod) 
    }
    
    public var token = "" {
        didSet {
            if (oldValue != token){
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: kLoginSuccess), object: nil)
                UserDefaults.standard.set(token,forKey: kToken)
                
                let tokenDict = ["token":token]
                
                do {
                    let tokenJson = try JSONSerialization.data(withJSONObject: tokenDict, options: .prettyPrinted)
                    let tokenConf = String(data:tokenJson,encoding: .utf8) ?? ""
                    let m = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.U0.ss")
                    let tokenUrl = m?.appendingPathComponent("token.conf") ?? URL(fileURLWithPath: "")
                    try tokenConf.write(to: tokenUrl, atomically: true, encoding: String.Encoding.utf8)
                }catch{
                    print(error)
                }
            }
        }
    }
    public var username = "" {
        didSet {
            if (oldValue != username){
                UserDefaults.standard.set(username,forKey: kUsername)
            }
        }
    }
    
    public var isPACMod = false {
        didSet {
            if (oldValue != isPACMod){
                UserDefaults.standard.set(isPACMod,forKey: kIsPacMod)
            }
        }
    }
    
//    record for record
    public var IP = ""
    public var port = 0
    public var method = ""
    public var passwd = ""
    
    public var expireDate = Double(0) {
        didSet {
            if (oldValue != expireDate){
                NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: kExDateChanged), object: nil)
            }
        }
    }
 
    
    public func timeIntervalChangeToTimeStr(timeInterval:Double, _ dateFormat:String? = "yyyy-MM-dd HH:mm:ss") -> String {
        let date:NSDate = NSDate.init(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter.init()
        if dateFormat == nil {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        }else{
            formatter.dateFormat = dateFormat
        }
        return formatter.string(from: date as Date)
    }
    
    public func startVPN(completion:((Error?)->Void)?) {
        ProviderManager.sharedManager.getProviderManager { (manager, error) in
            if let error = error {
                print(error)
                completion?(error)
                return
            }else{
                guard let manager = manager else {
                    print("manager is nil")
                    completion?(NSError(domain: "manager is nil", code: -1, userInfo: nil))
                    return
                }
                if manager.connection.status == .disconnected || manager.connection.status == .invalid {
                    do {
                        try manager.connection.startVPNTunnel(options: nil)
                    }catch {
                        print(error)
                        completion?(error)
                        return
                    }
                    completion?(nil)
                }
            }
        }
    }
    
    public func stopVPN() {
        ProviderManager.sharedManager.getProviderManager { (manager, error) -> Void in
            if let error = error {
                print(error)
                return
            }else{
                guard let manager = manager else {
                    print("manager is nil")
                    return
                }
                if manager.connection.status == .connected {
                    manager.connection.stopVPNTunnel()
                }
            }
        }
    }
}
