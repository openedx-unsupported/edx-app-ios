//
//  OEXMyVideosViewController.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 27/06/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NetworkManager;
@class OEXInterface;
@class OEXRouter;

@interface OEXMyVideosViewControllerEnvironment : NSObject

- (id)initWithInterface:(OEXInterface*)interface networkManager:(NetworkManager*)networkManager router:(OEXRouter*)router;

@property (strong, nonatomic) OEXInterface* interface;
@property (strong, nonatomic) NetworkManager* networkManager;
@property (weak, nonatomic) OEXRouter* router;

@end

@interface OEXMyVideosViewController : UIViewController

@property (strong, nonatomic) OEXMyVideosViewControllerEnvironment* environment;

@end
