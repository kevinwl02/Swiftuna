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
    
    :param: swiftuna The swiftuna object that initiated the call
    :param: option   The option that was selected
    :param: index    The index of the selected option
    
    :returns: Void
    */
    func swiftuna(swiftuna : Swiftuna, didSelectOption option : SwiftunaOption, index : Int)
    
    /**
    Optional method to be called after selection of an option.
    Must indicate if the options view should be dismissed after selection.
    The default value is true.
    
    :param: swiftuna The swiftuna object that initiated the call
    :param: option   The option that was selected
    :param: index    The index of the selected option
    
    :returns: Wether the options view should be dismissed or not
    */
    optional func swiftuna(swiftuna : Swiftuna, shouldDismissAfterSelectionOfOption option : SwiftunaOption, index : Int) -> Bool
}

/**
*  Decorator class that sets up a view with a swipe to open options
*  menu
*/
public class Swiftuna : NSObject {
    
    //MARK: Public Variables
    
    /// The reference delegate object
    public weak var delegate : SwiftunaDelegate?
    
    /// The view that is decorated with the options menu
    public unowned var targetView : UIView {
        get {
            return _targetView
        }
    }
    
    /// A tag to identify the Swiftuna instance
    public var tag : AnyObject?
    
    /// The options that are represented in the menu
    public var options : [SwiftunaOption] {
        get {
            return _options
        }
    }
    
    /// Indicates if swiping the viw will trigger the options menu.
    /// By default it is true
    public var swipeEnabled : Bool = true
    
    /// The background color of the view that is displayed when the
    /// options menu is triggered. Should not be a translucent color.
    public var backgroundViewColor : UIColor? {
        get {
            return backgroundView.backgroundColor
        }
        set {
            backgroundView.backgroundColor = newValue
        }
    }
    
    /// The current spacing in between options. It defaults to
    /// kOptionsHorizontalSpacing
    public var optionsSpacing : CGFloat
    
    //MARK: Private variables
    
    private unowned var _targetView : UIView
    private var _options : [SwiftunaOption]
    private var optionsView : UIView
    private var didShowMenu : Bool = false
    private var snapshotView : UIImageView?
    private var dismissView : UIButton
    private var backgroundView : UIView
    
    //MARK: Initializers
    
    /**
    The main initializer of the decorator which sets up its initial properties,
    including default values.
    
    :param: targetView The view to which the swipe menu will be attached
    :param: options    The options to display in the menu. The first option is
    displayed to the left.
    
    :returns: The initialized Swiftuna instance
    */
    public init(targetView : UIView, options : [SwiftunaOption]) {
        
        _targetView = targetView
        optionsView = UIView()
        dismissView = UIButton()
        backgroundView = UIView()
        backgroundView.backgroundColor = UIColor.blackColor()
        _options = options
        optionsSpacing = kOptionsHorizontalSpacing
        
        super.init()
    }
    
    //MARK: Public methods
    
    /**
    This does the actual attaching and layout of the swipe menu.
    This should always be called after all configuration has been made.
    */
    public func attach() {
        
        setupBackgroundView()
        setupDismissView()
        setupOptionsView()
        setupGestureRecognizer()
        attachToView()
    }
    
    /**
    Detaches the swipe menu from the target view.
    */
    public func detach() {
        
        removeViews()
        optionsView.removeFromSuperview()
        
        objc_setAssociatedObject(targetView, kAssociationKey, nil, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
    /**
    This method resets the swipe menu to its original and untriggered
    state.
    */
    public func reset() {
        
        didShowMenu = false
        self.dismissView.hidden = true
        self.optionsView.hidden = true
        self.backgroundView.hidden = true
        self.snapshotView?.removeFromSuperview()
        
        for optionView in optionsView.subviews as [UIView] {
            optionView.transform = CGAffineTransformIdentity
        }
    }
    
    /**
    This method updated the menu view with new options
    
    :param: options The new options to show
    */
    public func refreshWithNewOptions(options : [SwiftunaOption]) {
     
        _options = options
        optionsView.removeFromSuperview()
        optionsView = UIView()
        setupOptionsView()
    }
    
    //MARK: Private methods - Setup
    
    private func setupOptionsView() {
        
        optionsView.frame = CGRectMake(0, 0, 0, 100)
        optionsView.hidden = true
        optionsView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.addSubview(optionsView)
        
        let optionsViewWidth = optionsViewCalculatedWidth()
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[optionsView]|",
            options: NSLayoutFormatOptions.DirectionLeadingToTrailing,
            metrics: nil,
            views: ["optionsView": optionsView]))
        NSLayoutConstraint(item: optionsView,
            attribute: NSLayoutAttribute.Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1,
            constant: optionsViewWidth).active = true
        NSLayoutConstraint(item: optionsView, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: targetView, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: 0).active = true
        
        setupOptionsWithOptionsViewWidth(optionsViewWidth)
    }
    
    private func setupOptionsWithOptionsViewWidth(optionsViewWidth : CGFloat) {

        var iterationCounter : Int = 0
        var previousOption : UIButton?
        
        for option in options {
            
            let optionItem = UIButton()
            optionItem.tag = iterationCounter
            optionItem.addTarget(self, action: "optionSelected:", forControlEvents: UIControlEvents.TouchUpInside)
            optionItem.setTranslatesAutoresizingMaskIntoConstraints(false)
            optionsView.addSubview(optionItem)
            optionItem.setBackgroundImage(option.image, forState: UIControlState.Normal)
            
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: optionsView, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0).active = true
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: option.size.width).active = true
            NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1, constant: option.size.height).active = true
            
            if previousOption != nil {
            
                NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: previousOption, attribute: NSLayoutAttribute.Right, multiplier: 1, constant: optionsSpacing).active = true
            }
            else {
            
                NSLayoutConstraint(item: optionItem, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: optionsView, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: optionsViewWidth).active = true
            }
        
            previousOption = optionItem
            iterationCounter++
        }
    }
    
    private func optionsViewCalculatedWidth() -> CGFloat {
        
        var width : CGFloat = 0.0
        for option in options {
            width += option.size.width
        }
        
        return width
    }
    
    private func setupDismissView() {
        
        dismissView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.addSubview(dismissView)
        let dismissViewLayoutDictionary = ["dismissView": dismissView]
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[dismissView]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: dismissViewLayoutDictionary))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[dismissView]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: dismissViewLayoutDictionary))
        
        dismissView.backgroundColor = UIColor.clearColor()
        dismissView.addTarget(self, action: "hideOptionsView", forControlEvents: UIControlEvents.TouchUpInside)
        dismissView.hidden = true
    }
    
    private func setupBackgroundView() {
    
        backgroundView.setTranslatesAutoresizingMaskIntoConstraints(false)
        targetView.addSubview(backgroundView)
        
        let backgroundViewDictionary = ["backgroundView": backgroundView]
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundView]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: backgroundViewDictionary))
        NSLayoutConstraint.activateConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundView]|", options: NSLayoutFormatOptions.DirectionLeadingToTrailing, metrics: nil, views: backgroundViewDictionary))
        
        backgroundView.hidden = true
    }
    
    private func setupGestureRecognizer() {
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "viewSwiped:")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Left
        targetView.addGestureRecognizer(swipeGestureRecognizer)
        targetView.userInteractionEnabled = true
    }
    
    private func attachToView() {
        
        objc_setAssociatedObject(targetView, kAssociationKey, self, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
    //MARK: Private methods - Interaction
    
    func viewSwiped(swipeGestureRecognizer : UISwipeGestureRecognizer) {
        
        if swipeEnabled && !didShowMenu {
            
            didShowMenu = true
            setupSnapshotView()
            backgroundView.hidden = false
            dismissView.hidden = false
            optionsView.hidden = false
            
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.transformSnapshotView()
            }, completion: nil)
            
            var iteratorCount = 0.0
            for optionView in optionsView.subviews {
                animateOption(optionView as UIButton, delay: iteratorCount * 0.1)
                iteratorCount++
            }
        }
    }
    
    private func removeViews() {
        
        optionsView.removeFromSuperview()
        backgroundView.removeFromSuperview()
        dismissView.removeFromSuperview()
    }
    
    func hideOptionsView() {
        
        if !didShowMenu {
            return
        }
        
        didShowMenu = false
        
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.transformBackSnapshotView()
        }) { (completed) -> Void in
            if completed {
                self.dismissView.hidden = true
                self.optionsView.hidden = true
                self.backgroundView.hidden = true
                self.snapshotView!.removeFromSuperview()
            }
        }
        
        var iteratorCount = 0.0
        for optionView in optionsView.subviews {
            animateBackOption(optionView as UIButton, delay: (Double(options.count) - iteratorCount - 1.0) * 0.1)
            iteratorCount++
        }
    }
    
    func optionSelected(optionItem : UIButton) {
        
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
    
    private func animateOption(option : UIButton, delay : NSTimeInterval) {
        
        let width = optionsView.bounds.size.width + optionsSpacing * CGFloat(options.count)
        option.alpha = 0
        
        UIView.animateWithDuration(0.4, delay: delay, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            option.transform = CGAffineTransformTranslate(option.transform, -width, 0)
            option.alpha = 1
        }, completion: nil)
    }
    
    private func animateBackOption(option : UIButton, delay : NSTimeInterval) {
        
        UIView.animateWithDuration(0.4, delay: delay, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            option.transform = CGAffineTransformIdentity
            option.alpha = 0
            }, completion: nil)
    }
    
    private func setupSnapshotView() {
        
        UIGraphicsBeginImageContextWithOptions(targetView.frame.size, targetView.opaque, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        targetView.layer.renderInContext(context)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        snapshotView = UIImageView(frame: targetView.bounds)
        snapshotView!.image = snapshotImage
        snapshotView!.layer.allowsEdgeAntialiasing = true
        
        backgroundView.addSubview(snapshotView!)
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            unwrappedSnapshotView.layer.anchorPoint = CGPointMake(0, 0.5)
            unwrappedSnapshotView.layer.position = CGPointMake(unwrappedSnapshotView.layer.position.x - unwrappedSnapshotView.layer.bounds.size.width / 2, unwrappedSnapshotView.layer.position.y)
        }
    }
    
    private func transformSnapshotView() {
    
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            var identity = CATransform3DIdentity
            identity.m34 = 0.001
            unwrappedSnapshotView.layer.transform = CATransform3DRotate(identity, CGFloat(-20 / 180 * M_PI), 0, 1, 0)
        }
    }
    
    private func transformBackSnapshotView() {
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {

            unwrappedSnapshotView.layer.transform = CATransform3DIdentity
        }
    }
    
    private func setupBackSnapshotView() {
        
        if let unwrappedSnapshotView : UIImageView = snapshotView {
            unwrappedSnapshotView.layer.anchorPoint = CGPointMake(0.5, 0.5)
            unwrappedSnapshotView.layer.position = CGPointMake(0, unwrappedSnapshotView.layer.position.y)
        }
    }
}
