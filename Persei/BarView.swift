//
//  BarView.swift
//  Persei
//
//  Created by zen on 28/01/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

import Foundation
import UIKit

private var ContentOffsetContext = 0

public class BarView: UIView {
    
    // MARK: - Init
    public override init(frame: CGRect = CGRect(x: 0.0, y: 0.0, width: 320.0, height: 64.0)) {
        super.init(frame: frame)
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View lifecycle
    public override func willMoveToSuperview(newSuperview: UIView?) {
        super.willMoveToSuperview(newSuperview)
        scrollView = nil
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if superview != nil {
            scrollView = superview as UIScrollView
        }
    }
    
    // MARK: - ScrollView
    private weak var scrollView: UIScrollView! {
        willSet {
            self.scrollView?.removeObserver(self, forKeyPath: "contentOffset", context: &ContentOffsetContext)
            self.scrollView?.panGestureRecognizer.removeTarget(self, action: "handlePan:")
            
            appliedInsets = UIEdgeInsetsZero
        }
        
        didSet {
            scrollView?.addObserver(self, forKeyPath: "contentOffset", options: .Initial | .New, context: &ContentOffsetContext)
            scrollView?.panGestureRecognizer.addTarget(self, action: "handlePan:")
        }
    }
    
    // MARK: - KVO
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &ContentOffsetContext {
            layoutToFit()
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - State
    public enum State {
        case Default, Revealed
    }
    
    public private(set) var state: State = .Default {
        didSet {
            if oldValue != state {
                switch state {
                case .Default:
                    self.removeInsets()
                    
                case .Revealed:
                    self.addInsets()
                }
            }
        }
    }
    
    // MARK: - Applyied Insets
    private var appliedInsets: UIEdgeInsets = UIEdgeInsetsZero
    private var insetsApplied: Bool {
        return appliedInsets != UIEdgeInsetsZero
    }

    private func applyInsets(insets: UIEdgeInsets, animated: Bool) {
        let originalInset = scrollView.contentInset - appliedInsets
        let targetInset = originalInset + insets

        self.appliedInsets = insets
        
        if animated {
            UIView.animateWithDuration(0.2) {
                self.scrollView.contentInset = targetInset
            }
        } else {
            scrollView.contentInset = targetInset
        }
    }
    
    private func addInsets(animated: Bool = true) {
        assert(!insetsApplied, "Internal inconsistency")
        applyInsets(UIEdgeInsets(top: barHeigh, left: 0.0, bottom: 0.0, right: 0.0), animated: animated)
    }

    private func removeInsets(animated: Bool = true) {
        assert(insetsApplied, "Internal inconsistency")
        applyInsets(UIEdgeInsetsZero, animated: animated)
    }
    
    // MARK: - BarHeight
    @IBInspectable
    public var barHeigh: CGFloat = 64.0
    
    // MARK: - Threshold
    @IBInspectable
    public var threshold: CGFloat = 0.5
    
    // MARK: - Content Offset Hanlding
    @objc
    private func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .Ended:
            let value = scrollView.normalizedContentOffset.y
            let triggeringValue = CGRectGetHeight(bounds) * threshold
            
            switch state {
            case .Default:
                if triggeringValue < value * -1.0 {
                    state = .Revealed
                }
                
            case .Revealed:
                if triggeringValue < value {
                    state = .Default
                }
            }
            
        default:
            break
        }
    }
    
    // MARK: - Layout
    private func layoutToFit() {
        var origin = scrollView.contentOffset.y + scrollView.contentInset.top - appliedInsets.top
        frame.origin.y = origin
        
        sizeToFit()
    }
    
    public override func sizeThatFits(_: CGSize) -> CGSize {
        var height: CGFloat = 0.0
        
        switch state {
        case .Default:
            height = scrollView.normalizedContentOffset.y * -1.0
            
        case .Revealed:
            height = appliedInsets.top - scrollView.normalizedContentOffset.y
            break
        }
        
        let output = CGSize(width: CGRectGetWidth(scrollView.bounds), height: max(height, 0.0))
        
        return output
    }
}