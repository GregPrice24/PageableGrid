//
//  PageableGrid.swift
//  PageableGrid
//
//  Created by Greg Price on 6/7/15.
//  Copyright (c) 2015 Gregory Price. All rights reserved.
//

import Foundation
import UIKit

public protocol PageableGridViewDelegate {
    func pageableGrid(grid: PageableGridView, didMoveToSection section: Int)
    func pageableGrid(grid: PageableGridView, didMoveToRow row: Int)
}

public protocol PageableGridViewItem {
    var name: String? { get }
    var description: String? { get }
    var images: [UIImage]? { get }
}

open class PageableGridView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, PageableGridViewDelegate {
    
    public var delegate: PageableGridViewDelegate?
    
    public private(set) var items = [PageableGridViewItem]()
    
    private var pageView: PageView!
    private var collectionView: UICollectionView!
    private var header: UILabel!
    
    private var scrollViewOffset:CGPoint!
    private var section:Int = 0
    private var row:Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView = UICollectionView(frame: self.frame, collectionViewLayout: PageableGridViewLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.register(DynamicGridViewCell.self, forCellWithReuseIdentifier: "DynamicGridViewCell")
        collectionView.backgroundColor = UIColor.white
        pageView = PageView(frame: CGRect.zero)
        pageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pageView)
        pageView.backgroundColor = UIColor.clear
        pageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        pageView.trailingAnchor.constraint(equalTo: pageView.leadingAnchor, constant: 20).isActive = true
        pageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 150).isActive = true
        pageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -150).isActive = true
        header = UILabel(frame: CGRect.zero)
        header.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)
        header.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        header.topAnchor.constraint(equalTo: self.topAnchor, constant: 50).isActive = true
        header.heightAnchor.constraint(equalToConstant: 80)
        header.widthAnchor.constraint(equalToConstant: 200)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func add(_ item: PageableGridViewItem) {
        items.append(item)
        if items.count == 1 {
            header.text = item.name
            pageView.pages = item.images!.count
            pageView.page = row
        }
        collectionView.reloadData()
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].images!.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DynamicGridViewCell", for: indexPath) as! DynamicGridViewCell
        let item = items[indexPath.section]
        cell.imageView.image = item.images![indexPath.row]
        return cell
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewOffset = scrollView.contentOffset
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollViewOffset.x != scrollView.contentOffset.x && scrollViewOffset.y != scrollView.contentOffset.y {
            if (abs(scrollView.contentOffset.x - scrollViewOffset.x) > abs(scrollView.contentOffset.y - scrollViewOffset.y)) {
                scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y:scrollViewOffset.y)
            } else {
                scrollView.contentOffset = CGPoint(x: scrollViewOffset.x, y:scrollView.contentOffset.y)
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewOffset = scrollView.contentOffset
        let rowSnap = Int(collectionView.contentOffset.y / collectionView.frame.size.height)
        if row != rowSnap {
            row = rowSnap
            pageableGrid(grid: self, didMoveToRow: row)
        } else {
            let sectionSnap = Int(collectionView.contentOffset.x / collectionView.frame.size.width)
            if section != sectionSnap {
                section = sectionSnap
                row = 0
                pageableGrid(grid: self, didMoveToSection: section)
            }
        }
    }
    
    public func pageableGrid(grid: PageableGridView, didMoveToSection section: Int) {
        let layout = collectionView.collectionViewLayout as! PageableGridViewLayout
        layout.row = row
        layout.section = section
        let item = items[section]
        header.text = item.name
        pageView.pages = item.images!.count
        pageView.page = row
        delegate?.pageableGrid(grid: self, didMoveToSection: section)
    }
    
    public func pageableGrid(grid: PageableGridView, didMoveToRow row: Int) {
        let layout = collectionView.collectionViewLayout as! PageableGridViewLayout
        layout.row = row
        pageView.page = row
        delegate?.pageableGrid(grid: self, didMoveToRow: row)
    }
}

fileprivate class PageableGridViewLayout: UICollectionViewLayout {
    
    private var layoutAttributes = [Int:[UICollectionViewLayoutAttributes]]()
    private var contentSize:CGSize = CGSize.zero
    private var sectionsInLayout: Int {
        return collectionView?.numberOfSections ?? 0
    }
    
    var section: Int = 0 {
        didSet {
            configure()
        }
    }
    
    var row: Int = 0 {
        didSet {
            invalidateLayout()
        }
    }
    
    override func prepare() {
        if self.collectionView?.numberOfSections == 0 {
            return
        }
        configure()
    }
    
    override var collectionViewContentSize: CGSize  {
        return contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes.flatMap {$0.1.filter { rect.intersects($0.frame) }}
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return false
    }
    
    private func configure() {
        if section == 0 {
            prepareNextSectionAttributes()
        } else if section == sectionsInLayout {
            preparePreviousSectionAttributes()
        } else {
            prepareNextSectionAttributes()
            preparePreviousSectionAttributes()
        }
        
        let visibleWidth:CGFloat = collectionView!.bounds.size.width
        let visibleHeight:CGFloat = collectionView!.bounds.size.height
        let xOffset:CGFloat = visibleWidth*(CGFloat(section))
        collectionView?.scrollRectToVisible(CGRect(x: xOffset, y: CGFloat(row) * visibleHeight, width: visibleWidth, height: visibleHeight).integral, animated: false)
        var yOffset:CGFloat = 0
        let rows = collectionView!.numberOfItems(inSection: section)
        var sectionAttributes = [UICollectionViewLayoutAttributes]()
        for j in 0..<rows {
            let indexPath = IndexPath(item: j, section: section)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(x: xOffset, y: yOffset, width: visibleWidth, height: visibleHeight).integral
            sectionAttributes.append(attributes)
            yOffset += visibleHeight
        }
        layoutAttributes[section] = sectionAttributes
        contentSize = CGSize(width: visibleWidth*CGFloat(sectionsInLayout), height: yOffset)
    }
    
    private func preparePreviousSectionAttributes() {
        let previous = section - 1
        let indexPath = IndexPath(item: 0, section: previous)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
        attributes.frame = CGRect(x: (collectionView!.bounds.size.width*(CGFloat(previous))), y: collectionView!.bounds.size.height*CGFloat(row), width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height).integral
        layoutAttributes[previous] = [attributes]
    }
    
    private func prepareNextSectionAttributes() {
        let next = min(section + 1, sectionsInLayout)
        let indexPath = IndexPath(item: 0, section: next)
        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath as IndexPath)
        attributes.frame = CGRect(x: (collectionView!.bounds.size.width*(CGFloat(next))), y: collectionView!.bounds.size.height*CGFloat(row), width: collectionView!.bounds.size.width, height: collectionView!.bounds.size.height).integral
        layoutAttributes[next] = [attributes]
    }
}

fileprivate class PageView: UIView {
    var pages:Int = 0 {
        didSet {
            if pages > 5 {
                var newBounds:CGRect = self.bounds
                newBounds.size.height += 10
                self.bounds = newBounds
            }
            setNeedsDisplay()
        }
    }
    
    var page:Int = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private let π:CGFloat = .pi
    private let radius: CGFloat = 8
    private let verticalSpacing:CGFloat = 14
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        var path:UIBezierPath = UIBezierPath()
        for i in 0..<pages {
            let center:CGPoint = CGPoint(x: rect.width/2, y: ((CGFloat(i)) * verticalSpacing) + verticalSpacing)
            if page == i {
                path = UIBezierPath(arcCenter: center,
                                    radius: radius/2,
                                    startAngle: 2*π,
                                    endAngle: 4*π,
                                    clockwise: true)
                UIColor(red: CGFloat(170 / 255.0), green: CGFloat(43 / 255.0), blue: CGFloat(43 / 255.0), alpha: CGFloat(1)).setFill()
                path.fill()
            } else {
                let borderWidth:CGFloat = 1
                path = UIBezierPath(arcCenter: center,
                                    radius: radius/2 - borderWidth/2,
                                    startAngle: 2*π,
                                    endAngle: 4*π,
                                    clockwise: true)
                path.lineWidth = borderWidth
                UIColor.black.setStroke()
                path.stroke()
            }
        }
    }
}

open class DynamicGridViewCell: UICollectionViewCell {
    public var imageView: UIImageView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
