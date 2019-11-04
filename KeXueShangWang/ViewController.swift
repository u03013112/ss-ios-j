//
//  ViewController.swift
//  KeXueShangWang
//
//  Created by 宋志京 on 2019/11/1.
//  Copyright © 2019 宋志京. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let vc = SimpleVC()
        self.view.addSubview(vc.view)
        self.addChild(vc)
    }
}

