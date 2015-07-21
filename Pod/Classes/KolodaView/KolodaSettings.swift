//
//  KolodaSettings.swift
//  Cards
//
//  Created by Szabolcs Tóth on 20/07/15.
//  Copyright (c) 2015 Kapaza. All rights reserved.
//

import UIKit

public protocol KolodaVisualSettingsProtocol {
    var backgroundCardFrameAnimationDuration: NSTimeInterval { get }
    var backgroundCardsTopMargin: CGFloat { get }
    var backgroundCardsLeftMargin: CGFloat { get }
    var backgroundCardsScalePercent: CGFloat { get }
    
    var alphaValueOpaque: CGFloat { get }
    var alphaValueSemiTransparent: CGFloat { get }
    var alphaValueTransparent: CGFloat { get }
}

public struct KolodaVisualSettings: KolodaVisualSettingsProtocol {
    public let backgroundCardFrameAnimationDuration = NSTimeInterval(0.2)
    public let backgroundCardsTopMargin = CGFloat(4.0)
    public let backgroundCardsLeftMargin = CGFloat(8.0)
    public let backgroundCardsScalePercent = CGFloat(0.95)
    
    public let alphaValueOpaque = CGFloat(1.0)
    public let alphaValueSemiTransparent = CGFloat(0.7)
    public let alphaValueTransparent = CGFloat(0.0)
}

public protocol KolodaAnimationSettingsProtocol {
    var revertCardAnimationDuration: NSTimeInterval { get }
    var revertCardAnimationFromValue: CGFloat { get }
    var revertCardAnimationToValue: CGFloat { get }
    
    var kolodaAppearScaleAnimationDuration: NSTimeInterval { get }
    var kolodaAppearScaleAnimationFromValue: CGPoint { get }
    var kolodaAppearScaleAnimationToValue: CGPoint { get }
    
    var kolodaAppearAlphaAnimationDuration: NSTimeInterval { get }
    var kolodaAppearAlphaAnimationFromValue: CGFloat { get }
    var kolodaAppearAlphaAnimationToValue: CGFloat { get }
}

public struct KolodaAnimationSettings: KolodaAnimationSettingsProtocol {
    public let revertCardAnimationDuration = NSTimeInterval(1.0)
    public let revertCardAnimationFromValue = CGFloat(0.0)
    public let revertCardAnimationToValue = CGFloat(1.0)
    
    public let kolodaAppearScaleAnimationDuration = NSTimeInterval(0.8)
    public let kolodaAppearScaleAnimationFromValue = CGPoint(x: 0.1, y: 0.1)
    public let kolodaAppearScaleAnimationToValue = CGPoint(x: 1.0, y: 1.0)
    
    public let kolodaAppearAlphaAnimationDuration = NSTimeInterval(0.8)
    public let kolodaAppearAlphaAnimationFromValue = CGFloat(0.0)
    public let kolodaAppearAlphaAnimationToValue = CGFloat(1.0)
}
