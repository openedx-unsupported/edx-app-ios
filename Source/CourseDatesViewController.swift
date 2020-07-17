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
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & OEXSessionProvider & OEXStylesProvider & ReachabilityProvider & NetworkManagerProvider
    
    private let datesLoader = BackedStream<(CourseDateModel)>()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.register(TimelineTableViewCell.self, forCellReuseIdentifier: TimelineTableViewCell.identifier)
        
        return tableView
    }()
    
    private var datesResponse: CourseDateModel?
    
    private var blocks: [CourseDateBlock] = []
    
    private let courseID: String
    private let environment: Environment
    
    init(environment: Environment, courseID: String) {
        self.courseID = courseID
        self.environment = environment
        super.init(nibName: nil, bundle :nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        navigationItem.title = Strings.Coursedates.courseImportantDatesTitle
        
        setConstraints()
        tableView.reloadData()
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
                break
            }
        }
    }
    
    private func handleResponse(data: CourseDateModel) {
        datesResponse = data
        blocks = data.courseDateBlocks
        
        let past = blocks.filter { $0.isInPast }
        let future = blocks.filter { $0.isInFuture }
        
        let todayBlock = CourseDateBlock.init(date: Date())
        
        blocks.removeAll()
        
        blocks.append(contentsOf: past)
        blocks.append(todayBlock)
        blocks.append(contentsOf: future)
        
        var dictionary = [String : CourseDateBlock]()
        
        for block in blocks {
            let key = block.dateText
            if dictionary.keys.contains(key) {
                if let item = dictionary[key] {
                    let titleLink: [String: String] = [block.title : block.link]
                    item.titleAndLinks.append(titleLink)
                    
//                    item.titles.append(block.title)
//                    item.links.append(block.link)
                    //item.title = item.title + "\n" + block.title
                }
            } else {
                let titleLink: [String: String] = [block.title : block.link]
                block.titleAndLinks.append(titleLink)
                
                dictionary[key] = block
            }
        }
        
        
        blocks.removeAll()
        blocks = dictionary.values.map { $0 }
        blocks.sort { $0.blockDate < $1.blockDate }
        
        //print(blocks)
        //print(b)
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
    }
}

extension CourseDatesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = blocks[indexPath.row]
        
        if item.descriptionField.isEmpty {
            return 60
        }
        return tableView.estimatedRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimelineTableViewCell.identifier, for: indexPath) as! TimelineTableViewCell
        cell.selectionStyle = .none
        
        let index = indexPath.row
        let item = blocks[index]
        let count = blocks.count
        
        cell.timeline.topColor = .clear
        cell.timeline.bottomColor = .clear
        
        if index == 0 {
            cell.timeline.topColor = .clear
            cell.timeline.bottomColor = .black
        } else if index == count - 1 {
            cell.timeline.topColor = .black
            cell.timeline.bottomColor = .clear
        } else {
            cell.timeline.topColor = .black
            cell.timeline.bottomColor = .black
        }
        
        if item.isInPast {
            cell.timelinePoint.color = .lightGray
            cell.timelinePoint.diameter = 10
        } else if item.isInFuture {
            cell.timelinePoint.color = .black
            cell.timelinePoint.diameter = 10
        }
        
        cell.drawTimelineView()
        if item.dateText.contains(find: "6") {
            print("yo")
        }
        cell.dateStatus = item.blockStatus
        cell.dateText = item.dateText
        cell.titleAndLink = item.titleAndLinks
        cell.descriptionText = item.descriptionField
        
        cell.sizeToFit()
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }

extension Array {
    func uniques<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        return reduce([]) { result, element in
            let alreadyExists = (result.contains(where: { $0[keyPath: keyPath] == element[keyPath: keyPath] }))
            return alreadyExists ? result : result + [element]
        }
    }
}
