//
//  Card.swift
//  Cards
//
//  Created by Szabolcs Tóth on 19/07/15.
//  Copyright (c) 2015 Kapaza. All rights reserved.
//

import pop
import UIKit

public enum KolodaDirection: Int {
    case None = 0
    case Left = -1
    case Right = 1
}

internal protocol KolodaCardViewProtocol: NSObjectProtocol {
    func cardTapped(card: KolodaCardView)
    func cardReleased(card: KolodaCardView)
    func cardMovementStarted(card: KolodaCardView)
    func card(card: KolodaCardView, draggedWithPercent percent: CGFloat, inDirection direction: KolodaDirection)
    func card(card: KolodaCardView, swipedInDirection direction: KolodaDirection)
}

private let rotationMax: CGFloat = 1.0
private let defaultRotationAngle = CGFloat(M_PI) / 10.0
private let scaleMin: CGFloat = 0.8
private let resetAnimationDuration: NSTimeInterval = 0.2

public class KolodaCardView: KolodaBaseView {
    
    internal weak var delegate: KolodaCardViewProtocol?
    
    public internal(set) var contentView: KolodaContentView?
    public internal(set) var overlayView: KolodaOverlayView?
    
    internal var number: Int!
    private var margin: CGFloat!
    private var distance: CGPoint!
    private var originalCenter: CGPoint!
    private var acceptsAction: Bool!
    private var rotationDirection: KolodaDirection!

    override public var frame: CGRect {
        didSet {
            margin = floor(CGRectGetWidth(frame) / 2.0)
        }
    }
    
    required public init(frame: CGRect) {
        super.init(frame: frame)
        
        setupCard()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setupCard()
    }
    
    // MARK: - Reusability
    
    override public func prepareForReuse() {
        contentView = nil
        overlayView = nil

        setDefaultValues()
    }
    
    // MARK: - View configurations
    
    internal func configure(content: KolodaContentView, overlay: KolodaOverlayView?) {
        removeViews()
        addConentView(content)

        if let unwrappedOverlay = overlay {
            addOverLayView(unwrappedOverlay)
        }
    }
    
    internal func removeViews() -> (content: KolodaContentView?, overlay: KolodaOverlayView?) {
        let views = (contentView, overlayView)
        
        if let unwrappedContent = contentView {
            contentView!.removeFromSuperview()
            contentView = nil
        }
        
        if let unwrappedOverlay = overlayView {
            overlayView!.removeFromSuperview()
            overlayView = nil
        }
        
        return views
    }
    
    private func addConentView(content: KolodaContentView) {
        contentView = content
        addToCardView(contentView!)
    }
    
    private func addOverLayView(overlay: KolodaOverlayView) {
        overlayView = overlay
        overlayView!.alpha = 0.0
        addToCardView(overlayView!)
    }
    
    private func addToCardView(view: UIView) {
        view.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(view)
        NSLayoutConstraint.fit(parent: self, child: view)
    }
    
    // MARK: - Private
    
    private func setDefaultValues() {
        number = -1
        margin = 0.0
        distance = CGPointMake(0.0, 0.0)
        originalCenter = CGPointMake(0.0, 0.0)
        acceptsAction = true
        rotationDirection = KolodaDirection.None
    }
    
    private func updateOverlayWithProgress(percent: CGFloat) {
        overlayView?.direction = 0.0 < percent ? .Right : .Left
        let overlayStrength = min(fabs(2 * percent), 1.0)
        overlayView?.alpha = overlayStrength
    }
    
    private func setupCard() {
        identifier = "KolodaCardView"
        
        setDefaultValues()
        addGestures()
    }
    
    private func determineDirection() -> KolodaDirection {
        let direction: KolodaDirection
        if distance.x < -margin {
            direction = .Left
        } else if margin < distance.x {
            direction = .Right
        } else {
            direction = .None
        }
        
        return direction
    }
    
    // MARK: - Gesture handlers & related function
    
    private func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("panGestureHandler:"))
        addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("tapGestureHandler:"))
        addGestureRecognizer(tapGesture)
    }
    
    func tapGestureHandler(recognizer: UITapGestureRecognizer) {
        delegate?.cardTapped(self)
    }
    
    func panGestureHandler(recognizer: UIPanGestureRecognizer) {
        let location = recognizer.locationInView(self)
        distance = recognizer.translationInView(self)
        
        switch recognizer.state {
        case .Began:
            panBegan(location: location)
            break
        case .Changed:
            panChanged(location: location)
            break
        case .Ended, .Failed, .Cancelled:
            panEnded(location: location)
            break
        default:
            break
        }
    }
    
    // MARK: - Individual gesture states
    
    private func panBegan(#location: CGPoint) {
        acceptsAction = false
        layer.shouldRasterize = true
        originalCenter = center
        rotationDirection = floor(CGRectGetHeight(frame) / 2.0) <= location.y ? .Left : .Right
        
        delegate?.cardMovementStarted(self)
    }
    
    private func panChanged(#location: CGPoint) {
        let rotationStrength = min(distance.x / CGRectGetWidth(frame), rotationMax)
        let rotationAngle = CGFloat(rotationDirection.rawValue) * defaultRotationAngle * rotationStrength
        let scaleStrength = 1 - ((1 - scaleMin) * fabs(rotationStrength))
        let scale = max(scaleStrength, scaleMin)
        
        layer.rasterizationScale = scale * UIScreen.mainScreen().scale
        
        let rotationtransform = CGAffineTransformMakeRotation(rotationAngle)
        let scaleTransform = CGAffineTransformScale(rotationtransform, scale, scale)
        
        self.transform = scaleTransform
        center = CGPointMake(originalCenter.x + distance.x, originalCenter.y + distance.y)
        
        let percent = min(fabs(distance.x * 100 / CGRectGetWidth(frame)), 100)
        updateOverlayWithProgress(distance.x / CGRectGetWidth(frame))
        
        let direction: KolodaDirection
        if distance.x < 0.0 {
            direction = .Left
        } else if 0.0 < distance.x {
            direction = .Right
        } else {
            direction = .None
        }
        
        delegate?.card(self, draggedWithPercent: percent, inDirection: direction)
    }
    
    private func panEnded(#location: CGPoint) {
        let direction = determineDirection()
        if .None == direction {
            animateToOriginalPlace()
        }
        else {
            animateToSide(direction: direction)
        }
    }
    
    // MARK: - Animations
    
    private func animateToOriginalPlace() {
        userInteractionEnabled = false
        delegate?.cardReleased(self)
        
        springBackToTheMiddle()
        animateBackToDefaultValues()
    }
    
    private func springBackToTheMiddle() {
        let springAnimation = POPSpringAnimation(propertyNamed: kPOPLayerPosition)
        springAnimation.toValue = NSValue(CGPoint: originalCenter)
        springAnimation.springBounciness = 10.0
        springAnimation.springSpeed = 20.0
        springAnimation.completionBlock = { (_, _) in
            self.userInteractionEnabled = true
            self.acceptsAction = true
            self.layer.shouldRasterize = false
        }
        
        pop_addAnimation(springAnimation, forKey: "ResetCardPosition")
    }
    
    private func animateBackToDefaultValues() {
        overlayView?.direction = .None

        UIView.animateWithDuration(resetAnimationDuration, delay: 0.0, options: .CurveLinear, animations: {
            self.transform = CGAffineTransformMakeRotation(0)
            self.overlayView?.alpha = 0
            self.layoutIfNeeded()
        }, completion: { _ in
                self.transform = CGAffineTransformIdentity
        })
    }
    
    private func animateToSide(#direction: KolodaDirection) {
        let screenWidth = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let valueY = originalCenter.y + distance.y
        let valueX = direction == .Left ? -screenWidth : 2 * screenWidth
        let destination = CGPointMake(valueX, valueY)
                
        animate(direction: direction) { _ in
            self.center = destination
        }
    }
    
    private func animate(#direction: KolodaDirection, animationBlock: (() -> Void)) {
        userInteractionEnabled = false
        acceptsAction = false
        
        overlayView?.direction = direction
        overlayView?.alpha = 1.0
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseIn, animations: animationBlock, completion: { _ in
            self.userInteractionEnabled = true
            self.acceptsAction = true
            
            self.layer.shouldRasterize = false
            self.delegate?.card(self, swipedInDirection: direction)
        })
    }
    
    // MARK: - Swipe actions
    
    internal func swipe(direction: KolodaDirection) {
        if true == acceptsAction && .None != direction {
            let modifier: CGFloat = .Left == direction ? -1.0 : 2.0
            let desination = CGPoint(x: CGRectGetWidth(UIScreen.mainScreen().bounds) * modifier, y: center.y)
            let transformation = CGAffineTransformMakeRotation(CGFloat(direction.rawValue) * CGFloat(M_PI_4))
            
            animate(direction: direction, animationBlock: { _ in
                self.center = desination
                self.transform = transformation
            })
        }
    }
}

private extension NSLayoutConstraint {
    
    private class func fit(#parent: UIView, child: UIView) {
        let top = NSLayoutConstraint(item: child, attribute: .Top, relatedBy: .Equal, toItem: parent, attribute: .Top, multiplier: 1.0, constant: 0.0)
        let leading = NSLayoutConstraint(item: child, attribute: .Leading, relatedBy: .Equal, toItem: parent, attribute: .Leading, multiplier: 1.0, constant: 0.0)
        let width = NSLayoutConstraint(item: child, attribute: .Width, relatedBy: .Equal, toItem: parent, attribute: .Width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: child, attribute: .Height, relatedBy: .Equal, toItem: parent, attribute: .Height, multiplier: 1.0, constant: 0.0)
        parent.addConstraints([top, leading, width, height])
    }
}
