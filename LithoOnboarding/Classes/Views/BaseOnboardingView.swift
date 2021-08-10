//
//  BaseOnboardingView.swift
//  LithoOnboarding
//
//  Created by Calvin Collins on 8/6/21.
//

import UIKit
import LithoOperators
import Prelude
import LithoUtils

public enum OnboardingLayout {
    case topDown, leftRight, bottomUp, rightLeft
}

public protocol BaseOnboardingDelegate {
    func leadingForLabel(_ maskRect: CGRect) -> CGFloat
    func topForLabel(_ maskRect: CGRect) -> CGFloat
    func widthForLabel() -> CGFloat
    func heightForLabel() -> CGFloat
}

open class BaseOnboardingView: UIView {
    
    @IBOutlet weak public var contentView: UIView!
    @IBOutlet weak public var descriptionLabel: UILabel!
    @IBOutlet weak public var arrowImageView: UIImageView!
    
    @IBOutlet weak public var labelTop: NSLayoutConstraint!
    @IBOutlet weak public var labelLeading: NSLayoutConstraint!
    @IBOutlet weak public var labelWidth: NSLayoutConstraint!
    @IBOutlet weak public var labelHeight: NSLayoutConstraint!
    
    @IBOutlet weak public var arrowTop: NSLayoutConstraint!
    @IBOutlet weak public var arrowLeading: NSLayoutConstraint!
    
    public var delegate: BaseOnboardingDelegate?
    public var completion: (() -> Void)?
    public var validate: () -> Bool = returnValue(true)
    public var rectToMask: CGRect = .zero
    public var maskLayer: CALayer?
    public var cornerRadius: CGFloat? = nil
    public var onLayoutSubviews: ((BaseOnboardingView) -> Void)?
    public var onRotate: ((BaseOnboardingView) -> Void)?
    public var shouldAllowBack = true
    public var shouldAllowUserInput = true
    
    public convenience init<T: UIViewController>(vc: T, rectToMask: CGRect) {
        self.init(frame: vc.view.bounds)
        self.rectToMask = rectToMask.insetBy(dx: -10, dy: -10)
    }
    
    public convenience init(frame: CGRect, cornerRadius: CGFloat? = nil, shouldAllowUserInput: Bool = true) {
        self.init(frame: frame)
        self.cornerRadius = cornerRadius
        self.shouldAllowUserInput = shouldAllowUserInput
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        contentView.backgroundColor = .black
        contentView.layer.backgroundColor = UIColor.black.cgColor
        contentView.layer.opacity = 0.9
        NotificationCenter.default.addObserver(self, selector: #selector(rotate), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func rotate() {
        onRotate?(self)
    }
    
    func setFrameToMask(_ rect: CGRect) {
        self.rectToMask = rect
        setUpMask()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews?(self)
    }
    
    private func setUpMask() {
        let radius = cornerRadius != nil ? cornerRadius! : (rectToMask.width > rectToMask.height ? rectToMask.height / 2 : rectToMask.width / 2)
        let path = UIBezierPath(roundedRect: CGRect(x: rectToMask.minX, y: rectToMask.minY, width: rectToMask.width, height: rectToMask.height), cornerRadius: radius)
        let maskLayer = CAShapeLayer()
        path.append(UIBezierPath(rect: self.contentView.bounds))
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        maskLayer.path = path.cgPath
        contentView.layer.mask = maskLayer
    }
    
    public func layout(with orientation: OnboardingLayout) {
        orientArrow(orientation)
        orientLabel(orientation)
    }
    
    private func orientArrow(_ orientation: OnboardingLayout) {
        switch orientation {
        case .bottomUp:
            arrowTop.constant = rectToMask.maxY + 30
            arrowLeading.constant = rectToMask.midX - 25
            arrowImageView.image = UIImage(named: "OnboardingArrowUp")
        case .leftRight:
            arrowTop.constant = rectToMask.midY - 25
            arrowLeading.constant = rectToMask.minX - 100
            arrowImageView.image = UIImage(named: "OnboardingArrowRight")
        case .rightLeft:
            arrowTop.constant = rectToMask.midY - 25
            arrowLeading.constant = rectToMask.maxX + 30
            arrowImageView.image = UIImage(named: "OnboardingArrowLeft")
        case .topDown:
            arrowTop.constant = rectToMask.minY - 100
            arrowLeading.constant = rectToMask.midX - 25
            arrowImageView.image = UIImage(named: "OnboardingArrowDown")
            arrowImageView.frame = CGRect(x: arrowLeading.constant, y: arrowTop.constant, width: 50, height: 50)
        }
    }
    
    private func orientLabel(_ orientation: OnboardingLayout) {
        if let leading = delegate?.leadingForLabel(rectToMask), let top = delegate?.topForLabel(rectToMask), let width = delegate?.widthForLabel(), let height = delegate?.heightForLabel() {
            labelLeading.constant = leading
            labelTop.constant = top
            labelHeight.constant = height
            labelWidth.constant = width
        } else {
            let width = labelWidth.constant
            switch orientation {
            case .bottomUp:
                labelLeading.constant = min(max(rectToMask.midX - width / 2, 10), UIScreen.main.bounds.width - labelWidth.constant - 10)
                labelTop.constant = min(rectToMask.maxY + 120, UIScreen.main.bounds.height - labelHeight.constant)
                descriptionLabel.contentMode = .top
            case .leftRight:
                labelLeading.constant = max(rectToMask.minX - 120 - width, 10)
                labelTop.constant = max(rectToMask.midY - labelHeight.constant / 2, 0)
            case .rightLeft:
                labelLeading.constant = max(rectToMask.maxX + 120, 10)
                labelTop.constant = max(rectToMask.midY - labelHeight.constant / 2, 0)
            case .topDown:
                labelTop.constant = max(rectToMask.minY - 180 - labelHeight.constant, 0)
                labelLeading.constant = min(max(rectToMask.midX - width / 2, 10), UIScreen.main.bounds.width - labelWidth.constant - 10)
                descriptionLabel.contentMode = .bottom
            }
        }
    }
    
    public func configureView() {
        Bundle(for: type(of: self)).loadNibNamed(String(describing: type(of: self)), owner: self, options: nil)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.frame = self.bounds
        self.addSubview(contentView)
        NSLayoutConstraint(item: contentView!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: contentView!, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: contentView!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: contentView!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        switch (!rectToMask.contains(point), shouldAllowUserInput) {
        case (true, _):
            return true
        case (false, true):
            return false
        case (false, false):
            return true
        }
    }
}

public func standardOnboardingView(frameToMask: CGRect?, cornerRadius: CGFloat? = nil, userInput: Bool) -> BaseOnboardingView {
    return BaseOnboardingView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), cornerRadius: cornerRadius, shouldAllowUserInput: userInput).configure({ $0.rectToMask = frameToMask ?? .zero } <> hide <> set(\.onLayoutSubviews, { $0.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) } <> (frameToMask >||> (coalesceNil(with: .zero) >**> setMask))))
}

public func standardOnboardingView(frameToMask: CGRect?, cornerRadius: CGFloat? = nil, layout: OnboardingLayout, userInput: Bool = true) -> BaseOnboardingView {
    return standardOnboardingView(frameToMask: frameToMask, cornerRadius: cornerRadius, userInput: userInput).configure({ $0.onLayoutSubviews <>= (layout >||> layoutOnboardingView) })
}

public func tagSetter(_ tag: Int) -> (UIView) -> Void {
    return set(\.tag, tag)
}

public func viewWithTag(_ view: UIView?, tag: Int) -> UIView? {
    if view == nil || view!.subviews.isEmpty {
        return nil
    } else {
        for subview in view!.subviews {
            if subview.tag == tag {
                return subview
            }
        }
        return view!.subviews.compactMap(tag >||> viewWithTag).first
    }
}

public let viewWithTagVC: (UIViewController, Int) -> UIView? = ^\UIViewController.view >*> viewWithTag

public let hideViewWithTag: (UIView, Int) -> Void = viewWithTag >?> hide
public let hideViewWithTagVC: (UIViewController, Int) -> Void = ^\UIViewController.view >*> hideViewWithTag

public let showViewWithTag: (UIView, Int) -> Void = viewWithTag >?> show
public let showViewWithTagVC: (UIViewController, Int) -> Void = viewWithTagVC >?> show

public func tabBarOnboardingView(index: Int, userInput: Bool = false) -> BaseOnboardingView {
    return standardOnboardingView(frameToMask: tabBarFrame(index: index), layout: .topDown, userInput: userInput).configure(set(\.shouldAllowBack, false))
}

public func setRotate(frame: @escaping () -> CGRect?, view: BaseOnboardingView?) {
    view?.onRotate = { $0.setFrameToMask(frame() ?? .zero) }
}

public func rotateSetter<T: OnboardingViewControllerProtocol & UIViewController>(getter: @escaping (T) -> CGRect?, index: Int) -> (T) -> Void {
    return { vc in
        vc.onBoardingViews |> (indexer(index: index) >>> ~>((vc *> getter) >|> setRotate))
    }
}

public func tabBarFrame(index: Int) -> CGRect {
    let screenWidth = UIScreen.main.bounds.width
    let tabWidth = screenWidth / 3
    let screenHeight = UIScreen.main.bounds.height
    return CGRect(x: tabWidth * CGFloat(index), y: screenHeight - tabBarHeight, width: tabWidth, height: tabBarHeight)
}

public func rightBarButtonFrame(for nav: UINavigationController) -> CGRect {
    switch UIDevice.current.orientation {
    case .landscapeLeft, .landscapeRight:
        return CGRect(x: UIScreen.main.bounds.width - 90, y: 0, width: 60, height: 60)
    default:
        return CGRect(x: UIScreen.main.bounds.width - 60, y: nav.navigationBar.frame.height - 5, width: 60, height: 60)
    }
}

public func topRightBarButtonOnboarding(for nav: UINavigationController) -> BaseOnboardingView {
    return standardOnboardingView(frameToMask: rightBarButtonFrame(for: nav), layout: .bottomUp, userInput: false).configure(set(\.shouldAllowBack, false))
}

public func switchToNav(vc: UIViewController & OnboardingViewControllerProtocol, tag: Int) {
    vc.onBoardingViews |> forEach(f: hide)
    if let nav = vc.navigationController {
        viewWithTagVC(nav, tag)?.isHidden = false
    } else if let nav = vc.tabBarController?.navigationController {
        viewWithTagVC(nav, tag)?.isHidden = false
    }
}
