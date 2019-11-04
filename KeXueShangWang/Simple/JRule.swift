//
//  Rule.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/13.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation

class JRule: NSObject{
    static func setGFW() {
        let completion = {
            (result:String?, error:Error?) -> Void in
            if let result = result {
                if let data = Data(base64Encoded: result,options: .ignoreUnknownCharacters){
                    let str = String(data: data, encoding: String.Encoding.utf8)
                    var lines = str!.components(separatedBy: CharacterSet.newlines)
                    lines = lines.filter({ (s: String) -> Bool in
                        if s.isEmpty {
                            return false
                        }
                        let c = s[s.startIndex]
                        if c == "!" || c == "[" || c == "@" {
                            return false
                        }
                        return true
                    })
                    var count = 0
                    var retStr = ""
                    for line in lines {
                        var str = line
                        if str.count > 400 {
                            continue
                        }
                        if str.hasPrefix("||") {
                            let startIndex = str.index(str.startIndex, offsetBy: 2)
                            str = String(str[startIndex..<str.endIndex])
                        }else if str.hasPrefix("|") {
                            let startIndex = str.index(str.startIndex, offsetBy: 1)
                            str = String(str[startIndex..<str.endIndex])
                        }else if str.hasPrefix("https://") {
                            let startIndex = str.index(str.startIndex, offsetBy: 8)
                            str = String(str[startIndex..<str.endIndex])
                        }else if str.hasPrefix("http://") {
                            let startIndex = str.index(str.startIndex, offsetBy: 7)
                            str = String(str[startIndex..<str.endIndex])
                        }
                        count += 1
                        retStr += "DOMAIN-SUFFIX, "+str+",PROXY\n"
                    }
                    do {
                        try self.setRule(str: retStr)
                    }catch{
                        print(error)
                    }
                }
            }
        }
        HTTP.shared.getRequest(urlStr: "https://raw.github.com/gfwlist/gfwlist/master/gfwlist.txt", completion: completion)
    }
    
    static func setAll() {
        do {
            try self.setRule(str: "DOMAIN-SUFFIX, *, PROXY")
        }catch {
            print(error)
        }
    }
    
    static func setRule(str:String) throws{
        let m = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.U0.ss")
        let action = m?.appendingPathComponent("action.conf") ?? URL(fileURLWithPath: "")
        let http = m?.appendingPathComponent("http.conf") ?? URL(fileURLWithPath: "")
        
        let httpDict : [String: AnyObject] = ["actionsfile":action.path as AnyObject]
        let httpStr = httpDict.map { "\($0) \($1)"}.joined(separator: "\n")
        try httpStr.write(to: http, atomically: true, encoding: String.Encoding.utf8)
        
        let actionStr = "{+forward-rule}\n" + str
        try actionStr.write(to: action, atomically: true, encoding: String.Encoding.utf8)
        print(actionStr)
    }
}
