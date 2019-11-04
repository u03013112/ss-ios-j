//
//  HTTP.swift
//  ShadowCoel
//
//  Created by 宋志京 on 2019/10/9.
//  Copyright © 2019 CoelWu. All rights reserved.
//

import Foundation

class HTTP: NSObject{
    static let shared = HTTP()
    
    func postRequest(urlStr: String,data: [String:Any], completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url = URL(string: urlStr)!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        } catch let error {
            print(error.localizedDescription)
            completion(nil, error)
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
                return
            }
            guard let data = data else {
                DispatchQueue.main.async(execute: {
                    completion(nil, NSError(domain: "dataNilError", code: -100001, userInfo: nil))
                })
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    DispatchQueue.main.async(execute: {
                        completion(nil, NSError(domain: "invalidJSONTypeError", code: -100009, userInfo: nil))
                    })
                    return
                }
                print(json)
                DispatchQueue.main.async(execute: {
                    completion(json, nil)
                })
                
            } catch let error {
                print(error.localizedDescription)
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
            }
        })
        task.resume()
    }
    func getRequest(urlStr: String, completion: @escaping (String?, Error?) -> Void) {
        let url = URL(string: urlStr)!
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                DispatchQueue.main.async(execute: {
                    completion(nil, error)
                })
                return
            }
            guard let data = data else {
                DispatchQueue.main.async(execute: {
                    completion(nil, NSError(domain: "dataNilError", code: -100001, userInfo: nil))
                })
                return
            }
            
            let str = String.init(data: data, encoding: .utf8)
            print(str ?? "str failed")
            DispatchQueue.main.async(execute: {
                completion(str, nil)
            })
        })
        task.resume()
    }
}
