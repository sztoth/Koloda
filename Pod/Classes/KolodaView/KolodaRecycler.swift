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
    func setupAfterAwake()
}

internal class KolodaRecycler: NSObject {
   
    private var unusedItems = Set<KolodaBaseView>()
    private var registeredNibs: [String : UINib] = [String : UINib]()
    private var registeredClasses: [String : KolodaBaseView.Type] = [String : KolodaBaseView.Type]()
    
    internal func register(nib nib: UINib, forObjectReuseIdentifier identifier: String) {
        registeredNibs[identifier] = nib
        
        if let _ = registeredClasses.indexForKey(identifier) {
            registeredClasses.removeValueForKey(identifier)
        }
    }
    
    internal func register(Class objectClass: KolodaBaseView.Type, forObjectReuseIdentifier identifier: String) {
        registeredClasses[identifier] = objectClass
        
        if let _ = registeredNibs.indexForKey(identifier) {
            registeredNibs.removeValueForKey(identifier)
        }
    }
    
    internal func enqueue(object object: KolodaBaseView) {
        unusedItems.insert(object)
    }
    
    internal func dequeue<T: KolodaBaseView>(identifier identifier: String) -> T? {
        let unusedItem = unusedItems.filter { $0.identifier == identifier }.last
        
        if let item = unusedItem {
            unusedItems.remove(item)
            item.prepareForReuse()
            return item as? T
        }
        
        if let index = registeredClasses.indexForKey(identifier) {
            let objectClass = registeredClasses[index].1
            let item = objectClass.init(frame: CGRectZero)
            return item as? T
        }
        
        if let _ = registeredNibs.indexForKey(identifier) {
            let nib = registeredNibs[identifier]
            let item = nib!.instantiateWithOwner(nil, options: nil)[0] as? T
            item?.setupAfterAwake()
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
