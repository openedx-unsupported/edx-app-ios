//
//  VideoDownloadQualityViewController.swift
//  edX
//
//  Created by Muhammad Umer on 13/08/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

fileprivate let buttonSize: CGFloat = 20

protocol VideoDownloadQualityDelegate: AnyObject {
    func didUpdateVideoQuality()
}

class VideoDownloadQualityViewController: UIViewController {
    
    typealias Environment = OEXInterfaceProvider & OEXAnalyticsProvider & OEXConfigProvider
    
    private lazy var headerView = VideoDownloadQualityHeaderView()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 20
        tableView.alwaysBounceVertical = false
        tableView.separatorInset = .zero
        tableView.tableFooterView = UIView()
        tableView.register(VideoQualityCell.self, forCellReuseIdentifier: VideoQualityCell.identifier)
        tableView.accessibilityIdentifier = "VideoDownloadQualityViewController:table-view"
        
        return tableView
    }()
    
    private weak var delegate: VideoDownloadQualityDelegate?
    
    private let environment: Environment
    
    init(environment: Environment, delegate: VideoDownloadQualityDelegate?) {
        self.environment = environment
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        title = Strings.videoDownloadQualityTitle
        
        setupViews()
        addCloseButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        environment.analytics.trackScreen(withName: AnalyticsScreenName.VideoDownloadQuality.rawValue)
    }
    
    private func setupViews() {
        view.addSubview(tableView)
        
        tableView.tableHeaderView = headerView
        
        headerView.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        tableView.setAndLayoutTableHeaderView(header: headerView)
        
        tableView.reloadData()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: buttonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "VideoDownloadQualityViewController:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}

extension VideoDownloadQualityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return VideoDownloadQuality.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoQualityCell.identifier, for: indexPath) as! VideoQualityCell
        
        let item = VideoDownloadQuality.allCases[indexPath.row]
        
        if let quality = environment.interface?.getVideoDownladQuality(),
           quality == item {
            cell.update(title: item.title, selected: true)
        } else {
            cell.update(title: item.title, selected: false)
        }
        
        return cell
    }
}

extension VideoDownloadQualityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldQuality = environment.interface?.getVideoDownladQuality()
        let quality = VideoDownloadQuality.allCases[indexPath.row]
        tableView.reloadData()
        environment.interface?.saveVideoDownloadQuality(quality: quality)
        environment.analytics.trackVideoDownloadQualityChanged(value: quality.analyticsValue, oldValue: oldQuality?.analyticsValue ?? "")
        delegate?.didUpdateVideoQuality()
    }
}

class VideoDownloadQualityHeaderView: UITableViewHeaderFooterView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        let textStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralBlackT())
        label.attributedText = textStyle.attributedString(withText: Strings.videoDownloadQualityMessage(platformName: OEXConfig.shared().platformName()))
        label.accessibilityIdentifier = "VideoDownloadQualityHeaderView:title-view"
        return label
    }()
    
    private lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = OEXStyles.shared().neutralXLight()
        view.accessibilityIdentifier = "VideoDownloadQualityHeaderView:seperator-view"
        return view
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        accessibilityIdentifier = "VideoDownloadQualityHeaderView"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(separator)
    }
    
    private func setupConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardVerticalMargin * 2)
            make.trailing.equalTo(self).inset(StandardVerticalMargin * 2)
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
        }
        
        separator.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(1)
        }
    }
}

class VideoQualityCell: UITableViewCell {
    static let identifier = "VideoQualityCell"
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "VideoQualityCell:title-label"
        return label
    }()
    
    private lazy var checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.Check.imageWithFontSize(size: buttonSize).image(with: OEXStyles.shared().neutralBlackT())
        imageView.accessibilityIdentifier = "VideoQualityCell:checkmark-image-view"
        return imageView
    }()
    
    private lazy var textStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryDarkColor())
    private lazy var textStyleSelcted = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryDarkColor())

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "VideoDownloadQualityViewController:video-quality-cell"
        
        setupView()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)
    }
    
    private func setupConstrains() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
        }
        
        checkmarkImageView.snp.makeConstraints { make in
            make.width.equalTo(buttonSize)
            make.height.equalTo(buttonSize)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin * 2)
            make.centerY.equalTo(contentView)
        }
        
        checkmarkImageView.isHidden = true
    }
    
    func update(title: String, selected: Bool) {
        checkmarkImageView.isHidden = !selected
        
        if selected {
            titleLabel.attributedText = textStyleSelcted.attributedString(withText: title)
        } else {
            titleLabel.attributedText = textStyle.attributedString(withText: title)
        }
    }
}
