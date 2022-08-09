//
//  A4xVideoPushManager.swift
//
//  Created by wjin on 2020/12/8.
//

import Foundation
import UIKit
public enum A4xVideoMessageFilterType {
    case all
    case none
    case id(id : String?)
}


public class A4xVideoPushManager {
    public var filter: A4xVideoMessageFilterType?
    public static let shared = A4xVideoPushManager()
    
    public var config: A4xVideoMessageConfig? {
        didSet {
            config?.enableChangeBlock = { [weak self] in
                if !(self?.config?.enable ?? false) {
                    self?.hiddenMessage()
                }
            }
        }
    }

    public weak var inView: UIView? {
        didSet {
            if videoPushMessageView.superview != nil {
                videoPushMessageView.removeFromSuperview()
            }
        }
    }
    
    
    /// 消息格式
    /// - Parameter dict: {
    ///  "id": 2924129,
    ///    "videoUrl": "videoURl",
    ///    "timestamp": 1607915072,
    ///    "serialNumber": "7819097212940196d6076162ef2e5d2d",
    ///    "tags": "person",
    ///    "imageUrl": "https:imageURl",
    ///    "deviceName": "Vicoo智能摄像机",
    ///    "adminName": "Jason",
    ///    "traceId" : 2222
    ///    "pushInfo": "发现有人"
    ///  }
    public func recordMessage(dict: Dictionary<String,Any>){
        if self.videoPushMessageView.superview == nil {
            self.inView?.insertSubview(self.videoPushMessageView, at: 100)
            self.videoPushMessageView.superViewUpdate()
        }
        assert(self.inView != nil , "请设置展示的view")
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
            let decoder = JSONDecoder()
            if let modle  = try? decoder.decode(A4xVideoMessageModel.self, from: data) {
                self.videoPushMessageView.recordMessage(message: modle)
                self.videoPushMessageView.superViewUpdate()
                
//                // 4.GCD 主线程/子线程
//                var newModel = modle
//                newModel.image = "https://iknow-pic.cdn.bcebos.com/5882b2b7d0a20cf4aa7c036f78094b36adaf9996?x-bce-process=image%2Fresize%2Cm_lfit%2Cw_600%2Ch_800%2Climit_1%2Fquality%2Cq_85%2Fformat%2Cf_auto"
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//
//                    self.videoPushMessageView.recordMessage(message: newModel)
//                }
            }
        }
    }
    
    public func hiddenMessage() {
        self.videoPushMessageView.hiddenMessage()
    }
    
    public func resetMessageCount() {
        self.videoPushMessageView.resetMessageCount()
    }
    
    private lazy var videoPushMessageView: A4xVideoPushMessageView = {
        let temp = A4xVideoPushMessageView()
        return temp
    }()
}

extension A4xVideoPushManager {
    
    
}
