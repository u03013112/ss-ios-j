//
//  SimpleVC.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/8.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation
import Eureka
import Cartography
import NetworkExtension

private let kFormPACMode = "FormPACMode"
private let kFromConnect = "FromConnect"
public let kFromVIPExpire = "FromVIPExpire"
public let kExDateChanged = "kExDateChanged"

class SimpleVC: FormViewController{
    var obIsAdded = false
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Simple"
        
        if (SimpleManager.sharedManager.isPACMod){
            JRule.setGFW()
        }else{
            JRule.setAll()
        }
        login()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: nil, queue: nil) { (notification) in
//            print("received NEVPNStatusDidChangeNotification")
            let nevpnconn = notification.object as! NEVPNConnection
            let status = nevpnconn.status
            self.updateUI(status:status)
        }
        updateUI()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generateForm()
    }
    
    func generateForm() {
        form.delegate = nil
        form.removeAll()
        form +++ generateLoginSection()
        form.delegate = self
    }
    
    func generateLoginSection() -> Section {
        let section = Section()
        section
//            <<< ActionRow(kFromVIPExpire) {
//                $0.title = "VIP 有效期："
//                $0.value = "-"
//                if SimpleManager.sharedManager.expireDate > 0 {
//                    $0.value = SimpleManager.sharedManager.timeIntervalChangeToTimeStr(timeInterval: SimpleManager.sharedManager.expireDate)
//                }
//            }.onCellSelection({(cell, row) -> () in
//                cell.setSelected(false, animated: true)
//                let vc = PurchaseVC()
//                self.navigationController?.pushViewController(vc,animated: true)
//            })
            <<< SwitchRow(kFormPACMode) {
                $0.title = "智能路由"
                $0.value = SimpleManager.sharedManager.isPACMod
            }.onChange({ (row) in
//                if (Manager.sharedManager.vpnStatus == VPNStatus.on){
//                    VPN.restartVPN()
//                }
                if row.value == false {
                    SimpleManager.sharedManager.isPACMod = false
                    JRule.setAll()
                }else{
                    SimpleManager.sharedManager.isPACMod = true
                    JRule.setGFW()
                }
                
            })
            <<< ButtonRow(kFromConnect) {
                $0.title = "连接"
                }.onCellSelection({ (cell, row) in
                    if row.title == "连接"{
                        print("try 2 connect")
                        SimpleManager.sharedManager.startVPN(completion:nil)
                    }else if row.title == "断开"{
                        print("try 2 disconnect")
                        SimpleManager.sharedManager.stopVPN()
                    }
                })
//            <<< ButtonRow() {
//                $0.title = "log"
//                }.onCellSelection({ (cell, row) in
//                    self.readLog()
//                })
        return section
    }
    
    func readLog(){
        let m = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.U0.ss")
        let url = m?.appendingPathComponent("a.log") ?? URL(fileURLWithPath: "")
        do {
            let str = try String(contentsOf: url)
            print(str)
        }catch{
            print(error)
        }
    }
    
    @objc func onLoginSuccess() {
        
    }
    
    @objc func onVPNStatusChanged() {
        
    }
    
    
    func getVPNConfig (completion: @escaping ([String: Any]?, Error?, String?) -> Void) {
        let token = SimpleManager.sharedManager.token
        if token == "" {
            return
        }
        let dict = ["token":token]
        
        let completion1 = {
            (result:[String: Any]?, error:Error?) -> Void in
            if let error = error {
                completion(nil,error,nil)
                return
            }
            if let result = result {
                if (result["error"] as? String != nil){
                    completion(nil,nil,result["error"] as? String)
                    return
                }
                let ret = [
                    "IP":result["IP"] as! String,
                    "port":Int(result["port"] as! String) ?? 58700,
                    "method":result["method"] as! String,
                    "passwd":result["passwd"] as! String
                ] as [String : Any]
                completion(ret,nil,nil)
                return
            }
        }
        HTTP.shared.postRequest(urlStr: "https://frp.u03013112.win:18022/v1/ios/config", data: dict, completion: completion1)
    }
    func login() {
        login(success:{ (token,ex) in
            SimpleManager.sharedManager.token = token
//            self.updateExDate()
        },failed: { (errStr) in
            let alert = UIAlertController(title: "err", message: errStr, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "comfirm", style: .cancel, handler:{ (a) in
//                重新登录，必须成功
                self.login()
            }))
            self.present(alert, animated: true, completion: nil)
        })
    }
    func login (success:@escaping (String,Double)->Void,failed:@escaping (String)->Void) {
        let dict = ["uuid":getUUID()]
        
        let completion = {
            (result:[String: Any]?, error:Error?) -> Void in
            if let error = error {
                print(error)
                failed(error.localizedDescription)
                return
            }
            if let result = result {
                if (result["error"] as? String != nil){
                    failed(result["error"] as! String)
                    return
                }
                if result["expiresDate"] as? String != nil{
                    let exStr = result["expiresDate"] as! String
                    let ex = Double(exStr)
                    SimpleManager.sharedManager.expireDate = ex ?? 0
                    success(result["token"] as! String,ex ?? 0)
                }else{
                    success(result["token"] as! String,0)
                    //                    这里抓进去充值吧
                }
                return
            }
        }
        HTTP.shared.postRequest(urlStr: "https://frp.u03013112.win:18022/v1/ios/login", data: dict, completion: completion)
    }
    
    func updateUI(status:NEVPNStatus) {
        let connectButton = self.form.rowBy(tag: kFromConnect) as! ButtonRow
        if status == .connected{
            connectButton.title = "断开"
        }else if status == .disconnected{
            connectButton.title = "连接"
        }else{
            connectButton.title = "请稍后..."
            connectButton.disabled = true
        }
        connectButton.reload()
    }
    
    func updateUI() {
        ProviderManager.sharedManager.getProviderManager { (manager, error) -> Void in
            if error == nil {
                if manager != nil {
                    self.updateUI(status: manager!.connection.status)
                }
            }
        }
    }
}
