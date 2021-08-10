//
//  OnboardingViewController.swift
//  FBSnapshotTestCase
//
//  Created by Calvin Collins on 8/6/21.
//

import UIKit
import fuikit
import LithoOperators
import Prelude
import Combine
import LithoUtils

@objc public protocol OnboardingViewControllerProtocol {
    var onBoardingViews: [UIView] { get set }
    var validate: (() -> Bool) { get set }
    var selectedIndex: Int { get set }
    var completion: (() -> Void)? { get set }
    
    @objc func setUpSwipeRecognizers()
    @objc func swipeLeft()
    @objc func swipeRight()
    @objc func proceed()
}

extension OnboardingViewControllerProtocol {
    public func setUpSwipeRecognizers() {
        onBoardingViews.forEach({
            let tap = UITapGestureRecognizer(target: self, action: #selector(swipeLeft))
            let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
            left.direction = .left
            $0.addGestureRecognizer(tap)
            $0.addGestureRecognizer(left)
        })
    }
    
    func swipeLeft() {
        if onBoarding() {
            if selectedIndex < onBoardingViews.count - 1 {
                if validateSelectedView(onBoardingViews[selectedIndex]) {
                    onBoardingViews[selectedIndex].isHidden = true
                    onBoardingViews[selectedIndex + 1].isHidden = false
                    onBoardingViews[selectedIndex] |> ~>complete
                    selectedIndex += 1
                }
            } else if validate() && validateSelectedView(onBoardingViews[selectedIndex]) {
                completion?()
                onBoardingViews[selectedIndex].isHidden = true
                selectedIndex += 1
            }
        }
    }
    
    func proceed() {
        if selectedIndex < onBoardingViews.count - 1 {
            onBoardingViews[selectedIndex].isHidden = true
            onBoardingViews[selectedIndex + 1].isHidden = false
            onBoardingViews[selectedIndex] |> ~>complete
            selectedIndex += 1
        } else {
            completion?()
            onBoardingViews[selectedIndex].isHidden = true
            selectedIndex += 1
        }
    }
    
    func swipeRight() {
        if onBoarding() {
            if let onboarding = onBoardingViews[selectedIndex] as? BaseOnboardingView {
               if onboarding.shouldAllowBack && selectedIndex != 0 {
                   onBoardingViews[selectedIndex].isHidden = true
                   onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
                   selectedIndex -= 1
               }
           } else {
               if selectedIndex > 0 {
                   onBoardingViews[selectedIndex].isHidden = true
                   onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
                   selectedIndex -= 1
               }
           }
        }
    }
}

public func onBoardingSetUpSwipe(_ vc: OnboardingViewControllerProtocol) {
    vc.setUpSwipeRecognizers()
}

//open class OnboardingViewController: FUIViewController, OnboardingViewControllerProtocol {
//    public var validate: (() -> Bool) = returnValue(true)
//
//    public var onBoardingViews: [UIView] = []
//    public var selectedIndex: Int = 0
//
//    public var completion: (() -> Void)?
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//        onBoardingViews.forEach(set(\UIView.isHidden, true) <> self.view.addSubview)
//        if onBoarding() {
//            onBoardingViews |> (indexer(index: selectedIndex) >?> set(\UIView.isHidden, false))
//        }
//    }
//
//    open override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        setUpSwipeRecognizers()
//        if onBoarding() {
//            onBoardingViews |> (indexer(index: selectedIndex) >?> set(\UIView.isHidden, false))
//        }
//    }
//
//    open func setValidate(validator: @escaping () -> Bool) {
//        self.validate = validator
//    }
//
//    open func proceed() {
//        if selectedIndex < onBoardingViews.count - 1 {
//            onBoardingViews[selectedIndex].isHidden = true
//            onBoardingViews[selectedIndex + 1].isHidden = false
//            view.bringSubviewToFront(onBoardingViews[selectedIndex + 1])
//            onBoardingViews[selectedIndex] |> ~>complete
//            selectedIndex += 1
//        } else {
//            completion?()
//            onBoardingViews[selectedIndex].isHidden = true
//            selectedIndex += 1
//        }
//    }
//
//    @objc open func swipeLeft() {
//        if onBoarding() {
//            if selectedIndex < onBoardingViews.count - 1 {
//                if validateSelectedView(onBoardingViews[selectedIndex]) {
//                    onBoardingViews[selectedIndex].isHidden = true
//                    onBoardingViews[selectedIndex + 1].isHidden = false
//                    onBoardingViews[selectedIndex] |> ~>complete
//                    selectedIndex += 1
//                }
//            } else if validate() && validateSelectedView(onBoardingViews[selectedIndex]) {
//                completion?()
//                onBoardingViews[selectedIndex].isHidden = true
//                selectedIndex += 1
//            }
//        }
//    }
//
//    @objc open func swipeRight() {
//        if onBoarding() {
//            if let onboarding = onBoardingViews[selectedIndex] as? BaseOnboardingView {
//               if onboarding.shouldAllowBack && selectedIndex != 0 {
//                   onBoardingViews[selectedIndex].isHidden = true
//                   onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
//                   selectedIndex -= 1
//               }
//           } else {
//               if selectedIndex > 0 {
//                   onBoardingViews[selectedIndex].isHidden = true
//                   onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
//                   selectedIndex -= 1
//               }
//           }
//        }
//    }
//}

public let validateSelectedView: (UIView) -> Bool = ~>validate >>> coalesceNil(with: true)

public func setOnboardingViewWithPublisher(view: BaseOnboardingView, pub: AnyPublisher<Bool, Never>?, cancelBag: inout Set<AnyCancellable>) {
    pub?.map(returnValue).sink(receiveValue: view >|> setter(\BaseOnboardingView.validate)).store(in: &cancelBag)
}

public func setOnboardingViewWithPublisher(view: BaseOnboardingView, pub: AnyPublisher<(), Never>?, cancelBag: inout Set<AnyCancellable>) {
    pub?.map(returnValue(true)).map(returnValue).sink(receiveValue: view >|> setter(\BaseOnboardingView.validate)).store(in: &cancelBag)
}

public func setOnboardingViewWithPublisher<T>(view: BaseOnboardingView, pub: AnyPublisher<T, Never>?, condition: @escaping (T) -> Bool, cancelBag: inout Set<AnyCancellable>) {
    pub?.map(condition).map(returnValue).sink(receiveValue: view >|> setter(\BaseOnboardingView.validate)).store(in: &cancelBag)
}

public func validate(onboarding: BaseOnboardingView) -> Bool {
    return onboarding.validate()
}

public func complete(onboarding: BaseOnboardingView) {
    onboarding.completion?()
}

public let onBoarding: () -> Bool = "isOnboarding" *> UserDefaults.standard.bool

public func onBoardingViewDidLayoutSubviews<T: OnboardingViewControllerProtocol & UIViewController, U>(keypath: KeyPath<T, U?>, layout: OnboardingLayout, at index: Int, padding: CGFloat? = nil) -> (T) -> Void {
    return ((^keypath >?> { $0 as? UIView }, index) >||> (padding >||||> configureOnboardingViewController)) <> ((^\T.onBoardingViews >>> indexer(index: index)) >?> ~>(layout >||> layoutOnboardingView)) <> (rotateSetter(getter: ^keypath >?> ~>(paddingSetter(padding: padding)), index: index))
}

public func paddingSetter(padding: CGFloat?) -> (UIView) -> CGRect {
    return ^\UIView.frame >>> { $0.insetBy(dx: padding ?? .zero, dy: padding ?? .zero) }
}

public func onBoardingViewDidLayoutSubviews<T: OnboardingViewControllerProtocol & UIViewController>(getter: @escaping (T) -> CGRect?, layout: OnboardingLayout, at index: Int, padding: CGFloat? = nil) -> (T) -> Void {
    return ((getter, index) >||> (padding >||||> configureOnboardingViewController)) <> ((^\T.onBoardingViews  >>> indexer(index: index)) >?> ~>(layout >||> layoutOnboardingView)) <> (rotateSetter(getter: getter, index: index))
}

public func indexer<T>(index: Int) -> ([T]) -> T? {
    return { arr in
        if index < arr.count && index >= 0 {
            return arr[index]
        }
        return nil
    }
}

public func configureOnboardingViewController<T>(vc: T, getter: @escaping (T) -> UIView?, index: Int, padding: CGFloat? = nil) where T: OnboardingViewControllerProtocol & UIViewController {
    if onBoarding() {
        if let rectToMask = getter(vc)?.frame.insetBy(dx: padding ?? 0, dy: padding ?? 0) {
            vc.onBoardingViews.forEach({ $0.frame = vc.view.bounds })
            vc.onBoardingViews |> (indexer(index: index) >?> ~>(rectToMask >||> setMask))
        }
    }
}

public func configureOnboardingViewController<T>(vc: T, getter: @escaping (T) -> CGRect?, index: Int, padding: CGFloat? = nil) where T: OnboardingViewControllerProtocol & UIViewController {
    if onBoarding() {
        if let rectToMask = getter(vc)?.insetBy(dx: padding ?? 0, dy: padding ?? 0) {
            vc.onBoardingViews.forEach({ $0.frame = vc.view.bounds })
            vc.onBoardingViews |> (indexer(index: index) >?> ~>(rectToMask >||> setMask))
        }
    }
}

public func baseOnBoardingViewDidLoad<T>(vc: T) -> Void where T: OnboardingViewControllerProtocol & UIViewController {
    vc.onBoardingViews = [BaseOnboardingView(frame: vc.view.bounds)]
}

public func setMask<T: BaseOnboardingView>(view: T, for rect: CGRect) {
    view.setFrameToMask(rect)
}

public func layoutOnboardingView<T: BaseOnboardingView>(view: T, with layout: OnboardingLayout) {
    view.layout(with: layout)
}

public let setOnboardingText = setter(\BaseOnboardingView.descriptionLabel!.text)
public let setAccessibilityIdentifier = setter(\UIView.accessibilityIdentifier)
public func onBoardingTextSetter(text: String, index: Int) -> (OnboardingViewControllerProtocol) -> Void {
    return { vc in
        vc.onBoardingViews |> (indexer(index: index) >?> (~>(text >||> setOnboardingText)) <> (~>(accessibilityIdentifier(from: text) >||> setAccessibilityIdentifier)))
    }
}

public func accessibilityIdentifier(from text: String) -> String {
    let words: [String] = text.split(separator: Character(" ")).map(String.init)
    if words.count < 5 {
        return words.joined(separator: " ")
    } else {
        return words.prefix(5).joined(separator: " ")
    }
}

public func baseOnboardingWillAppear(_ vc: UIViewController) {
    if onBoarding() {
        hideTabBar(vc)
        hideNavBarFromTab(vc)
        hideNavBar(vc)
    }
}

public func switchToNav(vc: UIViewController & OnboardingViewControllerProtocol) {
    if let nav = vc.navigationController as? OnboardingViewControllerProtocol {
        (vc.onBoardingViews |> indexer(index: vc.selectedIndex)) |> (hide >||> ifExecute)
        // overriding default behavior
        (vc.onBoardingViews |> indexer(index: vc.selectedIndex + 1)) |> (hide >||> ifExecute)
        showTabBar(vc)
        showNavBar(vc)
        showNavBarFromTab(vc)
        nav.onBoardingViews[nav.selectedIndex] |> (show <> ~>set(\BaseOnboardingView.shouldAllowBack, false))
        //nav.view.bringSubviewToFront(nav.onBoardingViews[nav.selectedIndex])
    }
}

public func switchToVC(vc: UIViewController & OnboardingViewControllerProtocol) {
    if let nav = vc.navigationController as? OnboardingViewControllerProtocol {
        vc.onBoardingViews[vc.selectedIndex] |> (show <> ~>set(\BaseOnboardingView.shouldAllowBack, false))
        hideTabBar(vc)
        hideNavBar(vc)
        hideNavBarFromTab(vc)
        nav.onBoardingViews[nav.selectedIndex] |> hide
        (nav.onBoardingViews |> indexer(index: nav.selectedIndex + 1)) |> (hide >||> ifExecute)
    }
}

//open class OnboardingNavigationController: UINavigationController, OnboardingViewControllerProtocol {
//    public var completion: (() -> Void)?
//
//    public var onBoardingViews: [UIView] = []
//
//    public var validate: (() -> Bool) = returnValue(true)
//    var onBoardingCompletion: (() -> Void)?
//
//    public var selectedIndex: Int = 0
//
//    var onViewDidLayoutSubviews: ((OnboardingNavigationController) -> Void)?
//
//    open override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    open override func viewDidLayoutSubviews() {
//        setUpSwipeRecognizers()
//    }
//
//    public func swipeLeft() {
//        if selectedIndex < onBoardingViews.count - 1 {
//            if validateSelectedView(onBoardingViews[selectedIndex]) {
//                onBoardingViews[selectedIndex].isHidden = true
//                onBoardingViews[selectedIndex + 1].isHidden = false
//                view.bringSubviewToFront(onBoardingViews[selectedIndex + 1])
//                onBoardingViews[selectedIndex] |> ~>complete
//                selectedIndex += 1
//            }
//        } else if validate() && validateSelectedView(onBoardingViews[selectedIndex]) {
//            onBoardingCompletion?()
//            onBoardingViews[selectedIndex].isHidden = true
//            selectedIndex += 1
//        }
//    }
//
//    open func proceed() {
//        if selectedIndex < onBoardingViews.count - 1 {
//            onBoardingViews[selectedIndex].isHidden = true
//            onBoardingViews[selectedIndex + 1].isHidden = false
//            view.bringSubviewToFront(onBoardingViews[selectedIndex + 1])
//            onBoardingViews[selectedIndex] |> ~>complete
//            selectedIndex += 1
//        } else {
//            onBoardingCompletion?()
//            onBoardingViews[selectedIndex].isHidden = true
//            selectedIndex += 1
//        }
//    }
//
//    public func swipeRight() {
//        if let onboarding = onBoardingViews[selectedIndex] as? BaseOnboardingView {
//            if onboarding.shouldAllowBack && selectedIndex != 0 {
//                onBoardingViews[selectedIndex].isHidden = true
//                onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
//                selectedIndex -= 1
//            }
//        } else {
//            if selectedIndex != 0 {
//                onBoardingViews[selectedIndex].isHidden = true
//                onBoardingViews |> (indexer(index: selectedIndex - 1) >?> set(\.isHidden, false))
//                selectedIndex -= 1
//            }
//        }
//    }
//}



public func bindSwitchToVC(onBoardingView: BaseOnboardingView, vc: UIViewController) {
    onBoardingView.completion = vc *> ~>switchToVC
}


