//
//  KolodaBaseView.swift
//  Cards
//
//  Created by Szabolcs Tóth on 21/07/15.
//  Copyright (c) 2015 Kapaza. All rights reserved.
//

import UIKit

public class KolodaBaseView: UIView, KolodaReusableProtocol {
    
    private func setup(#identifier: String) {
        self.identifier = identifier
    }
    
    // MARK: KolodaReusableProtocol
    
    public var identifier = "KolodaBaseView"
    public func prepareForReuse() {}
}

// MARK: -

public class KolodaContentView: KolodaBaseView {

    // MARK: Internal initialization stuffs

    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setup(identifier: "KolodaContentView")
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup(identifier: "KolodaContentView")
    }
}

// MARK: -

public class KolodaOverlayView: KolodaBaseView {
    
    // MARK: The irection related stuffs
    
    private var _direction = KolodaDirection.None
    public internal(set) var direction: KolodaDirection {
        get {
            return _direction
        }
        
        set {
            _direction = newValue
            directionDidChange()
        }
    }
    
    public func directionDidChange() {}

    // MARK: Internal initialization stuffs
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        
        setup(identifier: "KolodaOverlayView")
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup(identifier: "KolodaOverlayView")
    }
}
