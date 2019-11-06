//
//  ViewController.swift
//  KeXueShangWang
//
//  Created by 宋志京 on 2019/11/1.
//  Copyright © 2019 宋志京. All rights reserved.
//

import UIKit

import SwiftyStoreKit

let appKey = "02188998de7d4b21830f46fa3440b143"

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    let completion = {
                        (str:String?,err:Error?) -> Void in
                        if let str = str {
                            print(str)
                            return
                        }
                        if let err = err {
                            print(err)
                            return
                        }
                        print("Purchase Success: \(purchase.productId)")
                    }
                    PurchaseJ.validateByServer(completion:completion)
                    if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
        
        let vc = SimpleVC()
        self.view.addSubview(vc.view)
        self.addChild(vc)
    }
}

