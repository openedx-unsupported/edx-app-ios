//
//  OEXCourseDashboardViewController.m
//  edX
//
//  Created by Akiva Leffert on 4/28/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCourseDashboardViewController.h"

#import "UIControl+OEXBlockActions.h"
#import "OEXConfig.h"
#import "OEXCourse.h"
#import "OEXRouter.h"

#import <Masonry/Masonry.h>

@implementation OEXCourseDashboardViewControllerEnvironment

- (id)initWithConfig:(OEXConfig *)config router:(OEXRouter *)router {
    self = [super init];
    if(self != nil) {
        _config = config;
        _router = router;
    }
    return self;
}

@end

@interface OEXCourseDashboardViewController ()

@property (strong, nonatomic) OEXCourseDashboardViewControllerEnvironment* environment;
@property (strong, nonatomic) OEXCourse* course;

@property (strong, nonatomic) UIButton* discussionsButton;

@end

@implementation OEXCourseDashboardViewController

- (id)initWithEnvironment:(OEXCourseDashboardViewControllerEnvironment *)environment course:(OEXCourse*)course {
    if(self != nil) {
        self.environment = environment;
        self.course = course;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self makeStubUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

// All of this UI is temporary. Will be replaced once there's a design spec
- (void)makeStubUI {
    self.view.backgroundColor = [UIColor whiteColor];
    
    __weak __typeof(self) weakself = self;
    NSMutableArray* buttons = [[NSMutableArray alloc] init];
    
    UIButton* coursewareButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [coursewareButton setTitle:@"Cøürseware!" forState:UIControlStateNormal];
    [coursewareButton oex_addAction:^(UIControl *control) {
        [weakself showCourseware];
    } forEvents:UIControlEventTouchUpInside];
    [buttons addObject:coursewareButton];
    
    UIButton* announcementsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [announcementsButton setTitle:@"Ånnouncements!" forState:UIControlStateNormal];
    [announcementsButton oex_addAction:^(UIControl *control) {
        [weakself showAnnouncements];
    } forEvents:UIControlEventTouchUpInside];
    [buttons addObject:announcementsButton];
    
    UIButton* handoutsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [handoutsButton setTitle:@"Handøüts!" forState:UIControlStateNormal];
    [handoutsButton oex_addAction:^(UIControl *control) {
        [weakself showHandouts];
    } forEvents:UIControlEventTouchUpInside];
    [buttons addObject:handoutsButton];
    
    if([self.environment.config shouldEnableDiscussions]) {
        self.discussionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.discussionsButton setTitle:@"Discussiøns!" forState:UIControlStateNormal];
        [self.discussionsButton oex_addAction:^(UIControl *control) {
            [weakself showDiscussions];
        } forEvents:UIControlEventTouchUpInside];
        
        [buttons addObject:self.discussionsButton];
    }
    
    UIView* container = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:container];
    
    UIButton* prev = nil;
    for(UIButton* button in buttons) {
        [container addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            if(prev) {
                make.top.equalTo(prev.mas_bottom).offset(20);
            }
            make.centerX.equalTo(container);
        }];
        prev = button;
    }
    
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.top.equalTo([buttons firstObject]);
        make.bottom.equalTo([buttons lastObject]);
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
    }];

}

- (void)showCourseware {
    [self.environment.router showCoursewareForCourseWithID:self.course.course_id fromController:self];
}

- (void)showDiscussions {
    // TODO
}

- (void)showAnnouncements {
    // TODO
}

- (void)showHandouts {
    // TODO
}

@end

@implementation OEXCourseDashboardViewController (Testing)

- (BOOL)t_canVisitDicussions {
    return self.discussionsButton.superview != nil;
}

@end