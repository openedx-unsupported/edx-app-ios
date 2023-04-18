//
//  CourseContentHeaderView.swift
//  edX
//
//  Created by MuhammadUmer on 11/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

protocol CourseContentHeaderViewDelegate: AnyObject {
    func didTapOnClose()
    func didTapOnBlock(block: CourseBlock, index: Int)
}

class CourseContentHeaderView: UIView {
    typealias Environment = OEXStylesProvider
    
    weak var delegate: CourseContentHeaderViewDelegate?
    
    private let environment: Environment
    
    private let imageSize: CGFloat = 20
    private let attributedIconOfset: CGFloat = -4
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    private let dropDownBottomOffset: CGFloat = StandardVerticalMargin * 2.4
    
    private lazy var headerTextstyle = OEXMutableTextStyle(weight: .bold, size: .base, color: environment.styles.neutralWhiteT())
    private lazy var titleTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralWhiteT())
    private lazy var subtitleTextStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.neutralWhiteT())
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "CourseContentHeaderView:back-button"
        button.setImage(Icon.ArrowBack.imageWithFontSize(size: imageSize), for: .normal)
        button.tintColor = environment.styles.neutralWhiteT()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnClose()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:header-label"
        label.backgroundColor = .clear
        label.alpha = 0
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:title-label"
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var subtitleView: UITextView = {
        let textView = UITextView()
        textView.accessibilityIdentifier = "CourseContentHeaderView:subtitle-label"
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        let padding = textView.textContainer.lineFragmentPadding
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -padding, bottom: 0, right: -padding)
        
        let tapGesture = AttachmentTapGestureRecognizer { [weak self] _ in
            self?.showDropDown()
        }
        
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }()
    
    private var dropDown: DropDown?
    private var tableView: UITableView?
    
    private var currentBlock: CourseBlock?
    private var blocks: [CourseBlock] = []
    
    init(environment: Environment) {
        self.environment = environment
        super.init(frame: .zero)
        addSubViews()
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViews() {
        backgroundColor = environment.styles.primaryLightColor()
        
        addSubview(backButton)
        addSubview(headerLabel)
        addSubview(titleLabel)
        addSubview(subtitleView)
    }
    
    private func addConstraints() {
        backButton.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(StandardHorizontalMargin * 0.86)
            make.top.equalTo(self).offset(StandardVerticalMargin * 1.25)
            make.width.height.equalTo(imageSize)
        }
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        subtitleView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
    }
    
    func showDropDown() {
        let dropDown = DropDown()
        
        self.tableView = dropDown.setupCustom()
        
        dropDown.bottomOffset = CGPoint(x: 0, y: dropDownBottomOffset)
        dropDown.direction = .bottom
        dropDown.anchorView = subtitleView
        dropDown.dismissMode = .automatic
        
        self.dropDown = dropDown
        
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.register(NewCourseContentHeaderTableViewCell.self, forCellReuseIdentifier: NewCourseContentHeaderTableViewCell.identifier)
        tableView?.register(NewCourseGatedContentHeaderTableViewCell.self, forCellReuseIdentifier: NewCourseGatedContentHeaderTableViewCell.identifier)
        
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = 44
        
        tableView?.separatorStyle = .singleLine
        tableView?.separatorColor = OEXStyles.shared().neutralXLight()
        tableView?.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        
        dropDown.updatedMinHeight = 44
        dropDown.updatedTableHeight = 44 * CGFloat(blocks.count)
        
        tableView?.reloadData()
        
        dropDown.show()
    }
    
    func setBlocks(currentBlock: CourseBlock, blocks: [CourseBlock]) {
        self.currentBlock = currentBlock
        self.blocks = blocks
    }
    
    func showHeaderLabel(show: Bool) {
        headerLabel.alpha = show ? 1 : 0
    }
    
    func setup(title: String, subtitle: String?) {
        headerLabel.attributedText = headerTextstyle.attributedString(withText: title)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        
        let subtitleTextString = [
            subtitleTextStyle.attributedString(withText: subtitle),
            attributedUnicodeSpace,
            Icon.Dropdown.attributedText(style: subtitleTextStyle, yOffset: attributedIconOfset)
        ]
        
        subtitleView.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: subtitleTextString)
    }
}

extension CourseContentHeaderView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let block = blocks[indexPath.row]
       
        if block.isGated {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewCourseGatedContentHeaderTableViewCell.identifier, for: indexPath) as! NewCourseGatedContentHeaderTableViewCell
            cell.setup(block: block)
            if let currentBlock = currentBlock, block.blockID == currentBlock.blockID {
                cell.contentView.backgroundColor = OEXStyles.shared().neutralXLight()
            } else {
                cell.contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: NewCourseContentHeaderTableViewCell.identifier, for: indexPath) as! NewCourseContentHeaderTableViewCell
            cell.setup(block: block)
            if let currentBlock = currentBlock, block.blockID == currentBlock.blockID {
                cell.contentView.backgroundColor = OEXStyles.shared().neutralXLight()
            } else {
                cell.contentView.backgroundColor = OEXStyles.shared().neutralWhiteT()
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let block = blocks[index]
        delegate?.didTapOnBlock(block: block, index: index)
        dropDown?.hide()
    }
}
