//
//  SwiftBinding.swift
//
// Keeping dynamic data up to date
// http://five.agency/solving-the-binding-problem-with-swift/
// https://github.com/SwiftBond/Bond

import Foundation

//Encapsulates Dynamic data
// Allowing for listeners to be called when value changes

//Note: We could have a property on the Dynamic that retains a Listener, but that would not be a good idea because we don’t want tasks to be owned by the data.
class Dynamic<T> {
    var value: T {
        didSet {
            valueChanged()
        }
    }
    
    var bonds: [BondBox<T>] = []
    
    init(_ v: T) {
        value = v
    }
    
    func valueChanged() {
        for bondBox in bonds {
            bondBox.bond?.listener(value)
        }
    }
}

//We don’t want to strongly reference bonded Bonds.
class BondBox<T> {
    weak var bond: Bond<T>?
    init(_ b: Bond<T>) { bond = b }
}

//Bond between Dynamic and Listener
class Bond<T> {
    typealias Listener = (T) -> Void
    
    var listener: Listener
    
    init(_ listener: Listener) {
        self.listener = listener
    }
    
    func bind(dynamic: Dynamic<T>) {
        dynamic.bonds.append(BondBox(self))
    }
}

protocol Bondable {
    typealias BondType
    var designatedBond: Bond<BondType> { get }
}

//MARK: UILabel Extension
//Use associated objects to add Bond object to update label's text
private var handle: UInt8 = 0;

extension UILabel: Bondable {
    var designatedBond: Bond<String> {
        if let b: AnyObject = objc_getAssociatedObject(self, &handle) {
            return b as Bond<String>
        } else {
            let b = Bond<String>() { [unowned self] v in self.text = v }
            objc_setAssociatedObject(self, &handle, b, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            return b
        }
    }
}