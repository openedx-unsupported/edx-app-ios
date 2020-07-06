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
        
        stream.listen(self, success: { data in
            print(data)
        }, failure: { error in
            print(error.localizedDescription)
        })
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
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.estimatedRowHeight
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TimelineTableViewCell.identifier, for: indexPath) as! TimelineTableViewCell
        cell.selectionStyle = .none
 
        cell.timeline.topColor = .clear
        cell.timeline.bottomColor = .clear
        cell.timelinePoint.color = .black
        
        if indexPath.row == 0 {
            cell.timeline.bottomColor = .black
        }
        if indexPath.row != 0 {
            cell.timeline.topColor = .black
            cell.timeline.bottomColor = .black
        }
        
        if indexPath.row == 2 {
            cell.timelinePoint.color = .yellow
            cell.timelinePoint.strokeColor = .black
            cell.timelinePoint.diameter = 12
        }
        
        if indexPath.row == 4 {
            cell.timeline.bottomColor = .clear
        }
        
        cell.dateText = "Fri, July 3, 2020"
        cell.titleText = "Upgrade to Verified Certificate"
        cell.descriptionText = "Don't miss the opportunity to highlight your new knowledge and skills by earning a verified certificate"
        
        return cell
    }
}

extension CourseDatesViewController: UITableViewDelegate { }
