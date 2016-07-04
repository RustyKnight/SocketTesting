//
//  KeyboardDismisser.swift
//  Cioffi
//
//  Created by Shane Whitehead on 31/05/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import UIKit

// This is because we can't generate an extension which can override/extend a stored value
// This allows us to connect the KeyboardDismisser and DismissableTextField from within the
// storyboard itself
public class DismissableTextField: UITextField {
    @IBOutlet public var inputAccessory: UIView? {
        set {
            self.inputAccessoryView = newValue
        }
        get {
            return self.inputAccessoryView
        }
    }
}

// This idea comes from http://stackoverflow.com/questions/9246509/how-to-dismiss-uikeyboardtypenumberpad/9288516#9288516
// It's not fully implemented as extensions in Swift can't have computed properties
// or override functionality
public class KeyboardDismisser: UIView {
    internal var tapGR: UITapGestureRecognizer?

    @IBOutlet public var mainView: UIView? {
        didSet {
            if let tapGR = tapGR, let view = tapGR.view {
                view.removeGestureRecognizer(tapGR)
            }
            tapGR = UITapGestureRecognizer(target: mainView, action: #selector(KeyboardDismisser.endEditing))
        }
    }

    public init(withMainView mainView: UIView) {
        self.mainView = mainView
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        guard let mainView = mainView else {
            return
        }
        guard let tapGR = tapGR else {
            return
        }
        if let _ = window {
            mainView.addGestureRecognizer(tapGR)
        } else {
            mainView.removeGestureRecognizer(tapGR)
        }
    }
}
