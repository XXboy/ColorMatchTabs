//
//  ScrollMenu.swift
//  ColorMatchTabs
//
//  Created by anna on 6/15/16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import UIKit

@objc public protocol ScrollMenuDelegate: UIScrollViewDelegate {
    
    @objc optional func scrollMenu(_ scrollMenu: ScrollMenu, didSelectedItemAt index: Int)
    
}

@objc public protocol ScrollMenuDataSource: class {
    
    func numberOfItemsInScrollMenu(_ scrollMenu: ScrollMenu) -> Int
    func scrollMenu(_ scrollMenu: ScrollMenu, viewControllerAt index: Int) -> UIViewController
    
}

open class ScrollMenu: UIScrollView {
    
    @IBOutlet open weak var menuDelegate: ScrollMenuDelegate?
    @IBOutlet open weak var dataSource: ScrollMenuDataSource?
    
    open var indexOfVisibleItem: Int {
        if bounds.width > 0 {
            return Int(round(contentOffset.x / bounds.width))
        }
        return 0
    }
    
    fileprivate var previousIndex = 0
    fileprivate var destinationIndex: Int?
    fileprivate var manualSelection = false
    
    fileprivate var viewControllers: [UIViewController] = [] {
        didSet {
            layoutContent()
        }
    }
    
    override open var contentOffset: CGPoint {
        didSet {
            if let destinationIndex = destinationIndex , manualSelection && destinationIndex != indexOfVisibleItem {
                return
            }
            if !manualSelection {
                showAllContent()
            }
            manualSelection = false
            
            if indexOfVisibleItem != previousIndex {
                previousIndex = indexOfVisibleItem
                destinationIndex = nil
                
                menuDelegate?.scrollMenu?(self, didSelectedItemAt: indexOfVisibleItem)
            }
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    fileprivate func commonInit() {
        isPagingEnabled = true
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        layoutContent()
    }
    
    open func selectItem(atIndex index: Int) {
        guard indexOfVisibleItem != index else {
            return
        }
        
        manualSelection = true
        destinationIndex = index
        
        let first = min(index, indexOfVisibleItem) + 1
        let last = max(index, indexOfVisibleItem)
        hideContent(forRange: first..<last)
        updateContentOffset(withIndex: index)
    }
 
    open func reloadData() {
        guard let dataSource = dataSource else {
            return
        }
        
        viewControllers = []
        for index in 0..<dataSource.numberOfItemsInScrollMenu(self) {
            let viewController = dataSource.scrollMenu(self, viewControllerAt: index)
            viewControllers.append(viewController)
            addSubview(viewController.view)
        }
        
        layoutContent()
    }
    
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateContentOffset(withIndex: indexOfVisibleItem)
    }
    
}

private extension ScrollMenu {
    
    func layoutContent() {
        contentSize = CGSize(width: bounds.width * CGFloat(viewControllers.count), height: bounds.height)
        
        for (index, viewController) in viewControllers.enumerated() {
            viewController.view.frame = CGRect(
                x: bounds.width * CGFloat(index),
                y: 0,
                width: bounds.width,
                height: bounds.height 
            )
        }
    }
    
    func updateContentOffset(withIndex index: Int) {
        if viewControllers.count > index {
            let width = viewControllers[index].view.bounds.width
            let contentOffsetX = width * CGFloat(index)
            setContentOffset(CGPoint(x: contentOffsetX, y: contentOffset.y), animated: true)
        }
    }
    
    func hideContent(forRange range: Range<Int>) {
        viewControllers.enumerated().forEach { index, viewController in
            viewController.view.isHidden = range.contains(index)
        }
    }

    func showAllContent() {
         viewControllers.forEach { viewController in
            viewController.view.isHidden = false
        }
    }
    
}
