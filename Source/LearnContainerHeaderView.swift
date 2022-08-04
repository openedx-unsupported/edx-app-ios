//
//  LearnContainerHeaderView.swift
//  edX
//
//  Created by Muhammad Umer on 31/05/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

protocol LearnContainerHeaderViewDelegate: AnyObject {
    func didTapOnDropDown(item: LearnContainerHeaderItem)
}

protocol LearnContainerHeaderItem {
    var title: String { get }
}

class LearnContainerHeaderView: UIView {
    static let height = StandardVerticalMargin * 6.5
    
    weak var delegate: LearnContainerHeaderViewDelegate?
    
    private let container = UIView()
    private let dropDownContainer = UIView()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "LearnContainerHeaderView:button-view"
        button.oex_addAction({ [weak self] _ in
            if self?.shouldShowDropDown == true {
                self?.dropDown.show()
            }
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var largeTextStyle = OEXMutableTextStyle(weight: .bold, size: .xxxxxLarge, color: OEXStyles.shared().primaryDarkColor())
    private lazy var smallTextStyle = OEXMutableTextStyle(weight: .bold, size: .xxxLarge, color: OEXStyles.shared().primaryDarkColor())
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "LearnContainerHeaderView:label"
        label.attributedText = largeTextStyle.attributedString(withText: items[0].title)
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "LearnContainerHeaderView:image-view"
        imageView.image = Icon.ExpandMore.imageWithFontSize(size: 24)
        imageView.tintColor = OEXStyles.shared().primaryBaseColor()
        return imageView
    }()
    
    private var originalFrame: CGRect = .zero
    
    private let dropDown = DropDown()
    
    private var shouldShowDropDown: Bool {
        return items.count > 1
    }
    
    private var items: [LearnContainerHeaderItem]
    private var selectedRowIndex: Int
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(items: [LearnContainerHeaderItem], selectedRowIndex: Int = 0) {
        self.items = items
        self.selectedRowIndex = selectedRowIndex
        super.init(frame: .zero)
        setupDropDown()
        setupViews()
    }
    
    private func setupViews() {
        accessibilityIdentifier = "LearnContainerHeaderView"
        
        container.addSubview(label)
        container.addSubview(imageView)
        container.addSubview(button)
        
        addSubview(dropDownContainer)
        addSubview(container)
        
        container.snp.makeConstraints { make in
            make.top.equalTo(self).offset(-6)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }

        dropDownContainer.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalTo(container)
            make.bottom.equalTo(container)
            make.leading.equalTo(label)
            make.trailing.equalTo(imageView)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(container)
            make.bottom.equalTo(container)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
        }
        
        imageView.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(StandardHorizontalMargin / 2)
            make.centerY.equalTo(label)
        }
        
        imageView.isHidden = !shouldShowDropDown
        originalFrame = container.frame
    }
    
    func moveToCenter() {
        dropDown.bottomOffset = CGPoint(x: 0, y: 44)
        container.frame = CGRect(x: 0, y: 0, width: 180, height: 44)
        container.center.x = frame.size.width / 2
        
        if let index = dropDown.indexForSelectedRow {
            label.attributedText = smallTextStyle.attributedString(withText: items[index].title)
        } else {
            label.attributedText = smallTextStyle.attributedString(withText: items[0].title)
        }
    }
    
    func moveBackOriginalFrame() {
        container.frame = originalFrame
        dropDown.bottomOffset = CGPoint(x: 0, y: 80)
        
        if let index = dropDown.indexForSelectedRow {
            label.attributedText = smallTextStyle.attributedString(withText: items[index].title)
        } else {
            label.attributedText = smallTextStyle.attributedString(withText: items[0].title)
        }
    }
    
    func updateHeader(at index: Int) {
        dropDown.selectedRowIndex = index
        label.attributedText = smallTextStyle.attributedString(withText: items[index].title)
    }
    
    private func rotateImageView(clockWise: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.imageView.transform = weakSelf.imageView.transform.rotated(by: clockWise ? -(.pi * 0.999) : .pi)
        }
    }
}

extension LearnContainerHeaderView {
    private func setupDropDown() {
        let normalTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
        normalTextStyle.alignment = .center
        
        let selectedTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryBaseColor())
        selectedTextStyle.alignment = .center
        
        dropDown.accessibilityIdentifier = "LearnContainerHeaderView:drop-down-view"
        dropDown.bottomOffset = CGPoint(x: 0, y: LearnContainerHeaderView.height)
        dropDown.direction = .bottom
        dropDown.anchorView = dropDownContainer
        dropDown.dismissMode = .automatic
        dropDown.normalTextStyle = normalTextStyle
        dropDown.selectedTextStyle = selectedTextStyle
        dropDown.selectedBackgroundColor = OEXStyles.shared().neutralXLight()
        dropDown.normalBackgroundColor = OEXStyles.shared().neutralWhiteT()
        dropDown.textColor = OEXStyles.shared().primaryBaseColor()
        dropDown.selectedTextColor = OEXStyles.shared().primaryBaseColor()
        dropDown.dataSource = items.map { $0.title }
        dropDown.selectedRowIndex = 0
        dropDown.selectionAction = { [weak self] index, _ in
            guard let weakSelf = self else { return }
            weakSelf.dropDown.selectedRowIndex = index
            weakSelf.label.attributedText = weakSelf.largeTextStyle.attributedString(withText: weakSelf.items[index].title)
            weakSelf.delegate?.didTapOnDropDown(item: weakSelf.items[index])
        }
        dropDown.willShowAction = { [weak self] in
            self?.rotateImageView(clockWise: true)
        }
        dropDown.cancelAction = { [weak self] in
            self?.rotateImageView(clockWise: false)
        }
    }
    
    func dimissDropDown() {
        dropDown.hide()
    }
}
