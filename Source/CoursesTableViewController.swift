//
//  CoursesTableViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCardCell : UITableViewCell {
    private static let cellIdentifier = "CourseCardCell"
    private let courseView = CourseCardView(frame: CGRectZero)
    private var course : OEXCourse?
    private let courseCardMargin = 8
    private let courseCardBorderStyle = BorderStyle()
    
    override init(style : UITableViewCellStyle, reuseIdentifier : String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(courseView)
        
        courseView.snp_makeConstraints {make in
            make.top.equalTo(self.contentView).offset(courseCardMargin)
            make.bottom.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(courseCardMargin)
            make.trailing.equalTo(self.contentView).offset(-courseCardMargin)
        }
        
        courseView.applyBorderStyle(courseCardBorderStyle)
        
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CoursesTableViewControllerDelegate : class {
    func coursesTableChoseCourse(course : OEXCourse)
}

class CoursesTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    typealias Environment = NetworkManagerProvider
    
    private var environment : Environment
    weak var delegate : CoursesTableViewControllerDelegate?
    
    private lazy var tableView = UITableView()
    private lazy var loadController = LoadStateViewController()
    private let courseStream : Stream<[OEXCourse]>
    
    init(environment: Environment, courseStream : Stream<[OEXCourse]>) {
        self.courseStream = courseStream
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .None
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        self.tableView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        courseStream.listen(self, success:
            {[weak self] courses in
                self?.loadController.state = .Loaded
                self?.tableView.reloadData()
            }, failure: {error in
                self.loadController.state = LoadState.failed(error)
            }
        )
        
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerClass(CourseCardCell.self, forCellReuseIdentifier: CourseCardCell.cellIdentifier)
        
        loadController.setupInController(self, contentView: self.tableView)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courseStream.value?.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let course = self.courseStream.value![indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CourseCardCell.cellIdentifier, forIndexPath: indexPath) as! CourseCardCell
        cell.courseView.tapAction = {[weak self] card in
            self?.delegate?.coursesTableChoseCourse(course)
        }
        
        CourseCardViewModel.onCourseCatalog(course).apply(cell.courseView, networkManager: self.environment.networkManager)
        cell.course = course

        return cell
    }

}
