//
// Swiftuna.swift
//
// Copyright (c) 2014 Kevin Wong
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

private let kAssociationKey : String = "Swiftuna.AssociationKey"
private let kOptionsHorizontalSpacing : CGFloat = 5.0

/**
*  This protocol represents the reactive behavior under interaction
*/
@objc public protocol SwiftunaDelegate : class {
    
    /**
    Method to be called whenever an option is selected
    
    - parameter swiftuna: The swiftuna object that initiated the call
    - parameter option:   The option that was selected
    - parameter index:    The index of the selected option
    
    - returns: Void
    */
    func swiftuna(_ swiftuna : Swiftuna, didSelectOption option : SwiftunaOption, index : Int)
    
    /**
    Optional method to be called after selection of an option.
    Must indicate if the options view should be dismissed after selection.
    The default value is true.
    
    - parameter swiftuna: The swiftuna object that initiated the call
    - parameter option:   The option that was selected
    - parameter index:    The index of the selected option
    
    - returns: Wether the options view should be dismissed or not
    */
    @objc optional func swiftuna(_ swiftuna : Swiftuna, shouldDismissAfterSelectionOfOption option : SwiftunaOption, index : Int) -> Bool
}

/**
*  Decorator class that sets up a view with a swipe to open options
*  menu
*/
open class Swiftuna : NSObject {
    
    //MARK: Public Variables
    
    /// The reference delegate object
    open weak var delegate : SwiftunaDelegate?
    
    /// The view that is decorated with the options menu
    open unowned var targetView : UIView {
        get {
            return _targetView
        }
    }
    
    /// A tag to identify the Swiftuna instance
    open var tag : AnyObject?
    
    /// The options that are represented in the menu
    open var options : [SwiftunaOption] {
        get {
            return _options
        }
    }
    
    /// Indicates if swiping the viw will trigger the options menu.
    /// By default it is true
    open var swipeEnabled : Bool = true
    
    /// The background color of the view that is displayed when the
    /// options menu is triggered. Should not be a translucent color.
    open var backgroundViewColor : UIColor? {
        get {
            return backgroundView.backgroundColor
        }
        set {
            backgroundView.backgroundColor = newValue
        }
    }
    
    /// The current spacing in between options. It defaults to
    /// kOptionsHorizontalSpacing
    open var optionsSpacing : CGFloat
    
    //MARK: Private variables
    
    fileprivate unowned var _targetView : UIView
    fileprivate var _options : [SwiftunaOption]
    fileprivate var optionsView : UIView
    fileprivate var didShowMenu : Bool = false
    fileprivate var snapshotView : UIImageView?
    fileprivate var dismissView : UIButton
    fileprivate var backgroundView : UIView
    
    //MARK: Initializers
    
    /**
    The main initializer of the decorator which sets up its initial properties,
    including default values.
    
    - parameter targetView: The view to which the swipe menu will be attached
    - parameter options:    The options to display in the menu. The first option is
    displayed to the left.
    
    - returns: The initialized Swiftuna instance
    */
    public init(targetView : UIView, options : [SwiftunaOption]) {
        
        _targetView = targetView
        optionsView = UIView()
        dismissView = UIButton()
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.black
        _options = options
        optionsSpacing = kOptionsHorizontalSpacing
        
        super.init()
    }
    
    //MARK: Public methods
    
    /**
    This does the actual attaching and layout of the swipe menu.
    This should always be called after all configuration has been made.
    */
    open func attach() {
        
        setupBackgroundView()
        setupDismissView()
        setupOptionsView()
        setupGestureRecognizer()
        attachToView()
    }
    
    /**
    Detaches the swipe menu from the target view.
    */
    open func detach() {
        
        removeViews()
        optionsView.removeFromSuperview()
        
        objc_setAssociatedObject(targetView, kAssociationKey, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    /**
    This method resets the swipe menu to its original and untriggered
    state.
    */
    open func reset() {
        
        didShowMenu = false
        self.dismissView.isHidden = true
        self.optionsView.isHidden = true
        self.backgroundView.isHidden = true
        self.snapshotView?.removeFromSuperview()
        
        for optionView in optionsView.subviews as [UIView] {
            optionView.transform = CGAffineTransform.identity
        }
    }
    
    /**
    This method updates the menu view with new options
    
    - parameter options: The new options to show
    */
    open func refreshWithNewOptions(_ options : [SwiftunaOption]) {
     
        _options = options
        optionsView.removeFromSuperview()
        optionsView = UIView()
        setupOptionsView()
    }
    
    //MARK: Private methods - Setup
    
    fileprivate func setupOptionsView() {
        
        optionsView.frame = CGRect(x: 0, y: 0, width: 0, height: 100)
        optionsView.isHidden = true
        optionsView.translatesAutoresizingMaskIntoConstraints = false
        targetView.addSubview(optionsView)
        
        let optionsViewWidth = optionsViewCalculatedWidth()
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[optionsView]|",
            options: NSLayoutFormatOptions(),
            metrics: nil,
            views: ["optionsView": optionsView]))
        NSLayoutConstraint(item: optionsView,
            attribute: NSLayoutAttribute.width,
            relatedBy: NSLayoutRelation.equal,
            toItem: nil,
            attribute: NSLayoutAttribute.notAnAttribute,
            multiplier: 1,
            constant: optionsViewWidth).isActive = true
        NSLayoutConstraint(item: optionsView, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: targetView, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0).isActive = true
        
        setupOptionsWithOptionsViewWidth(optionsViewWidth)
    }
    
    fileprivate func setupOptionsWithOptionsViewWidth(_ optionsViewWidth : CGFloat) {

        var iterationCounter : Int = 0
        var previousOption : UIButton?
        
        for option in options {
            
            let optionItem = UIButton()
            optionItem.tag = iterationCounter
            optionItem.addTarget(self, action: #selector(Swiftuna.optionSelected(_:)), for: UIControlEvents.touchUpInside)
            optionItem.translatesAutoresizingMaskIntoConstraints = false
            optionsView.addSubview(optionItem)
            optionItem.setBackgroundImage(option.image, for: UIControlState())
            
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: optionsView, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0).isActive = true
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: option.size.width).isActive = true
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: option.size.height).isActive = true
            
            if previousOption != nil {
            
                NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: previousOption, attribute: NSLayoutAttribute.right, multiplier: 1, constant: optionsSpacing).isActive = true
            }
            else {
            
                NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: optionsView, attribute: NSLayoutAttribute.left, multiplier: 1, constant: optionsViewWidth).isActive = true
            }
        
            previousOption = optionItem
            iterationCounter += 1
        }
    }
    
    fileprivate func optionsViewCalculatedWidth() -> CGFloat {
        
        var width : CGFloat = 0.0
        for option in options {
            width += option.size.width
        }
        
        return width
    }
    
    fileprivate func setupDismissView() {
        
        dismissView.translatesAutoresizingMaskIntoConstraints = false
        targetView.addSubview(dismissView)
        let dismissViewLayoutDictionary = ["dismissView": dismissView]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[dismissView]|", options: NSLayoutFormatOptions(), metrics: nil, views: dismissViewLayoutDictionary))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[dismissView]|", options: NSLayoutFormatOptions(), metrics: nil, views: dismissViewLayoutDictionary))
        
        dismissView.backgroundColor = UIColor.clear
        dismissView.addTarget(self, action: #selector(Swiftuna.hideOptionsView), for: UIControlEvents.touchUpInside)
        dismissView.isHidden = true
    }
    
    fileprivate func setupBackgroundView() {
    
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        targetView.addSubview(backgroundView)
        
        let backgroundViewDictionary = ["backgroundView": backgroundView]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundView]|", options: NSLayoutFormatOptions(), metrics: nil, views: backgroundViewDictionary))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundView]|", options: NSLayoutFormatOptions(), metrics: nil, views: backgroundViewDictionary))
        
        backgroundView.isHidden = true
    }
    
    fileprivate func setupGestureRecognizer() {
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(Swiftuna.viewSwiped(_:)))
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.left
        targetView.addGestureRecognizer(swipeGestureRecognizer)
        targetView.isUserInteractionEnabled = true
    }
    
    fileprivate func attachToView() {
        
        objc_setAssociatedObject(targetView, kAssociationKey, self, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    //MARK: Private methods - Interaction
    
    func viewSwiped(_ swipeGestureRecognizer : UISwipeGestureRecognizer) {
        
        if swipeEnabled && !didShowMenu {
            
            didShowMenu = true
            setupSnapshotView()
            backgroundView.isHidden = false
            dismissView.isHidden = false
            optionsView.isHidden = false
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                self.transformSnapshotView()
            }, completion: nil)
            
            var iteratorCount = 0.0
            for optionView in optionsView.subviews {
                animateOption(optionView as! UIButton, delay: iteratorCount * 0.1)
                iteratorCount += 1
            }
        }
    }
    
    fileprivate func removeViews() {
        
        optionsView.removeFromSuperview()
        backgroundView.removeFromSuperview()
        dismissView.removeFromSuperview()
    }
    
    func hideOptionsView() {
        
        if !didShowMenu {
            return
        }
        
        didShowMenu = false
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.transformBackSnapshotView()
        }, completion: { (completed) -> Void in
            if completed {
                self.dismissView.isHidden = true
                self.optionsView.isHidden = true
                self.backgroundView.isHidden = true
                self.snapshotView!.removeFromSuperview()
            }
        }) 
        
        var iteratorCount = 0.0
        for optionView in optionsView.subviews {
            animateBackOption(optionView as! UIButton, delay: (Double(options.count) - iteratorCount - 1.0) * 0.1)
            iteratorCount += 1
        }
    }
    
    func optionSelected(_ optionItem : UIButton) {
        
        let index = optionItem.tag
        delegate?.swiftuna(self, didSelectOption: options[index], index: index)
        
        var shouldDismiss = true
        if let shouldDismissResult = delegate?.swiftuna?(self, shouldDismissAfterSelectionOfOption: options[index], index: index) {
            shouldDismiss = shouldDismissResult
        }
        
        if shouldDismiss {
            hideOptionsView()
        }
    }
    
    //MARK: Private methods - Animation
    
    fileprivate func animateOption(_ option : UIButton, delay : TimeInterval) {
        
        let width = optionsView.bounds.size.width + optionsSpacing * CGFloat(options.count)
        option.alpha = 0
        
        UIView.animate(withDuration: 0.4, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            option.transform = option.transform.translatedBy(x: -width, y: 0)
            option.alpha = 1
        }, completion: nil)
    }
    
    fileprivate func animateBackOption(_ option : UIButton, delay : TimeInterval) {
        
        UIView.animate(withDuration: 0.4, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
            option.transform = CGAffineTransform.identity
            option.alpha = 0
            }, completion: nil)
    }
    
    fileprivate func setupSnapshotView() {
        
        snapshotView = UIImageView(frame: targetView.bounds)
        
        UIGraphicsBeginImageContextWithOptions(targetView.frame.size, targetView.isOpaque, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        if let unwrappedContext : CGContext = context {
            targetView.layer.render(in: unwrappedContext)
            let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            snapshotView!.image = snapshotImage
        }
        
        snapshotView!.layer.allowsEdgeAntialiasing = true
        
        backgroundView.addSubview(snapshotView!)
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            unwrappedSnapshotView.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
            unwrappedSnapshotView.layer.position = CGPoint(x: unwrappedSnapshotView.layer.position.x - unwrappedSnapshotView.layer.bounds.size.width / 2, y: unwrappedSnapshotView.layer.position.y)
        }
    }
    
    fileprivate func transformSnapshotView() {
    
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            var identity = CATransform3DIdentity
            identity.m34 = 0.001
            unwrappedSnapshotView.layer.transform = CATransform3DRotate(identity, CGFloat(-20 / 180 * Double.pi), 0, 1, 0)
        }
    }
    
    fileprivate func transformBackSnapshotView() {
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {

            unwrappedSnapshotView.layer.transform = CATransform3DIdentity
        }
    }
    
    fileprivate func setupBackSnapshotView() {
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            unwrappedSnapshotView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            unwrappedSnapshotView.layer.position = CGPoint(x: 0, y: unwrappedSnapshotView.layer.position.y)
        }
    }
}
