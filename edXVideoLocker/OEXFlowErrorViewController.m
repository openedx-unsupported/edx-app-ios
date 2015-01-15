//
//  OEXFlowErrorViewController.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 28/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXFlowErrorViewController.h"

#define ERRORVIEW_X 0
#define ERRORVIEW_Y -98
#define ERRORVIEW_WIDTH 0
#define ERRORVIEW_HEIGHT 100

@interface OEXFlowErrorViewController ()

- (void)setErrorTitle:(NSString *)title WithMessage:(NSString *)message;

@property (nonatomic, assign) CGRect parentViewFrame;

@end

static OEXFlowErrorViewController * _sharedInterface = nil;

@implementation OEXFlowErrorViewController

+ (id)sharedInstance
{
    if (!_sharedInterface) {
        _sharedInterface = [[OEXFlowErrorViewController alloc] init];
    }
    
    return _sharedInterface;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

#pragma mark Public Actions

- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message onViewController:(UIView *)View shouldHide:(BOOL)hide
{
    
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
    [_sharedInterface setErrorTitle:title WithMessage:message];
    _sharedInterface.errorMsgShouldHide = hide;
    
    //Animate
    [_sharedInterface animationDrop];
}

#pragma Logic

- (void)setErrorTitle:(NSString *)title WithMessage:(NSString *)message
{
    self.lbl_ErrorTitle.text = title;
    self.lbl_ErrorMessage.text = message;
}

#pragma mark Animation

- (void)animationDrop
{
    [UIView animateWithDuration:ANI_DURATION
                          delay:0.0
         usingSpringWithDamping:0.5
          initialSpringVelocity:0.1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         _sharedInterface.view.frame = CGRectMake(_parentViewFrame.origin.x,
                                                                  _parentViewFrame.origin.y,
                                                                  ERRORVIEW_WIDTH,
                                                                  ERRORVIEW_HEIGHT);
                     } completion:^(BOOL finished) {
                         [self performSelector:@selector(animationUp) withObject:nil afterDelay:ANI_ERROR_TIMEOUT];
                     }];
}

- (void)animationUp
{
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

- (void)removeSelfFromSuperView
{
    [self.view removeFromSuperview];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
}

- (void)didReceiveMemoryWarning
{

    ELog(@"MemoryWarning FlowErrorViewController");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
