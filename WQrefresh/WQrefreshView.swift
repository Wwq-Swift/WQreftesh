//
//  WQrefreshView.swift
//  WQrefresh
//
//  Created by 王伟奇 on 2017/10/24.
//  Copyright © 2017年 王伟奇. All rights reserved.
//

import UIKit

/// 刷新视图 - 负责相关的 UI 显示和动画
class WQrefreshView: UIView {

    /// 提示标签
    @IBOutlet weak var tipLabel: UILabel!
    /// 提示图片
    @IBOutlet weak var tipIcon: UIImageView!
    /// 提示器（小菊花）
    @IBOutlet weak var tipIndicator: UIActivityIndicatorView!
    
    /// 根据下拉状态的变化改变 下拉刷新控件的相关 视图
    var refreshState: WQrefreshState = .Normal {
        didSet{
            switch self.refreshState {
                
            case .Normal:
                //恢复状态
                tipIcon.isHidden = false
                tipIndicator.stopAnimating()
                tipLabel.text    = "继续使劲拉..."
                UIView.animate(withDuration: 0.25, animations: { 
                    self.tipIcon.transform = CGAffineTransform.identity
                })
                
            case .Pulling:
                //超过临界点，还未放手的状态
                tipLabel.text = "放手刷新..."
                UIView.animate(withDuration: 0.25, animations: { 
                    self.tipIcon.transform = CGAffineTransform(rotationAngle: CGFloat.pi - 0.001)
                })
                
            case .WillRefresh:
                //超过临界点并且放手
                tipLabel.text    = "正在刷新中"
                tipIcon.isHidden = true   //隐藏图片
                tipIndicator.startAnimating() //小菊花开始转
                
            }
            
        }
    }
    
    /// 创建refreshView
    class func regreshView() -> WQrefreshView {
        let nib = UINib(nibName: "WQrefreshView", bundle: nil)
        return nib.instantiate(withOwner: nil, options: nil)[0] as! WQrefreshView
    }
    
}
