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
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(CourseDateViewCell.self, forCellReuseIdentifier: CourseDateViewCell.identifier)
        
        return tableView
    }()
    
    private lazy var loadController = LoadStateViewController()
    
    private var datesResponse: CourseDateModel?
    private var courseDateBlockMap: [Date : [CourseDateBlock]] = [:]
    private var courseDateBlockMapSortedKeys: [Date] = []
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
                self?.loadController.state = .failed()
                break
            }
        }
    }
    
    private func handleResponse(data: CourseDateModel) {
        populate(data: data)
        loadController.state = .Loaded
    }
    
    private func populate(data: CourseDateModel) {
        datesResponse = data
        var blocks = data.courseDateBlocks
        
        courseDateBlockMap = [:]
        
        let foundToday = blocks.first { $0.blockStatus == .today }
        
        if foundToday == nil {
            let past = blocks.filter { $0.isInPast }
            let future = blocks.filter { $0.isInFuture }
            let todayBlock = CourseDateBlock()
            
            blocks.removeAll()
            
            blocks.append(contentsOf: past)
            blocks.append(todayBlock)
            blocks.append(contentsOf: future)
        }
        
        for block in blocks {
            let key = block.blockDate.stripTimeStamp()
            if courseDateBlockMap.keys.contains(key) {
                if var item = courseDateBlockMap[key] {
                    item.append(block)
                    courseDateBlockMap[key] = item
                }
            } else {
                courseDateBlockMap[key] = [block]
            }
        }
        
        courseDateBlockMapSortedKeys = courseDateBlockMap.keys.sorted()
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
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseDateBlockMapSortedKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseDateViewCell.identifier, for: indexPath) as! CourseDateViewCell
        cell.selectionStyle = .none
        cell.accessibilityIdentifier = "CourseDatesViewController:table-cell"

        let index = indexPath.row
        let key = courseDateBlockMapSortedKeys[index]
        let item = courseDateBlockMap[key]
        let count = courseDateBlockMapSortedKeys.count
        
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
        
        guard let blocks = item else { return cell }
        
        cell.delegate = self
        
        if !setDueNext {
            cell.setDueNextOnThisBlock = true
        } else {
            cell.setDueNextOnThisBlock = false
        }
        cell.blocks = blocks
        
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }

extension CourseDatesViewController: CourseDateViewCellDelegate {
    func didSelectLinkWith(url: URL) {
        UIApplication.shared.openURL(url)
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
        datesResponse = data
        let blocks = data.courseDateBlocks
        
        courseDateBlockMap = [:]

        for block in blocks {
            let key = block.blockDate.stripTimeStamp()
            if courseDateBlockMap.keys.contains(key) {
                if var item = courseDateBlockMap[key] {
                    item.append(block)
                    courseDateBlockMap[key] = item
                }
            } else {
                courseDateBlockMap[key] = [block]
            }
        }
        
        courseDateBlockMapSortedKeys = courseDateBlockMap.keys.sorted()
        tableView.reloadData()
    }
}
