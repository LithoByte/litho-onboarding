//
//  Styles.swift
//  LithoOnboarding
//
//  Created by Calvin Collins on 8/6/21.
//

import UIKit
import LithoOperators

let hide = set(\UIView.isHidden, true)
let show = set(\UIView.isHidden, false)

//MARK: - OnBoarding

public let hideTabBar: (UIViewController) -> Void = { $0.tabBarController?.tabBar.isHidden = true }
public let hideNavBar: (UIViewController) -> Void = { $0.navigationController?.isNavigationBarHidden = true }
public let hideNavBarFromTab: (UIViewController) -> Void = {
    $0.tabBarController?.navigationController?.isNavigationBarHidden = true
}

public let showTabBar: (UIViewController) -> Void = { $0.tabBarController?.tabBar.isHidden = false }
public let showNavBar: (UIViewController) -> Void = { $0.navigationController?.isNavigationBarHidden = false }
public let showNavBarFromTab: (UIViewController) -> Void = {
    $0.tabBarController?.navigationController?.isNavigationBarHidden = false
}

public func convert(subview: UIView, to vc: UIViewController) -> CGRect {
    return subview.convert(subview.bounds, to: vc.view)
}

public func convert(layer: CALayer, to vc: UIViewController) -> CGRect {
    return layer.convert(layer.bounds, to: vc.view.layer)
}

public let device = UIDevice.current.userInterfaceIdiom
public var tabBarHeight: CGFloat {
    switch device {
    case .pad:
        return 49.0
    case .phone:
        if UIScreen.main.scale == 3.0 {
            let orientation = UIDevice.current.orientation
            switch orientation {
            case .landscapeLeft, .landscapeRight:
                return 53.0
            case .portrait, .portraitUpsideDown, .faceUp:
                return 83.0
            default:
                return .zero
            }
        } else {
            return 49.0
        }
    default:
        return .zero
    }
}

