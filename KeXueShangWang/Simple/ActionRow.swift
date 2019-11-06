//
//  ActionRow.swift
//  KeXueShangWang
//
//  Created by 宋志京 on 2019/11/5.
//  Copyright © 2019 宋志京. All rights reserved.
//

import Foundation
import Eureka
import MBProgressHUD
import Async

public final class ActionRow: _LabelRow, RowType {
    
    public required init(tag: String?) {
        super.init(tag: tag)
    }
    
    public override func updateCell() {
        super.updateCell()
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
    }
    
    public override func didSelect() {
        super.didSelect()
        cell.setSelected(false, animated: true)
    }
    
}

extension UIViewController {
    @objc func showTextHUD(_ text: String?, dismissAfterDelay: TimeInterval) {
        hideHUD()
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.mode = .text
        hud.detailsLabel.text = text
        hideHUD(dismissAfterDelay)
    }
    
    @objc func hideHUD() {
        MBProgressHUD.hide(for: view, animated: true)
    }
    
    @objc func hideHUD(_ afterDelay: TimeInterval) {
        Async.main(after: afterDelay) {
            self.hideHUD()
        }
    }
    
}
