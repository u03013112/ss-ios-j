//
//  PurchaseVC.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/22.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Eureka
import Foundation
import SwiftyStoreKit

class PurchaseVC: FormViewController {
    var isShowing:String?
    var block:UIAlertController?
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "充值"
        NotificationCenter.default.addObserver(self, selector: #selector(updateExDate), name: NSNotification.Name(rawValue: kExDateChanged), object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateForm()
    }
    func generateForm() {
        form.delegate = nil
        form.removeAll()
        form +++ generateStatus()
        form +++ generatePurchase()
        form +++ generateRestore()
        form.delegate = self
        tableView.reloadData()
    }
    func generateStatus() -> Section {
        let section = Section("")
        section
            <<< LabelRow(kFromVIPExpire) {
                $0.title = "VIP 有效期："
                $0.value = "-"
                if SimpleManager.sharedManager.expireDate > 0 {
                    $0.value = SimpleManager.sharedManager.timeIntervalChangeToTimeStr(timeInterval: SimpleManager.sharedManager.expireDate)
                }
            }.onCellSelection({(cell, row) -> () in
                cell.setSelected(false, animated: true)
            })
        return section
    }
    func generateRestore() -> Section {
        let section = Section("")
        <<< ActionRow() {
            $0.title = "重购"
            }.onCellSelection({(cell, row) -> () in
                cell.setSelected(false, animated: true)
                SwiftyStoreKit.restorePurchases(atomically: false) { results in
                    if results.restoreFailedPurchases.count > 0 {
                        print("Restore Failed: \(results.restoreFailedPurchases)")
                    }
                    else if results.restoredPurchases.count > 0 {
                        for purchase in results.restoredPurchases {
                            if purchase.needsFinishTransaction {
                                let completion = {
                                    (str:String?,err:Error?) -> Void in
                                    if let str = str {
                                        self.showTextHUD(str, dismissAfterDelay: 1.0)
                                        return
                                    }
                                    if let err = err {
                                        self.showTextHUD("\(err)", dismissAfterDelay: 1.0)
                                        return
                                    }
                                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                                    print("Purchase Success: \(purchase.productId)")
                                    self.showTextHUD("重购成功", dismissAfterDelay: 1.0)
                                }
                                PurchaseJ.validateByServer(completion:completion)
                            }
                        }
                        print("Restore Success: \(results.restoredPurchases)")
                    }
                    else {
                        print("Nothing to Restore")
                    }
                }
            })
        return section
    }
    func generatePurchase() -> Section {
        let section = Section("")
        section
            <<< ActionRow() {
                $0.title = "连续包周"
                $0.value = "￥5"
                }.onCellSelection({ (cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    if self.isShowing != "w" {
                        self.isShowing = "w"
                    }else{
                        self.isShowing = ""
                    }
                    self.generateForm()
                })
//            <<< LabelRow(){
//                if (self.isShowing != "w"){
//                    $0.hidden = true
//                }
//                $0.title = "新用户首周免费!"
//            }
            <<< ButtonRow() {
                if (self.isShowing != "w"){
                    $0.hidden = true
                }
                $0.title = "支付"
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({(cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.pay4it(productID: "u0.vpn.vip.week")
                })
            <<< ActionRow() {
                $0.title = "连续包月"
                $0.value = "￥15"
                }.onCellSelection({ (cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    if self.isShowing != "m" {
                        self.isShowing = "m"
                    }else{
                        self.isShowing = ""
                    }
                    self.generateForm()
                })
//            <<< LabelRow(){
//                if (self.isShowing != "m"){
//                    $0.hidden = true
//                }
//                $0.title = "新用户首月半价!"
//                }
            <<< ButtonRow() {
                if (self.isShowing != "m"){
                    $0.hidden = true
                }
                $0.title = "支付"
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({(cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.pay4it(productID: "u0.vpn.vip.month")
                })
            <<< ActionRow() {
                $0.title = "连续包年"
                $0.value = "￥138"
                }.onCellSelection({ (cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    if self.isShowing != "y" {
                        self.isShowing = "y"
                    }else{
                        self.isShowing = ""
                    }
                    self.generateForm()
                })
//            <<< LabelRow(){
//                if (self.isShowing != "y"){
//                    $0.hidden = true
//                }
//                $0.title = "包年用户常年特价!"
//            }
            <<< ButtonRow() {
                if (self.isShowing != "y"){
                    $0.hidden = true
                }
                $0.title = "支付"
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({(cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.pay4it(productID: "u0.vpn.vip.year")
                })
        
        return section
    }
    func getPrice () {
        SwiftyStoreKit.retrieveProductsInfo(["u0.vpn.vip.month"]) { result in
            if let product = result.retrievedProducts.first {
                let priceString = product.localizedPrice!
                print("Product: \(product.localizedDescription), price: \(priceString)")
            }
            else if let invalidProductId = result.invalidProductIDs.first {
                print("Invalid product identifier: \(invalidProductId)")
            }
            else {
                print("Error: \(result.error)")
            }
        }
    }
    
    func pushBlockView() -> Void {
        self.block = UIAlertController(title: "联系苹果中，请稍后", message: nil, preferredStyle: .alert)
        self.present((self.block ?? nil)! , animated: true, completion: nil)
    }
    
    func pay4it(productID:String) -> Void {
        self.pushBlockView()
        SwiftyStoreKit.purchaseProduct(productID, quantity: 1, atomically: false) { result in
            self.block?.dismiss(animated: true)
            self.block = nil
            switch result {
            case .success(let purchase):
                if purchase.needsFinishTransaction {
                    let completion = {
                        (str:String?,err:Error?) -> Void in
                        if let str = str {
                            self.showTextHUD(str, dismissAfterDelay: 5.0)
                            return
                        }
                        if let err = err {
                            self.showTextHUD("\(err)", dismissAfterDelay: 5.0)
                            return
                        }
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                        print("Purchase Success: \(purchase.productId)")
                        self.showTextHUD("支付成功", dismissAfterDelay: 3.0)
                    }
                    PurchaseJ.validateByServer(completion:completion)
                }
            case .error(let error):
                switch error.code {
                case .unknown: self.showTextHUD("Unknown error. Please contact support", dismissAfterDelay: 3.0)
                case .clientInvalid: self.showTextHUD("Not allowed to make the payment", dismissAfterDelay: 3.0)
                case .paymentCancelled: break
                case .paymentInvalid: self.showTextHUD("The purchase identifier was invalid", dismissAfterDelay: 3.0)
                case .paymentNotAllowed: self.showTextHUD("The device is not allowed to make the payment", dismissAfterDelay: 3.0)
                case .storeProductNotAvailable: self.showTextHUD("The product is not available in the current storefront", dismissAfterDelay: 3.0)
                case .cloudServicePermissionDenied: self.showTextHUD("Access to cloud service information is not allowed", dismissAfterDelay: 3.0)
                case .cloudServiceNetworkConnectionFailed: self.showTextHUD("Could not connect to the network", dismissAfterDelay: 3.0)
                case .cloudServiceRevoked: self.showTextHUD("User has revoked permission to use this cloud service", dismissAfterDelay: 3.0)
                default: print((error as NSError).localizedDescription)
                }
            }
        }
    }
    
    @objc func updateExDate() {
        let exRow = self.form.rowBy(tag:kFromVIPExpire) as! LabelRow
        exRow.value = SimpleManager.sharedManager.timeIntervalChangeToTimeStr(timeInterval: SimpleManager.sharedManager.expireDate)
        exRow.reload()
    }
}
