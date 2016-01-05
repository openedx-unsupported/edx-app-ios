//
//  CourseCatalogDetailView.swift
//  edX
//
//  Created by Akiva Leffert on 12/7/15.
//  Copyright © 2015 edX. All rights reserved.
//

struct CourseDetailField {
    let name : String
    let value : String
    let icon : Icon
}

private let margin : CGFloat = 20

class CourseCatalogDetailView : UIView, UIWebViewDelegate {
    
    typealias Environment = NetworkManagerProvider
    
    private let environment : Environment
    
    private let courseCard = CourseCardView()
    private let blurbLabel = UILabel()
    private let enrollButton = SpinnerButton(type: .System)
    private let container : TZStackView
    private let insetContainer : TZStackView
    private let descriptionHeader = UILabel()
    private let descriptionContainer : TZStackView
    // Need to use UIWebView since WKWebView isn't consistently calculating content height
    private let descriptionView = UIWebView()
    private let fieldsList = TZStackView()
    private let playButton = UIButton(type: .System)
    
    var enrollAction: ((completion : () -> Void) -> Void)?
    
    private var _loaded = Sink<()>()
    var loaded : Stream<()> {
        return _loaded
    }
    
    init(frame: CGRect, environment: Environment) {
        self.descriptionContainer = TZStackView(arrangedSubviews: [descriptionHeader, descriptionView])
        self.insetContainer = TZStackView(arrangedSubviews: [blurbLabel, enrollButton, fieldsList, descriptionContainer])
        self.container = TZStackView(arrangedSubviews: [courseCard, insetContainer])
        self.environment = environment
        
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        self.addSubview(container)
        container.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
        container.spacing = margin
        for stack in [container, fieldsList, insetContainer, descriptionContainer] {
            stack.axis = .Vertical
            stack.alignment = .Fill
        }
        
        insetContainer.layoutMarginsRelativeArrangement = true
        insetContainer.layoutMargins = UIEdgeInsetsMake(0, margin, 0, margin)
        insetContainer.spacing = margin
        
        fieldsList.layoutMarginsRelativeArrangement = true
        
        blurbLabel.numberOfLines = 0
        
        enrollButton.applyButtonStyle(OEXStyles.sharedStyles().filledEmphasisButtonStyle, withTitle: Strings.CourseDetail.enrollNow)
        enrollButton.oex_addAction({[weak self] _ in
            self?.enrollButton.showProgress = true
            self?.enrollAction?( completion: { self?.enrollButton.showProgress = false } )
            }, forEvents: .TouchUpInside)
        descriptionContainer.spacing = StandardVerticalMargin
        descriptionHeader.attributedText = descriptionHeaderStyle.attributedStringWithText(Strings.CourseDetail.descriptionHeader)
        descriptionView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        descriptionView.snp_makeConstraints { make in
            // Need to give it an initial height so it will layout properly
            make.height.equalTo(1)
        }
        descriptionView.delegate = self
        descriptionView.scrollView.scrollEnabled = false
        descriptionView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        descriptionView.scrollView.oex_addObserver(self, forKeyPath: "contentSize") { (observer, descriptionView, size) -> Void in
            observer.setNeedsUpdateConstraints()
        }
        
        playButton.setImage(Icon.CourseVideoPlay.imageWithFontSize(60), forState: .Normal)
        playButton.tintColor = OEXStyles.sharedStyles().neutralWhite()
        playButton.layer.shadowOpacity = 0.5
        playButton.layer.shadowRadius = 3
        playButton.layer.shadowOffset = CGSizeZero
        courseCard.addCenteredOverlay(playButton)
    }
    
    override func updateConstraints() {
        let size = descriptionView.scrollView.contentSize
        // Need to give it a non-zero height so it will layout properly
        let height = size.height > 0 ? size.height : 1
        
        descriptionView.snp_updateConstraints {make in
            make.height.equalTo(height)
        }
        super.updateConstraints()
    }
    
    private var blurbStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var descriptionHeaderStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Bold, size: .Large, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private func fieldSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = OEXStyles.sharedStyles().neutralLight()
        view.snp_makeConstraints {make in
            make.height.equalTo(OEXStyles.dividerSize())
        }
        return view
    }
    
    var blurbText : String? {
        didSet {
            if let blurb = blurbText where !blurb.isEmpty {
                self.blurbLabel.attributedText = blurbStyle.attributedStringWithText(blurb)
                self.blurbLabel.hidden = false
            }
            else {
                self.blurbLabel.hidden = true
            }
        }
    }
    
    var descriptionHTML : String? {
        didSet {
            guard let html = OEXStyles.sharedStyles().styleHTMLContent(descriptionHTML, stylesheet: "inline-content") else {
                self.descriptionContainer.hidden = true
                self.descriptionView.loadHTMLString("", baseURL: environment.networkManager.baseURL)
                return
            }
            
            self.descriptionContainer.hidden = false
            self.descriptionView.loadHTMLString(html, baseURL: environment.networkManager.baseURL)
        }
    }
    
    var fields : [CourseDetailField] = [] {
        didSet {
            for view in self.fieldsList.arrangedSubviews {
                view.removeFromSuperview()
            }
            let views = fields.map{ viewForField($0) }.interpose { fieldSeparator() }
            
            for view in views {
                fieldsList.addArrangedSubview(view)
            }
        }
    }
    
    func viewForField(field : CourseDetailField) -> UIView {
        let view = ChoiceLabel()
        view.titleText = field.name
        view.valueText = field.value
        view.icon = field.icon
        return view
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        _loaded.send(())
    }
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let URL = request.URL where navigationType != .Other {
            UIApplication.sharedApplication().openURL(URL)
            return false
        }
        return true
    }
}

extension CourseCatalogDetailView {
    
    private func fieldsForCourse(course : OEXCourse) -> [CourseDetailField] {
        var result : [CourseDetailField] = []
        if let effort = course.effort where !effort.isEmpty {
            result.append(CourseDetailField(name: Strings.CourseDetail.effort, value: effort, icon: .CourseEffort))
        }
        if let endDate = course.end where !course.isStartDateOld {
            let date = OEXDateFormatting.formatAsMonthDayYearString(endDate)
            result.append(CourseDetailField(name: Strings.CourseDetail.endDate, value: date, icon: .CourseEnd))
        }
        return result
    }
    
    func applyCourse(course : OEXCourse) {
        CourseCardViewModel.onCourseCatalog(course).apply(courseCard, networkManager: self.environment.networkManager)
        self.blurbText = course.short_description
        self.descriptionHTML = course.overview_html
        let fields = fieldsForCourse(course)
        self.fields = fields
        self.playButton.hidden = course.courseVideoMediaInfo?.uri?.isEmpty ?? true
        self.playButton.oex_removeAllActions()
        self.playButton.oex_addAction(
            {[weak self] _ in
                if let
                    path = course.courseVideoMediaInfo?.uri,
                    url = NSURL(string: path, relativeToURL: self?.environment.networkManager.baseURL)
                {
                    UIApplication.sharedApplication().openURL(url)
                }
            }, forEvents: .TouchUpInside)
    }
}

// Testing
extension CourseCatalogDetailView {
    var t_showingEffort : Bool {
        return self.fields.contains {(field : CourseDetailField) in field.icon == .CourseEffort }
    }
    
    var t_showingEndDate : Bool {
        return self.fields.contains {(field : CourseDetailField) in field.icon == .CourseEnd }
    }
    
    var t_showingPlayButton : Bool {
        return !self.playButton.hidden
    }
    
    var t_showingShortDescription : Bool {
        return !self.blurbLabel.hidden
    }
}

