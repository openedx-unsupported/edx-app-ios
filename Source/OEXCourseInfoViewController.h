//
//  OEXCourseInfoViewController.h
//  edXVideoLocker
//
//  Created by Abhradeep on 03/02/15.
//  Copyright (c) 2015-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN
@class RouterEnvironment;

@interface OEXCourseInfoViewController : UIViewController

- (instancetype)initWithEnvironment:(RouterEnvironment* _Nullable)environment pathID:(NSString*)pathID bottomBar:(nullable UIView*) bottomBar;
- (void)showMainScreenWithMessage:(NSString*)message courseID:(NSString*)courseID;
@end

NS_ASSUME_NONNULL_END
