//
//  A4xMessageHelper.swift
//
//  Created by kzhi on 2020/12/9.
//

import UIKit

extension UIImage {
    static func adNamed(named : String) -> UIImage? {
        let frameworkBundle : Bundle = Bundle(for: A4xVideoMessageContentView.self)
        if let url = frameworkBundle.url(forResource: "A4xVideoPushManager", withExtension: "bundle") {
            let bundle = Bundle(url: url)
            return UIImage(named: named, in: bundle, compatibleWith: nil)
        }else {
            NSLog("A4xVideoMessage bundle load error")
            return nil
        }
    }
    
}
