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
    private let loadController: LoadStateViewController

    private var datesResponse: CourseDateModel?
    private var courseDateBlockMap = [Date : [CourseDateBlock]]()
    private var courseDateBlockMapSortedKeys = [Dictionary<Date, [CourseDateBlock]>.Keys.Element]()
    
    private let courseID: String
    private let environment: Environment
    
    init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        
        loadController.setupInController(controller: self, contentView: tableView)

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
        
        courseDateBlockMap = [Date : [CourseDateBlock]]()
        
        blocks.forEach { print($0.blockStatus) }
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
        
        courseDateBlockMapSortedKeys = Array(courseDateBlockMap.keys).sorted()
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
        
        let index = indexPath.row
        let key = courseDateBlockMapSortedKeys[index]
        let item = courseDateBlockMap[key]
        let count = courseDateBlockMapSortedKeys.count
        
        cell.timeline.topColor = .clear
        cell.timeline.bottomColor = .clear
        
        if index == 0 {
            cell.timeline.topColor = .clear
            cell.timeline.bottomColor = OEXStyles.shared().neutralXDark()
        } else if index == count - 1 {
            cell.timeline.topColor = OEXStyles.shared().neutralXDark()
            cell.timeline.bottomColor = .clear
        } else {
            cell.timeline.topColor = OEXStyles.shared().neutralXDark()
            cell.timeline.bottomColor = .black
        }
        
        guard let blocks = item else { return cell }
        cell.delegate = self
        cell.blocks = blocks
        cell.accessibilityIdentifier = "CourseDatesViewController:table-cell"
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }

extension CourseDatesViewController: CourseDateViewCellDelegate {
    func didSelectLinkWith(url: URL) {
        UIApplication.shared.openURL(url)
    }
}

// For use in testing only
extension CourseDatesViewController {
    func t_loadData(data: CourseDateModel) {
        handleResponse(data: data)
    }
}
