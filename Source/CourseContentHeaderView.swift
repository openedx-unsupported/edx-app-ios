//
//  CourseContentHeaderView.swift
//  edX
//
//  Created by MuhammadUmer on 11/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

protocol CourseContentHeaderViewDelegate: AnyObject {
    func didTapBackButton()
    func didTapOnUnitBlock(block: CourseBlock, index: Int)
}

class CourseContentHeaderView: UIView {
    typealias Environment = OEXStylesProvider
    
    weak var delegate: CourseContentHeaderViewDelegate?
    
    private let environment: Environment
    
    private let imageSize: CGFloat = 20
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    private let dropDownBottomOffset: CGFloat = StandardVerticalMargin * 5
    private let cellHeight: CGFloat = 36
    private let gatedCellHeight: CGFloat = 76
    
    private lazy var headerTextstyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .base, color: environment.styles.neutralWhiteT())
        style.alignment = .center
        return style
    }()
    
    private lazy var titleTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralWhiteT())
    private lazy var subtitleTextStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.neutralWhiteT())
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "CourseContentHeaderView:back-button"
        button.setImage(Icon.ArrowBack.imageWithFontSize(size: imageSize), for: .normal)
        button.tintColor = environment.styles.neutralWhiteT()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapBackButton()
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
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:subtitle-label"
        return label
    }()
    
    private lazy var bottomContainer = UIView()
    
    private lazy var imageContainer = UIView()
    
    private lazy var dropDownImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "LearnContainerHeaderView:image-view"
        imageView.image = Icon.Dropdown.imageWithFontSize(size: imageSize)
        imageView.tintColor = environment.styles.neutralWhiteT()
        return imageView
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.handleDropDown()
        }, for: .touchUpInside)
        return button
    }()
    
    private var shouldShowDropDown: Bool = true {
        didSet {
            if !shouldShowDropDown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.shouldShowDropDown = true
                }
            }
        }
    }
    
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
        imageContainer.addSubview(dropDownImageView)
        bottomContainer.addSubview(imageContainer)
        bottomContainer.addSubview(subtitleLabel)
        bottomContainer.addSubview(button)
        addSubview(bottomContainer)
        
        subtitleLabel.numberOfLines = 1
    }
    
    private func addConstraints() {
        dropDownImageView.snp.makeConstraints { make in
            make.leading.equalTo(imageContainer)
            make.top.equalTo(imageContainer)
            make.bottom.equalTo(imageContainer)
            make.width.equalTo(imageSize)
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(StandardHorizontalMargin * 0.86)
            make.top.equalTo(self).offset(StandardVerticalMargin * 1.25)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
        }
        
        headerLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.top.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin * 1.86 + imageSize)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        bottomContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        imageContainer.snp.makeConstraints { make in
            make.leading.equalTo(subtitleLabel.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.width.greaterThanOrEqualTo(imageSize)
        }
        
        button.snp.makeConstraints { make in
            make.leading.equalTo(bottomContainer)
            make.top.equalTo(bottomContainer)
            make.bottom.equalTo(bottomContainer)
            make.trailing.equalTo(dropDownImageView)
        }
    }
    
    private func handleDropDown() {
        if dropDown?.isVisible == true {
            dropDown?.hide()
            rotateImageView(clockWise: false)
            dropDown = nil
        } else {
            if shouldShowDropDown {
                showDropDown()
                rotateImageView(clockWise: true)
            }
        }
    }
    
    private func showDropDown() {
        let safeAreaInset = UIApplication.shared.windows.first?.safeAreaInsets ?? .zero
        
        let dropDown = DropDown()
        tableView = dropDown.setupCustom()
        
        dropDown.bottomOffset = CGPoint(x: 0, y: dropDownBottomOffset)
        dropDown.direction = .bottom
        dropDown.anchorView = bottomContainer
        dropDown.dismissMode = .automatic
        dropDown.cornerRadius = 10
        dropDown.offsetFromWindowBottom = safeAreaInset.bottom
        dropDown.cancelAction = { [weak self] in
            self?.shouldShowDropDown = false
            self?.rotateImageView(clockWise: false)
        }
        self.dropDown = dropDown
        
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.register(CourseContentHeaderTableViewCell.self, forCellReuseIdentifier: CourseContentHeaderTableViewCell.identifier)
        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = cellHeight
        tableView?.separatorStyle = .singleLine
        tableView?.separatorColor = environment.styles.neutralXLight()
        tableView?.separatorInset = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        tableView?.layer.cornerRadius = 10
                
        let height = blocks.reduce(0) { $0 + ($1.isGated ? gatedCellHeight : cellHeight) }
        dropDown.updatedTableHeight = height
        dropDown.updatedMinHeight = cellHeight
        
        tableView?.reloadData()
        
        dropDown.show()
    }
    
    private func rotateImageView(clockWise: Bool) {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let weakSelf = self else { return }
            if clockWise {
                weakSelf.dropDownImageView.transform = weakSelf.dropDownImageView.transform.rotated(by: -(.pi * 0.999))
            } else {
                weakSelf.dropDownImageView.transform = .identity
            }
        }
    }
    
    func setBlocks(currentBlock: CourseBlock, blocks: [CourseBlock]) {
        self.currentBlock = currentBlock
        self.blocks = blocks
    }
    
    func showHeaderLabel(show: Bool) {
        headerLabel.alpha = show ? 1 : 0
    }
    
    func update(title: String, subtitle: String?) {
        headerLabel.attributedText = headerTextstyle.attributedString(withText: title)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        subtitleLabel.attributedText = subtitleTextStyle.attributedString(withText: subtitle)
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseContentHeaderTableViewCell.identifier, for: indexPath) as! CourseContentHeaderTableViewCell
        cell.setup(block: block)
        
        if let currentBlock = currentBlock, block.blockID == currentBlock.blockID {
            cell.contentView.backgroundColor = environment.styles.neutralXLight()
        } else {
            cell.contentView.backgroundColor = environment.styles.neutralWhiteT()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = indexPath.row
        let block = blocks[index]
        handleDropDown()
        delegate?.didTapOnUnitBlock(block: block, index: index)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let block = blocks[indexPath.row]
        return block.isGated ? gatedCellHeight : cellHeight
    }
}
