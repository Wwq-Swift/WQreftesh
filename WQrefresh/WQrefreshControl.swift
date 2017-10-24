//
//  WQrefresh.swift
//  WQrefresh
//
//  Created by 王伟奇 on 2017/10/24.
//  Copyright © 2017年 王伟奇. All rights reserved.
//
// //下拉刷新的设置 (一种方法是系统自带   另一种自定义的(1.实例化刷新控件，2.添加到表格视图，3.添加监听方法))

import UIKit

/// 刷新状态切换的临界点
fileprivate let WQrefreshOffset: CGFloat = 60

/// 刷新状态
///
/// - Normal: 普通状态什么都不做
/// - Pulling: 正在下拉并且超过临界点，如果放手，开始刷新
/// - WillRefresh: 用户下拉超过临界点并且放手
enum WQrefreshState {
    case Normal
    case Pulling
    case WillRefresh
}

/// 刷新控件 - 负责相关的逻辑处理
class WQrefreshControl: UIControl {

    // MARK: - 属性
    /// 刷新控件的父视图， 下拉刷新控件使用于 UITabeleView ／ UICollectionView
    private weak var scrollView: UIScrollView?
    
    /// 刷新控件视图
    fileprivate lazy var refreshView: WQrefreshView = WQrefreshView.regreshView()
    
    // MARK: - 构造方法
    init() {
        super.init(frame: CGRect())
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     willMove addSubview 方法会调用
     - 当添加到父视图的时候，newSuperview 是父视图
     - 当父视图被移除，newSuperview 是 nil
     */
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        // 判断父视图是否存在
        guard let supView = newSuperview else {
            return
        }
        
        // 记录父滚动视图
        scrollView = supView as? UIScrollView
        
        // KVO 监听父滚动视图是否滚动 contentOffset
        scrollView?.addObserver(self, forKeyPath: "contentOffset", options: [], context: nil)
    }

    // 本视图从父视图上移除
    // 提示： 所有的下啦刷新框架都要监听父视图的 contentOffset
    //       所有的框架 KVO 监听实现思路都是这个
    override func removeFromSuperview() {
        // 一定要在removeFromSuperView之前进行监听的移除
        superview?.removeObserver(self, forKeyPath: "contentOffset") //这时候superView还存在
        super.removeFromSuperview()                                  //这时候superView已经不存在了
        
    }
    
    //所有KVO 方法会统一调用此方法
    //在程序中，通常只监听某一个对象的几个属性，如果属性太多，方法会很乱
    //观察者模式，在不需要的时候，都需要释放
    // - 通知中心： 如果不释放，什么也不会发生，但是会有内存泄漏，会有多次注册的可能
    // - KVO 如果不释放，会崩溃
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // contentOffset 的 y 和 contentInset 的 top 有关
        
        guard let supView = scrollView else {
            return
        }
        
        // 初始高度应该是 0
        let height = -(supView.contentInset.top + supView.contentOffset.y)
        
        if height < 0 {
            return
        }
        
        // 根据高度设置刷新控件的 frame
        self.frame = CGRect(x: 0, y: -height, width: supView.bounds.width, height: height)
        
        // 判断临界点 只需要判断一次(首先判断是否在拖拉)
        if supView.isDragging {
            // 拉过临界点，未放手
            if height > WQrefreshOffset && refreshView.refreshState == .Normal {
                refreshView.refreshState = .Pulling
                
                // 未拉过临界点未放手
            }else if height <= WQrefreshOffset && refreshView.refreshState == .Pulling{
                refreshView.refreshState = .Normal
            }
            
        }else {
            
            //放手了 判断是否超过临界点的时候放手
            if refreshView.refreshState == .Pulling {
                
                // 需要刷新结束之后 将状态改为 normal 才能继续响应刷新
                refreshView.refreshState = .WillRefresh
                
                //让整个刷新视图能够现实出来 （解决方法： 修改表格的 contentInset）
                var insert           = supView.contentInset
                insert.top          += WQrefreshOffset
                
                supView.contentInset = insert
                
                // 发送刷新数据事件
                sendActions(for: .valueChanged)
                
            }
            
        }
    }
    
    // 开始刷新
    func beginRefreshing() {
        
        // 判断父视图
        guard let supView = scrollView else {
            return
        }
        
        // 设置刷新状态
        refreshView.refreshState = .WillRefresh
        
        // 调整表格间距
        var insert           = supView.contentInset
        insert.top          += WQrefreshOffset
        
        supView.contentInset = insert
        
    }
    
    // 结束刷新
    func endRefreshing() {
        
        guard let supView = scrollView else {
            return
        }
        
        // 判断状态， 是否正在刷新， 如果不是直接返回
        if refreshView.refreshState != .WillRefresh {
            return
        }
        
        // 恢复状态视图的状态
        refreshView.refreshState = .Normal
        
        // 恢复表格的contentInsert
        var insert           = supView.contentInset
        insert.top          -= WQrefreshOffset
        
        supView.contentInset = insert
        
    }
    
}

/// MARK: - 设置相关ui及手写自动布局
extension WQrefreshControl{
    
    fileprivate func setupUI() {
        
        /// 设置超出边界不显示
//        clipsToBounds = true
        /// 设置背景颜色和父视图的背景颜色一致
        self.backgroundColor        = superview?.backgroundColor
        refreshView.backgroundColor = superview?.backgroundColor
        // 添加新视图
        addSubview(refreshView)
        
        /// 自动布局 - 设置xib 控件的自动布局， 需要制定宽高约束
        //提示 ：  ios 程序员 一定要会原生的写法， 因为： 如果自己开发框架，不能用任何的自动布局框架
        refreshView.translatesAutoresizingMaskIntoConstraints = false  //关闭自动布局
        
        addConstraints([NSLayoutConstraint(item: refreshView,
                                           attribute: .centerX,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .centerX,
                                           multiplier: 1.0,
                                           constant: 0),
                        NSLayoutConstraint(item: refreshView,
                                           attribute: .bottom,
                                           relatedBy: .equal,
                                           toItem: self,
                                           attribute: .bottom,
                                           multiplier: 1.0,
                                           constant: 0),
                        NSLayoutConstraint(item: refreshView,
                                           attribute: .width,
                                           relatedBy: .equal,
                                           toItem: nil,
                                           attribute: .notAnAttribute,
                                           multiplier: 1.0,
                                           constant: refreshView.bounds.width),
                        NSLayoutConstraint(item: refreshView,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: nil,
                                           attribute: .notAnAttribute,
                                           multiplier: 1.0,
                                           constant: refreshView.bounds.height)])
    }
    
}





























