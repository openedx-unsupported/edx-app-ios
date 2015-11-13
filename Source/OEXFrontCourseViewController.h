//
//  OEXFrontCourseViewController.h
//  edXVideoLocker
//
//  Created by Nirbhay Agarwal on 16/05/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OEXAnalytics;
@class OEXConfig;
@class OEXInterface;
@class NetworkManager;
@class OEXRouter;

@interface OEXFrontCourseViewControllerEnvironment : NSObject

@property (strong, nonatomic) OEXAnalytics* analytics;
@property (strong, nonatomic) OEXConfig* config;
@property (strong, nonatomic) OEXInterface* interface;
@property (strong, nonatomic) NetworkManager* networkManager;
@property (weak, nonatomic) OEXRouter* router;

- (id)initWithAnalytics:(OEXAnalytics*)analytics
                 config:(OEXConfig*)config
              interface:(OEXInterface*)interface
         networkManager:(NetworkManager*)networkManager
                 router:(OEXRouter*)router;

@end

@interface OEXFrontCourseViewController : UIViewController

@property (strong, nonatomic) OEXFrontCourseViewControllerEnvironment* environment;

@end


NS_ASSUME_NONNULL_END
