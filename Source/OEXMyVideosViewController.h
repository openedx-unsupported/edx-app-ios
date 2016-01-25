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

@interface OEXMyVideosViewControllerEnvironment : NSObject

- (id)initWithInterface:(OEXInterface*)interface networkManager:(NetworkManager*)networkManager router:(OEXRouter*)router;

@property (strong, nonatomic) OEXInterface* interface;
@property (strong, nonatomic) NetworkManager* networkManager;
@property (weak, nonatomic, nullable) OEXRouter* router;

@end

@interface OEXMyVideosViewController : UIViewController

@property (strong, nonatomic) OEXMyVideosViewControllerEnvironment* environment;

@end

NS_ASSUME_NONNULL_END
