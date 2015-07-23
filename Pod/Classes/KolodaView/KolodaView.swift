//
//  CardHolder.swift
//  Cards
//
//  Created by Szabolcs Tóth on 19/07/15.
//  Copyright (c) 2015 Kapaza. All rights reserved.
//

import pop
import UIKit

public protocol KolodaDataSource: NSObjectProtocol {
    func numberOfCards(koloda: KolodaView) -> Int
    func koloda(koloda: KolodaView, viewForCardAtIndex index: Int) -> KolodaContentView
    func koloda(koloda: KolodaView, overlayForCardAtIndex index: Int) -> KolodaOverlayView?
}

public protocol KolodaDelegate: NSObjectProtocol {
    func koloda(koloda: KolodaView, didSwipedCardAtIndex index: Int, inDirection direction: KolodaDirection)
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: Int)
    func kolodaDidRunOutOfCards(koloda: KolodaView)
    func kolodaDidRevertCard(koloda: KolodaView)
}

public protocol KolodaInteractionDelegate: NSObjectProtocol {
    func koloda(koloda: KolodaView, interactionStartedWithCardAtIndex index: Int)
    func koloda(koloda: KolodaView, didDragCardWithProgress percent: CGFloat, inDirection direction: KolodaDirection)
    func koloda(koloda: KolodaView, interactionEndedWithCardAtIndex index: Int)
}

public class KolodaView: UIView, KolodaCardViewProtocol {
    
    static private let SimpleFrameAnimationKey = "SimpleFrameAnimationKey"
    static private let RevertCardAnimationKey = "RevertCardAnimationKey"
    static private let ScaleAppearAnimationKey = "ScaleAppearAnimationKey"
    static private let AlphaAppearAnimationKey = "AlphaAppearAnimationKey"
    static private let KolodaCardViewKey = "KolodaCardViewKey"
    
    public weak var dataSource: KolodaDataSource? {
        didSet {
            if let unwrappedDataSource = dataSource {
                setupCards()
            }
        }
    }
    public weak var delegate: KolodaDelegate?
    public weak var interactionDelegate: KolodaInteractionDelegate?
    
    private var _enabled = true
    public var enabled: Bool {
        get {
            return _enabled
        }
        
        set {
            _enabled = newValue
            userInteractionEnabled = _enabled
        }
    }
    public var animatedAppearing = true
    public internal(set) var currentCardNumber = 0
    public internal(set) var visibleCards = [KolodaCardView]()
    
    private let recycler = KolodaRecycler()
    private let visualSettings = KolodaVisualSettings()
    private let animationSettings = KolodaAnimationSettings()
    private var countOfVisibleCards = 3
    private var animating = false
    private var configured = false

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        if !configured {
                        
            if visibleCards.isEmpty {
                reloadData()
            }
            else {
                layoutCards()
            }
            
            configured = true
        }
    }
    
    // MARK: - Recycling views
    
    public func dequeueReusableView(#identifier: String) -> KolodaBaseView? {
        return recycler.dequeue(identifier: identifier)
    }
    
    public func register(#nib: UINib, forObjectReuseIdentifier identifier: String) {
        recycler.register(nib: nib, forObjectReuseIdentifier: identifier)
    }
    
    public func register(#objectClass: KolodaBaseView.Type, forObjectReuseIdentifier identifier: String) {
        recycler.register(objectClass: objectClass, forObjectReuseIdentifier: identifier)
    }
    
    // MARK: - Private
    
    private func setup() {
        recycler.register(objectClass: KolodaCardView.self, forObjectReuseIdentifier: KolodaView.KolodaCardViewKey)
    }
    
    private func setupCards() {
        let remeiningCards = numberOfCards() - currentCardNumber
        if 0 < remeiningCards {
            
            let countOfNeededCards = min(countOfVisibleCards, remeiningCards)
            for index in 0..<countOfNeededCards {
                
                let cardView = createCard(index: index)
                cardView.frame = frameForCardAtIndex(index)
                cardView.alpha = isVisible(index: index) ? visualSettings.alphaValueOpaque : visualSettings.alphaValueSemiTransparent
                cardView.userInteractionEnabled = isVisible(index: index)
                
                visibleCards.append(cardView)
                if isVisible(index: index) {
                    addSubview(cardView)
                }
                else {
                    insertSubview(cardView, belowSubview: visibleCards[index - 1])
                }
            }
        }
    }
    
    private func isVisible(#index: Int) -> Bool {
        return 0 == index
    }
    
    private func layoutCards() {
        for (index, card) in enumerate(self.visibleCards) {
            card.frame = frameForCardAtIndex(index)
        }
    }
    
    private func frameForCardAtIndex(index: Int) -> CGRect {
        let bottomOffset = CGFloat(0.0)
        
        let topOffset = visualSettings.backgroundCardsTopMargin * CGFloat(countOfVisibleCards - 1)
        
        let xOffset = visualSettings.backgroundCardsLeftMargin * CGFloat(index)
        
        let scalePercent = visualSettings.backgroundCardsScalePercent
        let width = CGRectGetWidth(self.frame) * pow(scalePercent, CGFloat(index))
        let height = (CGRectGetHeight(self.frame) - bottomOffset - topOffset) * pow(scalePercent, CGFloat(index))
        
        let multiplier: CGFloat = 0 < index ? 1.0 : 0.0
        let previousCardFrame = 0 < index ? frameForCardAtIndex(max(index - 1, 0)) : CGRectZero
        let yOffset = (CGRectGetHeight(previousCardFrame) - height + previousCardFrame.origin.y + visualSettings.backgroundCardsTopMargin) * multiplier
        
        let frame = CGRect(x: xOffset, y: yOffset, width: width, height: height)
        
        return frame
    }
    
    private func resetVisibleCardsTransparency() {
        for index in 1..<visibleCards.count {
            let card = visibleCards[index]
            card.alpha = visualSettings.alphaValueSemiTransparent
        }
    }
    
    private func createCard(#index: Int) -> KolodaCardView {
        let contentView = contentViewForIndex(index)
        let overlayView = overlayViewForIndex(index)
        
        let card = recycler.dequeue(identifier: KolodaView.KolodaCardViewKey) as! KolodaCardView
        card.delegate = self
        card.configure(contentView, overlay: overlayView)
        card.number = index
        
        return card
    }
    
    private func createSimpleFrameAnimation(frame: CGRect) -> POPBasicAnimation {
        let animation = POPBasicAnimation(propertyNamed: kPOPViewFrame)
        animation.duration = visualSettings.backgroundCardFrameAnimationDuration
        animation.toValue = NSValue(CGRect: frame)
        
        return animation
    }
    
    private func recycle(#card: KolodaCardView) {
        let views = card.removeViews()
        recycler.enqueue(object: card)
        
        if let content = views.content {
            recycler.enqueue(object: content)
        }
        
        if let overlay = views.overlay {
            recycler.enqueue(object: overlay)
        }
        
        card.removeFromSuperview()
    }
    
    // MARK: - Getting values from delegate
    
    private func numberOfCards() -> Int {
        return dataSource?.numberOfCards(self) ?? 0
    }
    
    private func contentViewForIndex(index: Int) -> KolodaContentView {
        let contentView = dataSource?.koloda(self, viewForCardAtIndex: index)
        
        if nil == contentView {
            NSException(name:"Error", reason:"DataSource or the content view is nil", userInfo:nil).raise()
        }
        
        return contentView!
    }
    
    private func overlayViewForIndex(index: Int) -> KolodaOverlayView? {
        return dataSource?.koloda(self, overlayForCardAtIndex: index)
    }
    
    // MARK: - Movement related functions
    
    private func moveOtherCardsWithFinishPercent(percent: CGFloat) {
        if visibleCards.count > 1 {
            
            var previousFrame: CGRect?
            
            for index in 1..<visibleCards.count {
                
                if nil == previousFrame {
                    previousFrame = frameForCardAtIndex(index - 1)
                }
                
                let currentFrame = frameForCardAtIndex(index)
                
                let frame = calculateFrame(current: currentFrame, previous: previousFrame!, percent: percent)
                let card = visibleCards[index]
                card.frame = frame
                card.layoutIfNeeded()
                
                if 1 == index {
                    card.alpha = visualSettings.alphaValueOpaque
                }
                
                previousFrame = currentFrame
            }
        }
    }
    
    private func calculateFrame(#current: CGRect, previous: CGRect, percent: CGFloat) -> CGRect {
        let movementY = (CGRectGetMinY(current) - CGRectGetMinY(previous)) * (percent / 100)
        let valueY = CGRectGetMinY(current) - movementY
        
        let movementX = (CGRectGetMinX(previous) - CGRectGetMinX(current)) * (percent / 100)
        let valueX = CGRectGetMinX(current) + movementX
        
        let widthScale = (CGRectGetWidth(previous) - CGRectGetWidth(current)) * (percent / 100)
        let valueWidth = CGRectGetWidth(current) + widthScale
        
        let heightScale = (CGRectGetHeight(previous) - CGRectGetHeight(current)) * (percent / 100)
        let valueHeight = CGRectGetHeight(current) + heightScale

        let frame = CGRect(x: valueX, y: valueY, width: valueWidth, height: valueHeight)
        return frame
    }
    
    // MARK: - Animations
    
    private func applyAppearAnimation() {
        animating = true
        userInteractionEnabled = false
        
        let scaleAnimation = POPBasicAnimation(propertyNamed: kPOPViewScaleXY)
        scaleAnimation.duration = animationSettings.kolodaAppearScaleAnimationDuration
        scaleAnimation.fromValue = NSValue(CGPoint: animationSettings.kolodaAppearScaleAnimationFromValue)
        scaleAnimation.toValue = NSValue(CGPoint: animationSettings.kolodaAppearScaleAnimationToValue)
        scaleAnimation.completionBlock = { (_, _) in
            self.userInteractionEnabled = true
            self.animating = false
        }
        
        let alphaAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        alphaAnimation.duration = animationSettings.kolodaAppearAlphaAnimationDuration
        alphaAnimation.fromValue = NSNumber(float: Float(animationSettings.kolodaAppearAlphaAnimationFromValue))
        alphaAnimation.toValue = NSNumber(float: Float(animationSettings.kolodaAppearAlphaAnimationToValue))
        
        pop_addAnimation(alphaAnimation, forKey: KolodaView.AlphaAppearAnimationKey)
        pop_addAnimation(scaleAnimation, forKey: KolodaView.ScaleAppearAnimationKey)
    }
    
    private func applyRevertAnimation(card: KolodaCardView) {
        animating = true
        
        let revertAnimation = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
        revertAnimation.duration = animationSettings.revertCardAnimationDuration
        revertAnimation.fromValue =  NSNumber(float: Float(animationSettings.revertCardAnimationFromValue))
        revertAnimation.toValue = NSNumber(float: Float(animationSettings.revertCardAnimationToValue))
        revertAnimation.completionBlock = { (_, _) in
            self.animating = false
        }
        
        card.pop_addAnimation(revertAnimation, forKey: KolodaView.RevertCardAnimationKey)
    }
    
    // MARK: - Draggable delegate
    
    func cardTapped(card: KolodaCardView) {
        if let foundIndex = find(visibleCards, card) {
            let index = currentCardNumber + foundIndex
            delegate?.koloda(self, didSelectCardAtIndex: index)
        }
        else {
            NSException(name:"Error", reason:"Card not found in the list of visible cards", userInfo:nil).raise()
        }
    }
    
    func cardReleased(card: KolodaCardView) {
        enabled = false
        interactionDelegate?.koloda(self, interactionEndedWithCardAtIndex: currentCardNumber)
        
        if 1 < visibleCards.count {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveLinear, animations: {
                self.moveOtherCardsWithFinishPercent(0)
            }, completion: { _ in
                self.resetVisibleCardsTransparency()
                self.animating = false
                self.enabled = true
            })
        }
        else {
            animating = false
            enabled = true
        }
    }
    
    func cardMovementStarted(card: KolodaCardView) {
        animating = true
        interactionDelegate?.koloda(self, interactionStartedWithCardAtIndex: currentCardNumber)
    }
    
    func card(card: KolodaCardView, draggedWithPercent percent: CGFloat, inDirection direction: KolodaDirection) {
        moveOtherCardsWithFinishPercent(percent)
        interactionDelegate?.koloda(self, didDragCardWithProgress: percent, inDirection: direction)
    }
    
    func card(card: KolodaCardView, swipedInDirection direction: KolodaDirection) {
        enabled = false
        interactionDelegate?.koloda(self, interactionEndedWithCardAtIndex: currentCardNumber)
        
        recycle(card: card)
        visibleCards.removeAtIndex(0)
        currentCardNumber += 1
        
        let totalCards = numberOfCards()
        let shownCardsCount = currentCardNumber + countOfVisibleCards
        if shownCardsCount - 1 < totalCards {
            insertNewCardInStack(shownCardsCount - 1)
        }
        
        if !visibleCards.isEmpty {
            moveCardsInDeckAfterSwipe(direction)
        }
        else {
            didSwipeLastCard(direction)
        }
    }
    
    // MARK: - Draggable delegate related functions
    
    private func insertNewCardInStack(index: Int) {
        let cardView = createCard(index: index)
        cardView.hidden = true
        cardView.userInteractionEnabled = true

        insertSubview(cardView, belowSubview: visibleCards.last!)
        visibleCards.append(cardView)
    }
    
    private func moveCardsInDeckAfterSwipe(direction: KolodaDirection) {
        for (index, card) in enumerate(visibleCards) {
            let animation = createSimpleFrameAnimation(frameForCardAtIndex(index))

            if 0 == index {
                animation.completionBlock = { (_, _) in
                    self.visibleCards.last?.hidden = false
                    self.animating = false
                    self.enabled = true
                    self.delegate?.koloda(self, didSwipedCardAtIndex: self.currentCardNumber - 1, inDirection: direction)
                }
                card.alpha = visualSettings.alphaValueOpaque
            }
            else {
                card.alpha = visualSettings.alphaValueSemiTransparent
            }
            
            card.userInteractionEnabled = isVisible(index: index)
            card.pop_addAnimation(animation, forKey: KolodaView.SimpleFrameAnimationKey)
        }
    }
    
    private func didSwipeLastCard(direction: KolodaDirection) {
        animating = false
        enabled = true

        delegate?.koloda(self, didSwipedCardAtIndex: currentCardNumber - 1, inDirection: direction)
        delegate?.kolodaDidRunOutOfCards(self)
    }
    
    // MARK: - Revert action & related functions
    
    public func revertLastCard() {
        if canRevertCard() {
            
            let remainingCards = numberOfCards() - currentCardNumber
            if let lastCard = visibleCards.last where countOfVisibleCards <= remainingCards {
                lastCard.removeFromSuperview()
                visibleCards.removeLast()
            }
            
            currentCardNumber -= 1
            
            animateBackLastCard()
            moveCardsInDeckAfterRevert()
        }
    }
    
    private func canRevertCard() -> Bool {
        return 0 < currentCardNumber && false == animating
    }
    
    private func animateBackLastCard() {
        let card = createCard(index: currentCardNumber)
        card.frame = frameForCardAtIndex(0)
        card.alpha = visualSettings.alphaValueTransparent

        visibleCards.insert(card, atIndex: 0)
        addSubview(card)
        
        applyRevertAnimation(card)
    }
    
    private func moveCardsInDeckAfterRevert() {
        for index in 1..<visibleCards.count {
            let card = visibleCards[index]
            card.alpha = visualSettings.alphaValueSemiTransparent
            card.userInteractionEnabled = false

            let animation = createSimpleFrameAnimation(frameForCardAtIndex(index))
            card.pop_addAnimation(animation, forKey: KolodaView.SimpleFrameAnimationKey)
        }
    }
    
    // MARK: - Reload contents & related functions
    
    public func reloadData() {
        let totalCards = numberOfCards()
        if 0 == totalCards {
            return
        }
        
        if 0 == currentCardNumber {
            removeAllCards()
        }
        
        if 0 < totalCards - (currentCardNumber + visibleCards.count) {
            if !visibleCards.isEmpty {
                let missingCardsCount = min(countOfVisibleCards - visibleCards.count, totalCards - (currentCardNumber + 1))
                loadMissingCards(missingCardsCount, totalCards: totalCards)
            }
            else {
                setupCards()
                layoutCards()
                
                if animatedAppearing {
                    applyAppearAnimation()
                }
            }
        }
        else {
            for index in 0..<visibleCards.count {
                let contentView = contentViewForIndex(currentCardNumber + index)
                let overlayView = overlayViewForIndex(currentCardNumber + index)
                
                let card = visibleCards[index]
                card.configure(contentView, overlay: overlayView)
            }
        }
    }
    
    private func loadMissingCards(missingCardsCount: Int, totalCards: Int) {
        if 0 < missingCardsCount {
            let cardsToAdd = min(missingCardsCount, totalCards - currentCardNumber)
            for index in 1...cardsToAdd {
                let nextCardIndex = countOfVisibleCards - cardsToAdd + index - 1
                let nextCardView = KolodaCardView(frame: frameForCardAtIndex(index))
                
                nextCardView.alpha = visualSettings.alphaValueSemiTransparent
                nextCardView.delegate = self
                
                visibleCards.append(nextCardView)
                insertSubview(nextCardView, belowSubview: visibleCards[index - 1])
            }
        }
        
        for index in 0..<visibleCards.count {
            let contentView = contentViewForIndex(currentCardNumber + index)
            let overlayView = overlayViewForIndex(currentCardNumber + index)
            
            let card = visibleCards[index]
            card.configure(contentView, overlay: overlayView)
        }
    }
    
    // MARK: - Programmatic swipe
    
    public func swipe(direction: KolodaDirection) {
        if let cardOnTop = visibleCards.first where true == enabled && false == animating {
            animating = true
            
            cardOnTop.swipe(direction)
            
            if 1 < visibleCards.count {
                let nextCard = visibleCards[1]
                nextCard.alpha = visualSettings.alphaValueOpaque
            }
        }
    }
    
    // MARK: - Reset and reload
    
    public func removeAllCards() {
        for card in visibleCards {
            recycle(card: card)
        }
        
        currentCardNumber = 0
        visibleCards.removeAll(keepCapacity: true)
    }
    
    public func resetAndReload() {
        removeAllCards()
        reloadData()
    }
}







