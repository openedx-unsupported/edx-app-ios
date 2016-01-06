//
//  CoursesTableViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class CourseCardCell : UITableViewCell {
    static let margin = StandardVerticalMargin
    
    private static let cellIdentifier = "CourseCardCell"
    private let courseView = CourseCardView(frame: CGRectZero)
    private var course : OEXCourse?
    private let courseCardBorderStyle = BorderStyle()
    
    override init(style : UITableViewCellStyle, reuseIdentifier : String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(courseView)
        
        courseView.snp_makeConstraints {make in
            make.top.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(self.contentView).offset(-CourseCardCell.margin)
        }
        
        courseView.applyBorderStyle(courseCardBorderStyle)
        
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.selectionStyle = .None
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol CoursesTableViewControllerDelegate : class {
    func coursesTableChoseCourse(course : OEXCourse)
}

class CoursesTableViewController: UITableViewController {
    
    enum Context {
        case CourseCatalog
        case EnrollmentList
    }
    
    typealias Environment = protocol<NetworkManagerProvider>
    
    private let environment : Environment
    private let context: Context
    
    weak var delegate : CoursesTableViewControllerDelegate?
    var courses : [OEXCourse] = []
    let insetsController = ContentInsetsController()
    
    init(environment : Environment, context: Context) {
        self.context = context
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .None
        self.tableView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.tableView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerClass(CourseCardCell.self, forCellReuseIdentifier: CourseCardCell.cellIdentifier)
        
        self.insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courses.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let course = self.courses[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CourseCardCell.cellIdentifier, forIndexPath: indexPath) as! CourseCardCell
        cell.courseView.tapAction = {[weak self] card in
            self?.delegate?.coursesTableChoseCourse(course)
        }
        
        switch context {
        case .CourseCatalog:
            CourseCardViewModel.onCourseCatalog(course).apply(cell.courseView, networkManager: self.environment.networkManager)
        case .EnrollmentList:
            CourseCardViewModel.onHome(course).apply(cell.courseView, networkManager: self.environment.networkManager)
        }
        cell.course = course

        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
}
