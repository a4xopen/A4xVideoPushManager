//
//  A4xVideoMessageConfig.swift
//
//  Created by kzhi on 2020/12/9.
//

import Foundation
import UIKit

// App内推送点击类型
public enum A4xVideoMessageLoctionInViewType {
    case moveBar
    case content
    case messageNotip
    case offCall // 门铃挂断
    case onCall // 门铃接听
}

public enum A4xVideoMessageConfigStringType {
    case messageDateString(time : TimeInterval)
    case messageCountDestion(count : Int)
    case messageNoTipButton
}

public enum A4xVideoMessageConfigImageType {
    case messageDateFormat
    case messageCountDestion(count : Int)
}

public enum A4xVideoMessageConfigColorType {
    case theme
}
public class A4xVideoMessageConfig {
    var loadStringBlock : ((_ type : A4xVideoMessageConfigStringType) -> String)
    var loadImageBlock : ((_ type : A4xVideoMessageConfigImageType) -> UIImage?)
    var loadColorBlock : ((_ type : A4xVideoMessageConfigColorType) -> UIColor?)
    
    internal var enableChangeBlock : (()->Void)?
    
    public var messageContentClick: ((_ type : A4xVideoMessageLoctionInViewType , _ msg : A4xVideoMessageModel?)->Void)?
    public var messageCountClick: (()->Void)?

    public var pushPirShowTime : TimeInterval = 5
    public var pushDoorbellShowTime : TimeInterval = 15
    
    public var enable : Bool = true {
        didSet {
            print("A4xVideoMessageConfig enable \(enable)")
            enableChangeBlock?()
        }
    }

    public init(loadString : (@escaping (_ type : A4xVideoMessageConfigStringType) -> String) , loadImage : (@escaping  (_ type : A4xVideoMessageConfigImageType) -> UIImage?) = {_ in return nil} , loadColor : (@escaping  (_ type : A4xVideoMessageConfigColorType) -> UIColor?) = {_ in return nil}) {
    
        self.loadImageBlock = loadImage
        self.loadStringBlock = loadString
        self.loadColorBlock = loadColor
    }
    
}
