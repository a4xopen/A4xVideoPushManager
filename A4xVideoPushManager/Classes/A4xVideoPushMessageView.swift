//
//  A4xVideoPushMessageView.swift
//
//  Created by kzhi on 2020/12/9.
//

import Foundation
import AutoInch

class A4xVideoPushMessageView: UIView {
    
    static let messagePadding : CGFloat = 8.auto()
    static let animailDuration : TimeInterval = 0.3
    
    private var superWidth : CGFloat = 0
    
    private var messageCount = 0
    private var currentIsMoveBar : Bool = false
    private var currentIsMoveCount : Bool = false
    private var currentIsMoveCotent : Bool = false
    /// 当前推送过来的TraceId
    private var currentTraceId : String = ""

    private var messageContentModel : A4xVideoMessageModel?
    private var showContentMessage : Bool = false {
        didSet {
            if !showContentMessage  && !showCountMessage {
                lastCloseDateTimer = Date().timeIntervalSince1970
            }
        }
    }
    
    private var showCountMessage   : Bool = false {
        didSet {
            if !showContentMessage && !showCountMessage {
                lastCloseDateTimer = Date().timeIntervalSince1970
            }
        }
    }
    
    private var lastCloseDateTimer : TimeInterval = 0
    
    convenience init() {
        self.init(frame : .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(self.dragGesture)
        self.addGestureRecognizer(self.tapGestUre)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func superViewUpdate() {
        superWidth = UIScreen.main.bounds.width//self.superview?.frame.width ?? 0
    }
    
    func checkShowMessge() -> Bool {
        let datet = Date().timeIntervalSince1970
        if messageContentModel?.type == 3 {// 门铃
            if datet - lastCloseDateTimer > 15 {
                return true
            }
        } else { // 普通pir推送
            if datet - lastCloseDateTimer > 2 {
                return true
            }
        }
        return false
    }
    
    func hiddenMessage() {
        dragGesture.isEnabled = false
        self.messageContentView.isHidden = true
        UIView.animate(withDuration: 0.3) {
            self.messageContentView.moveTohidden()
            self.hiddenCountView()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.messageContentView.reset()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.messageContentView.isHidden = false
        }
    }
    
    func resetMessageCount() {
        messageCount = 0
        hiddenMessageCount()
    }
    
    func recordMessage(message : A4xVideoMessageModel) {
        // 判断是否横屏直播中，如果是则不弹出提示框
        if !(A4xVideoPushManager.shared.config?.enable ?? false) {
            return
        }
        if message.type == 3 { // 门铃推送
            if messageContentView.isHidden { // messageContentView.frame.origin.y > 0
                messageCount += 1
                self.showMessageCount()
            } else {
                /// 记录当前的traceID
                NSLog("收到门铃 -- 1 的traceId: \(message.traceId) image:\(message.image)")
                if self.currentTraceId != message.traceId {
                    /// 如果当前traceID 不等于 收到通知的traceId
                    /// 更新当前的traceid
                    self.currentTraceId = message.traceId ?? ""
                    
                    // 1.隐藏
                    self.messageContentView.moveTohidden()
                    self.updateCountViewFrame()
                    self.messageContentView.reset()
                    // 2.展示
                    superViewUpdate()
                    //如果图文显示和数量都不显示，那么来消息收展示消息
                    messageContentModel = message
                    showContentMessage = true //如果移除的是展示条，messageCount 应该是 > 2
                    messageCountView.isHidden = true
                    /// 这里更新了门铃通话的PushUI,展示了图片
                    messageContentView.message = message
                    
                    let messageWidth = Int(superWidth - 2 * A4xVideoPushMessageView.messagePadding)
                    let height = max(100, messageContentView.sizeThatFits(CGSize(width: messageWidth, height: 400)).height)
                    messageContentView.frame = CGRect(x: A4xVideoPushMessageView.messagePadding, y: -height, width: CGFloat(messageWidth), height: height)
                    var top : CGFloat = 20
                    if #available(iOS 11.0, *) {
                        top = self.safeAreaInsets.top
                    }
                    self.frame = CGRect(x: 0,  y: 0, width: superWidth , height: height + top)
                    self.messageContentView.defaultMinX = top
                    
                    UIView.animate(withDuration: A4xVideoPushMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                        self?.messageContentView.frame = CGRect(x: A4xVideoPushMessageView.messagePadding,  y: top, width: CGFloat(messageWidth), height: height)
                    } completion: { (f) in
                        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hiddenMessageCountent), object: nil)
                        let time : TimeInterval = A4xVideoPushManager.shared.config?.pushDoorbellShowTime ?? 15
                        self.perform(#selector(self.hiddenMessageCountent), with: nil, afterDelay: time)
                    }
                    
                } else {
                    /// 如果当前traceID 等于 收到通知的traceId
                    /// 更新UI
                    NSLog("收到门铃 -- 2 的traceId: \(message.traceId) image:\(message.image)")
                    messageContentView.message = message
                }
                
                
            }
        } else { // 普通pir推送
            if !checkShowMessge() { // 判断展示超时时间
                return
            }
            if self.currentIsMoveBar || self.currentIsMoveCount {
                return
            }
            // 消息数量view
            messageCount += 1
            if !self.showMessageContent(message: message){
                self.showMessageCount()
            }
        }
    }
    
    lazy var dragGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.moveSmailProgress(sender:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        return panGesture
    }()
    
    lazy var tapGestUre : UITapGestureRecognizer =  {
        let oneTap = UITapGestureRecognizer(target: self, action:#selector(oneClick(tap:)))
        oneTap.numberOfTapsRequired = 1
        return oneTap
    }()
    
    func showMessageContent(message: A4xVideoMessageModel) -> Bool {
        // 更新UI
        superViewUpdate()
        //如果图文显示和数量都不显示，那么来消息收展示消息
        if !showContentMessage && !showCountMessage {
            messageContentModel = message
            showContentMessage = true //如果移除的是展示条，messageCount 应该是 > 2
            messageCountView.isHidden = true
            messageContentView.message = message
            
            let messageWidth = Int(superWidth - 2 * A4xVideoPushMessageView.messagePadding)
            let height = max(100, messageContentView.sizeThatFits(CGSize(width: messageWidth, height: 400)).height)
            messageContentView.frame = CGRect(x: A4xVideoPushMessageView.messagePadding, y: -height, width: CGFloat(messageWidth), height: height)
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            self.frame = CGRect(x: 0,  y: 0, width: superWidth , height: height + top)
            self.messageContentView.defaultMinX = top
            
            UIView.animate(withDuration: A4xVideoPushMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                
                self?.messageContentView.frame = CGRect(x: A4xVideoPushMessageView.messagePadding,  y: top, width: CGFloat(messageWidth), height: height)
            } completion: { (f) in
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hiddenMessageCountent), object: nil)
                let time : TimeInterval = A4xVideoPushManager.shared.config?.pushPirShowTime ?? 5
                self.perform(#selector(self.hiddenMessageCountent), with: nil, afterDelay: time)
            }
            return true
        }
        return false
    }
    
    func showMessageCount() {
        guard messageCount > 1 else {
            return
        }
        if !showCountMessage && !showContentMessage { //如果图片和数量都不展示，不展示新的数量
            return
        }
        let messageWidth = Int(superWidth - 2 * A4xVideoPushMessageView.messagePadding)
        let countViewHeight = self.messageCountView.sizeThatFits(CGSize(width: messageWidth, height: 1000)).height
        messageCountView.messageCount = messageCount - 1
        
        if !showCountMessage {
            showCountMessage = true
            messageCountView.isHidden = false
            messageCountView.frame = CGRect(x: self.messageContentView.frame.minX, y: self.messageContentView.frame.maxY - countViewHeight, width: messageContentView.frame.width, height: countViewHeight)
            self.frame = CGRect(x: 0,  y: 0, width: superWidth, height: self.messageContentView.frame.maxY + A4xVideoPushMessageView.messagePadding + countViewHeight)

            UIView.animate(withDuration: A4xVideoPushMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                let rect = CGRect(x: self?.messageContentView.frame.minX ?? 0, y: (self?.messageContentView.frame.maxY ?? 0) + (A4xVideoPushMessageView.messagePadding), width: self?.messageContentView.frame.width ?? 0, height: countViewHeight)
                self?.messageCountView.frame = rect
            } completion: { (f) in
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.hiddenMessageCount), object: nil)
                let time : TimeInterval = A4xVideoPushManager.shared.config?.pushPirShowTime ?? 2
                self.perform(#selector(self.hiddenMessageCount), with: nil, afterDelay: time)
            }
        }else {
            if showCountMessage && !currentIsMoveCotent && !currentIsMoveCount{
                self.updateCountViewFrame()
            }
        }
    }
    
    @objc func hiddenMessageCount() {
        dragGesture.isEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.hiddenCountView()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.hiddenCountView()
        }
    }
    
    @objc func hiddenMessageCountent() {
        dragGesture.isEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.messageContentView.moveTohidden()
            self.updateCountViewFrame()
        } completion: { (f) in
            self.dragGesture.isEnabled = true
            self.messageContentView.reset()
        }
    }
    
    lazy var messageCountView: A4xMessageCountView = {
        let temp = A4xMessageCountView()
        self.addSubview(temp)
        return temp
    }()
    
    // 内部推送UI
    lazy var messageContentView: A4xVideoMessageContentView = {
        let temp = A4xVideoMessageContentView()
        temp.messageContentHiddenBlock = { [weak self ] in
            self?.showContentMessage = false
        }
        self.addSubview(temp)
        return temp
    }()
    
    // 内部推送点击
    @objc private func oneClick(tap: UITapGestureRecognizer) {
        let point = tap.location(in: self)
        if self.messageContentView.frame.contains(point) {
            let point = tap.location(in: self.messageContentView)
            let type = self.messageContentView.locationView(ofPoint: point)
            if case .moveBar = type {
                UIView.animate(withDuration: 0.3) {
                    self.messageContentView.showBar()
                    self.updateCountViewFrame()
                }
            } else {
                // 推送点击处理
                A4xVideoPushManager.shared.config?.messageContentClick?(type, messageContentModel)
                // 只有点击接听、挂断、免打扰时才会消失
                switch type {
                case .content:
                    if messageContentModel?.type != 3 {
                        hiddenMessageCountent()
                    }
                default:
                    hiddenMessageCountent()
                }
            }
            return
        }
        if self.messageCountView.frame.contains(point) {
            A4xVideoPushManager.shared.config?.messageCountClick?()
            messageCount = 0
            hiddenMessageCount()
        }
    }
    
    @objc private func moveSmailProgress(sender : UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            currentIsMoveBar = self.isMoveBar(sender: sender)
            currentIsMoveCount = self.isMoveCountView(sender: sender)
            currentIsMoveCotent = self.isMoveContentView(sender: sender)
        case .changed:
            let tran = sender.translation(in: self)
            if self.currentIsMoveCotent {
                messageContentView.moveBarTranform(yvalue: tran.y, isMoveBar: currentIsMoveBar)
                self.updateCountViewFrame()
            }else if currentIsMoveCount {
                self.moveCountViewFrame(move: tran.y)
            }
            sender.setTranslation(CGPoint.zero, in: self)
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            fallthrough
        default:
            UIView.animate(withDuration: A4xVideoPushMessageView.animailDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: UIView.AnimationOptions.allowAnimatedContent) { [weak self] in
                guard let self = self else {
                    return
                }
                if self.currentIsMoveCotent {
                    self.messageContentView.updateBarVisable(isMoveBar: self.currentIsMoveBar)
                    self.updateCountViewFrame()
                }else if self.currentIsMoveCount  {
                    self.updateCountResultFrame()
                }
            } completion: { (f) in
                self.currentIsMoveBar = false
                self.currentIsMoveCount = false
                self.currentIsMoveCotent = false
                if !self.showContentMessage {
                    self.messageContentView.reset()
                }
            }
            debugPrint("move end")
        }
    }
    
    func hiddenCountView() {
        self.updateCountViewFrame()
        showCountMessage = false
    }
    
    func updateCountResultFrame() {
        if showContentMessage {
            if self.messageCountView.frame.midY < self.messageContentView.frame.maxY {
                showCountMessage = false
                messageCount = 1
            }
        }else {
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            if self.messageCountView.frame.midY < top {
                showCountMessage = false
            }
        }
        self.updateCountViewFrame()
    }
    
    func moveCountViewFrame(move : CGFloat) {
        var top : CGFloat = 0
        if self.showContentMessage && showCountMessage {
            top = (self.messageContentView.frame.maxY) + (A4xVideoPushMessageView.messagePadding)
        }else {
            top = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            top += A4xVideoPushMessageView.messagePadding
        }
        top = min(top, messageCountView.frame.minY + move)
        let rect = CGRect(x: self.messageContentView.frame.minX, y: top, width: self.messageCountView.frame.width, height: messageCountView.frame.height)
        self.messageCountView.frame = rect
    }
    
    func updateCountViewFrame()  {
        if self.showContentMessage && showCountMessage {
            let rect = CGRect(x: self.messageContentView.frame.minX, y: (self.messageContentView.frame.maxY) + A4xVideoPushMessageView.messagePadding, width: self.messageCountView.frame.width, height: messageCountView.frame.height)
            self.messageCountView.frame = rect
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageCountView.frame.maxY)
        }else if showCountMessage{
            var top : CGFloat = 20
            if #available(iOS 11.0, *) {
                top = self.safeAreaInsets.top
            }
            let rect = CGRect(x: self.messageContentView.frame.minX, y: top + A4xVideoPushMessageView.messagePadding, width: self.messageCountView.frame.width, height: messageCountView.frame.height)
            self.messageCountView.frame = rect
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageCountView.frame.maxY)
        } else if !showCountMessage {
            self.messageCountView.frame = CGRect(x: self.messageContentView.frame.minX, y: -self.messageCountView.frame.height, width: self.messageCountView.frame.width, height: self.messageCountView.frame.height)
            self.frame = CGRect(x: 0, y: 0, width: superWidth, height: self.messageContentView.frame.maxY)
        }
    }
    
    func isMoveBar(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: messageContentView)
        let isMoveBar = messageContentView.isMoveBar(point: conLocation)
        return isMoveBar
    }
    
    func isMoveCountView(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: self)
        let isMove = self.messageCountView.frame.contains(conLocation)
        return isMove
    }
    
    func isMoveContentView(sender : UIPanGestureRecognizer) -> Bool {
        let conLocation = sender.location(in: self)
        let isMove = self.messageContentView.frame.contains(conLocation)
        return isMove
    }
}
