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
    static let expandedHeight = StandardVerticalMargin * 10.6
    static let collapsedHeight = StandardVerticalMargin * 5.5
    
    weak var delegate: LearnContainerHeaderViewDelegate?
    
    var headerViewState: HeaderViewState = .expanded
    
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
    
    private let container = UIView()
    private let dropDownContainer = UIView()
    private let dropDown = DropDown()
    private let dropDownBottomOffset: CGFloat = StandardVerticalMargin * 2
    
    private var items: [LearnContainerHeaderItem]
    
    private var shouldShowDropDown: Bool {
        return items.count > 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(items: [LearnContainerHeaderItem]) {
        self.items = items
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
        
        container.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(-6)
            make.bottom.equalTo(self)
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(LearnContainerHeaderView.expandedHeight)
        }

        dropDownContainer.snp.remakeConstraints { make in
            make.centerY.equalTo(label)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        button.snp.remakeConstraints { make in
            make.centerY.equalTo(label)
            make.leading.equalTo(label)
            make.trailing.equalTo(imageView)
        }
        
        label.snp.remakeConstraints { make in
            make.bottom.equalTo(container).inset(StandardVerticalMargin)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
        }
        
        imageView.snp.remakeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(StandardHorizontalMargin / 2)
            make.centerY.equalTo(label)
        }
        
        imageView.isHidden = !shouldShowDropDown
    }
    
    private func setupDropDown() {
        let normalTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
        normalTextStyle.alignment = .center
        
        let selectedTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryBaseColor())
        selectedTextStyle.alignment = .center
        
        dropDown.accessibilityIdentifier = "LearnContainerHeaderView:drop-down-view"
        dropDown.bottomOffset = CGPoint(x: 0, y: dropDownBottomOffset)
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
            weakSelf.updateHeaderLabel()
            weakSelf.delegate?.didTapOnDropDown(item: weakSelf.items[index])
        }
        dropDown.willShowAction = { [weak self] in
            self?.rotateImageView(clockWise: true)
        }
        dropDown.cancelAction = { [weak self] in
            self?.rotateImageView(clockWise: false)
        }
    }
    
    private func updateHeaderLabel() {
        let index = dropDown.indexForSelectedRow ?? 0
        if headerViewState == .collapsed {
            label.attributedText = smallTextStyle.attributedString(withText: items[index].title)
        } else if headerViewState == .expanded {
            label.attributedText = largeTextStyle.attributedString(withText: items[index].title)
        }
    }
    
    func changeHeader(for index: Int) {
        dropDown.selectedRowIndex = index
        label.attributedText = smallTextStyle.attributedString(withText: items[index].title)
    }
    
    func dimissDropDown() {
        dropDown.forceHide()
    }
    
    func updateHeaderViewState(collapse: Bool) {
        headerViewState = collapse ? .collapsed : .expanded
        updateHeaderLabel()
    }
    
    private func rotateImageView(clockWise: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let weakSelf = self else { return }
            if clockWise {
                weakSelf.imageView.transform = weakSelf.imageView.transform.rotated(by: -(.pi * 0.999))
            } else {
                weakSelf.imageView.transform = .identity
            }
        }
    }
}
