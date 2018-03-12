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
    
    fileprivate static let cellIdentifier = "CourseCardCell"
    fileprivate let courseView = CourseCardView(frame: CGRect.zero)
    fileprivate var course : OEXCourse?
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
        
        courseView.applyBorderStyle(style: courseCardBorderStyle)
        
        self.contentView.backgroundColor = OEXStyles.shared().neutralXLight()
        
        self.selectionStyle = .none
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
    
    typealias Environment = NetworkManagerProvider
    
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
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = OEXStyles.shared().neutralXLight()
        self.tableView.accessibilityIdentifier = "courses-table-view"
        
        self.tableView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(CourseCardCell.self, forCellReuseIdentifier: CourseCardCell.cellIdentifier)
        
        self.insetsController.addSource(
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let course = self.courses[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseCardCell.cellIdentifier, for: indexPath as IndexPath) as! CourseCardCell
        DispatchQueue.main.async {
            cell.accessibilityLabel = cell.courseView.updateAcessibilityLabel()
        }
        cell.accessibilityHint = Strings.accessibilityShowsCourseContent
        cell.courseView.tapAction = {[weak self] card in
            self?.delegate?.coursesTableChoseCourse(course: course)
        }
        
        switch context {
        case .CourseCatalog:
            CourseCardViewModel.onCourseCatalog(course: course, wrapTitle: true).apply(card: cell.courseView, networkManager: self.environment.networkManager)
        case .EnrollmentList:
            CourseCardViewModel.onHome(course: course).apply(card: cell.courseView, networkManager: self.environment.networkManager)
        }
        cell.course = course
        
        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
}

