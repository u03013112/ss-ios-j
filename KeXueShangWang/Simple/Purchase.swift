//
//  Purchase.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/20.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation
import SwiftyStoreKit

class PurchaseJ : NSObject {
    static public func validateByServer(completion:((String?,Error?) -> Void)? = nil) -> Void {
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let receiptData):
                let encryptedReceipt = receiptData.base64EncodedString(options: [])
//                print("Fetch receipt success:\n\(encryptedReceipt)")
                
                let dict = ["token":SimpleManager.sharedManager.token,"data":encryptedReceipt]
                let completion4Post = {
                    (result:[String: Any]?, error:Error?) -> Void in
                    if let result = result {
                        if (result["error"] as? String != nil) {
                            print(result["error"] as! String)
                            completion?(result["error"] as? String,nil)
                            return
                        }
                        if result["expiresDate"] as? String != nil{
                            let exStr = result["expiresDate"] as! String
                            let ex = Double(exStr)
                            SimpleManager.sharedManager.expireDate = ex ?? 0
                            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: kExDateChanged), object: nil)
                        }
                        completion?(nil,nil)
                        return
                    } else if let error = error {
                        print("error: \(error.localizedDescription)")
                        completion?("",error)
                        return
                    }
                }
                HTTP.shared.postRequest(urlStr: "https://frp.u03013112.win:18022/v1/ios/purchase", data: dict, completion: completion4Post)
            case .error(let error):
                print("Fetch receipt failed: \(error)")
                completion?("",error)
            }
        }
    }
}



