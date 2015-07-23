//
//  KolodaRecycler.swift
//  Cards
//
//  Created by Szabolcs Tóth on 21/07/15.
//  Copyright (c) 2015 Kapaza. All rights reserved.
//

import UIKit

public protocol KolodaReusableProtocol {
    var identifier: String { get set }
    func prepareForReuse()
}

internal class KolodaRecycler: NSObject {
   
    private var unusedItems = Set<KolodaBaseView>()
    private var registeredNibs: [String : UINib] = [String : UINib]()
    private var registeredClasses: [String : KolodaBaseView.Type] = [String : KolodaBaseView.Type]()
    
    internal func register(#nib: UINib, forObjectReuseIdentifier identifier: String) {
        registeredNibs[identifier] = nib
        
        if let index = registeredClasses.indexForKey(identifier) {
            registeredClasses.removeValueForKey(identifier)
        }
    }
    
    internal func register(#objectClass: KolodaBaseView.Type, forObjectReuseIdentifier identifier: String) {
        registeredClasses[identifier] = objectClass
        
        if let index = registeredNibs.indexForKey(identifier) {
            registeredNibs.removeValueForKey(identifier)
        }
    }
    
    internal func enqueue(#object: KolodaBaseView) {
        unusedItems.insert(object)
    }
    
    internal func dequeue(#identifier: String) -> KolodaBaseView {
        let unusedItem = filter(unusedItems) { $0.identifier == identifier }.last
        
        if let item = unusedItem {
            unusedItems.remove(item)
            item.prepareForReuse()
            return item
        }
        
        if let index = registeredClasses.indexForKey(identifier) {
            let objectClass = registeredClasses[index].1
            let item = objectClass(frame: CGRectZero)
            item.prepareForReuse()
            return item
        }
        
        if let index = registeredNibs.indexForKey(identifier) {
            let nib = registeredNibs[identifier]
            let array = nib!.instantiateWithOwner(nil, options: nil)
            let item = array[0] as! KolodaBaseView
            item.prepareForReuse()
            return item
        }
        
        NSException(name:"Error", reason:"Boooommm, could not instantiate a new object for the \"\(identifier)\" identifier.", userInfo:nil).nonReturningRaise()
    }
    
    internal func removeUnusedItems() {
        unusedItems.removeAll(keepCapacity: true)
    }
}

internal extension NSException {
    
    @noreturn internal func nonReturningRaise() {
        raise()
        abort()
    }
}
