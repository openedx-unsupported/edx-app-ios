//
//  CourseDatesViewController.swift
//  edX
//
//  Created by Salman on 08/05/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import WebKit

class CourseDatesViewController: UIViewController, InterfaceOrientationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider & OEXRouterProvider
    
    private let datesLoader = BackedStream<(CourseDateModel)>()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(CourseDateViewCell.self, forCellReuseIdentifier: CourseDateViewCell.identifier)
        
        return tableView
    }()
    
    private lazy var loadController = LoadStateViewController()
    
    private var courseDateModel: CourseDateModel?
    private var dateBlocksMap: [Date : [CourseDateBlock]] = [:]
    private var dateBlocksMapSortedKeys: [Date] = []
    private var setDueNext = false
    
    private let courseID: String
    private let environment: Environment
    
    init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setConstraints()
        setAccessibilityIdentifiers()
        loadCourseDates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.CourseDates.rawValue, courseID: courseID, value: nil)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func setupView() {
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.addSubview(tableView)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        loadController.setupInController(controller: self, contentView: tableView)
    }
    
    private func loadCourseDates() {
        let networkRequest = CourseDatesAPI.courseDatesRequest(courseID: courseID)
        let stream = environment.networkManager.streamForRequest(networkRequest)
        datesLoader.addBackingStream(stream)
        
        stream.listen(self) { [weak self] response in
            switch response {
            case .success(let data):
                self?.handleResponse(data: data)
                break
            case .failure:
                self?.loadController.state = LoadState.failed(message: Strings.Coursedates.courseDateUnavailable)
                break
            }
        }
    }
    
    private func handleResponse(data: CourseDateModel) {
        if data.courseDateBlocks.isEmpty {
            loadController.state = LoadState.failed(message: Strings.Coursedates.courseDateUnavailable)
        } else {
            populate(data: data)
            loadController.state = .Loaded
        }
    }
    
    private func populate(data: CourseDateModel) {
        courseDateModel = data
        var blocks = data.courseDateBlocks
        
        dateBlocksMap = [:]
        
        let isToday = blocks.first { $0.blockStatus == .today }
        
        if isToday == nil {
            let past = blocks.filter { $0.isInPast }
            let future = blocks.filter { $0.isInFuture }
            let todayBlock = CourseDateBlock()
            
            blocks.removeAll()
            
            blocks.append(contentsOf: past)
            blocks.append(todayBlock)
            blocks.append(contentsOf: future)
        }
        
        for block in blocks {
            let key = block.blockDate
            if dateBlocksMap.keys.contains(key) {
                if var item = dateBlocksMap[key] {
                    item.append(block)
                    dateBlocksMap[key] = item
                }
            } else {
                dateBlocksMap[key] = [block]
            }
        }
        
        dateBlocksMapSortedKeys = dateBlocksMap.keys.sorted()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "CourseDatesViewController:view"
        tableView.accessibilityIdentifier = "CourseDatesViewController:table-view"
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
}

extension CourseDatesViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dateBlocksMapSortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseDateViewCell.identifier, for: indexPath) as! CourseDateViewCell

        let index = indexPath.row
        let key = dateBlocksMapSortedKeys[index]
        let count = dateBlocksMapSortedKeys.count
        
        cell.timeline.topColor = .clear
        cell.timeline.bottomColor = .clear
        
        let dark = OEXStyles.shared().neutralXDark()
        
        if index == 0 {
            cell.timeline.topColor = .clear
            cell.timeline.bottomColor = dark
        } else if index == count - 1 {
            cell.timeline.topColor = dark
            cell.timeline.bottomColor = .clear
        } else {
            cell.timeline.topColor = dark
            cell.timeline.bottomColor = .black
        }
        
        guard let blocks = dateBlocksMap[key] else { return cell }
        
        cell.delegate = self
        cell.setDueNextOnThisBlock = !setDueNext
        cell.userTimeZone = courseDateModel?.userTimezone
        cell.blocks = blocks
        
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }

extension CourseDatesViewController: CourseDateViewCellDelegate {
    func didSelectLinkWith(url: URL) {
       if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    func didSetDueNext() {
        setDueNext = true
    }
}

// For use in testing only
extension CourseDatesViewController {
    func t_loadData(data: CourseDateModel) {
        t_handleResponse(data: data)
        loadController.state = .Loaded
    }
    
    func t_handleResponse(data: CourseDateModel) {
        courseDateModel = data
        let blocks = data.courseDateBlocks
        
        dateBlocksMap = [:]

        for block in blocks {
            let key = block.blockDate
            if dateBlocksMap.keys.contains(key) {
                if var item = dateBlocksMap[key] {
                    item.append(block)
                    dateBlocksMap[key] = item
                }
            } else {
                dateBlocksMap[key] = [block]
            }
        }
        
        dateBlocksMapSortedKeys = dateBlocksMap.keys.sorted()
        tableView.reloadData()
    }
}
