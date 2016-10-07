//
//  OEXMyVideosViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014-2016 edX. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class NetworkManager;
@class OEXInterface;
@class OEXRouter;
@class RouterEnvironment;

@interface OEXMyVideosViewController : UIViewController

@property (strong, nonatomic) RouterEnvironment* environment;

@end

NS_ASSUME_NONNULL_END
