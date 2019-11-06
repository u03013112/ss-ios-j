//
//  UUID.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/21.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation
import KeychainAccess

public func getUUID()->String{
    let keychain = Keychain(service: "U0.SS.UUID")
    let uuid = try? keychain.get("U0.SS.UUID.token")
    if let uuid = uuid{
        return uuid
    }else{
        let str = UUID().uuidString
        do {
            try keychain.set(str, key: "U0.SS.UUID.token")
        } catch let error {
            print(error)
        }
        return str
    }
}
