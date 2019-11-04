//
//  ProviderManager.swift
//  KeXueShangWang
//
//  Created by 宋志京 on 2019/11/1.
//  Copyright © 2019 宋志京. All rights reserved.
//

import Foundation
import NetworkExtension

open class ProviderManager {
    let description = "科学就是力量"
    public static let sharedManager = ProviderManager()
    func getProviderManager(_ complete: @escaping (NETunnelProviderManager?, Error?) -> Void ) {
        NETunnelProviderManager.loadAllFromPreferences { [unowned self] (managers, error) -> Void in
            if let managers = managers {
                var manager:NETunnelProviderManager
                if managers.count > 0 {
                    manager = managers[0]
                    complete(manager,nil)
                }else{
                    manager = NETunnelProviderManager()
                    manager.protocolConfiguration = NETunnelProviderProtocol()
                    manager.isEnabled = true
                    manager.localizedDescription = self.description
                    manager.protocolConfiguration?.serverAddress = self.description
                    manager.isOnDemandEnabled = true
                    manager.saveToPreferences(completionHandler: { (error) -> Void in
                        if let error = error {
                            complete(nil, error)
                        }else{
                            manager.loadFromPreferences(completionHandler: { (error) -> Void in
                                if let error = error {
                                    complete(nil, error)
                                }else{
                                    complete(manager, nil)
                                }
                            })
                        }
                    })
                }
            }else{
                complete(nil, error)
            }
        }
    }
}
