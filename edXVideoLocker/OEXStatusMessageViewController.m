//
//  OEXStatusMessageViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXStatusMessageViewController.h"

#define ERRORVIEW_X 0
#define ERRORVIEW_Y -80
#define ERRORVIEW_WIDTH 0
#define ERRORVIEW_HEIGHT 80

@interface OEXStatusMessageViewController ()

@property (nonatomic, assign) CGRect parentViewFrame;

@end

static OEXStatusMessageViewController* _sharedInterface = nil;

@implementation OEXStatusMessageViewController

+ (id)sharedInstance {
    if(!_sharedInterface) {
        _sharedInterface = [[OEXStatusMessageViewController alloc] init];
        _sharedInterface.messageY = 64;
    }

    return _sharedInterface;
}

- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
	// Custom initialization
    }
    return self;
}

#pragma mark Public Actions

- (void)showMessage:(NSString*)message
    onViewController:(UIView*)View
    messageY:(float)messageY
    shouldHide:(BOOL)hide {
	//Remove previous instance and animation
    [self removeSelfFromSuperView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

	//Set initial frame
    self.parentViewFrame = View.frame;
    _sharedInterface.view.frame = CGRectMake(_parentViewFrame.origin.x,
                                             _parentViewFrame.origin.y - ERRORVIEW_HEIGHT,
                                             ERRORVIEW_WIDTH,
                                             ERRORVIEW_HEIGHT);
    [View addSubview:_sharedInterface.view];

	//Pass data
    self.statusLabel.text = message;
    _sharedInterface.errorMsgShouldHide = hide;

    self.messageY = messageY;

	//Animate
    [_sharedInterface animationDrop];
}

- (void)showMessage:(NSString*)message
    onViewController:(UIView*)View
    messageY:(float)messageY
    components:(NSArray*)comps
    shouldHide:(BOOL)hide {
	//Remove previous instance and animation
    [self removeSelfFromSuperView];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

	//Set initial frame
    self.parentViewFrame = View.frame;
    _sharedInterface.view.frame = CGRectMake(_parentViewFrame.origin.x,
                                             _parentViewFrame.origin.y - ERRORVIEW_HEIGHT,
                                             ERRORVIEW_WIDTH,
                                             ERRORVIEW_HEIGHT);
    [View addSubview:_sharedInterface.view];

    for(UIView* objects in comps) {
        [View bringSubviewToFront:objects];
    }

	//Pass data
    self.statusLabel.text = message;
    _sharedInterface.errorMsgShouldHide = hide;

    self.messageY = messageY;

	//Animate
    [_sharedInterface animationDrop];
}

#pragma mark Animation

- (void)animationDrop {
    [UIView animateWithDuration:ANI_DURATION
     delay:0.0
     usingSpringWithDamping:1.0
     initialSpringVelocity:0.1
     options:UIViewAnimationOptionCurveEaseIn
     animations:^{
         _sharedInterface.view.frame = CGRectMake(_parentViewFrame.origin.x,
                                                  _parentViewFrame.origin.y + _messageY,
                                                  ERRORVIEW_WIDTH,
                                                  ERRORVIEW_HEIGHT);
     } completion:^(BOOL finished) {
         [self performSelector:@selector(animationUp) withObject:nil afterDelay:ANI_ERROR_TIMEOUT];
     }];
}

- (void)animationUp {
    [UIView animateWithDuration:ANI_DURATION
     delay:0.0
     usingSpringWithDamping:1.0
     initialSpringVelocity:0.1
     options:UIViewAnimationOptionCurveEaseOut
     animations:^{
         _sharedInterface.view.frame = CGRectMake(_parentViewFrame.origin.x,
                                                  _parentViewFrame.origin.y - ERRORVIEW_HEIGHT,
                                                  ERRORVIEW_WIDTH,
                                                  ERRORVIEW_HEIGHT);
     } completion:^(BOOL finished) {
     }];
}

- (void)removeSelfFromSuperView {
    [self.view removeFromSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self errorMessagesAccessibilityIdentifiers];
	// Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    ELog(@"MemoryWarning StatusMessageViewController");

    [super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

-(void)errorMessagesAccessibilityIdentifiers {
    self.statusLabel.accessibilityLabel = @"floatingMessages";
}
@end
