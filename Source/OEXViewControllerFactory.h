//
//  OEXViewControllerFactory.h
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/04/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OEXDownloadViewController.h"

@interface OEXViewControllerFactory : NSObject

+ (OEXDownloadViewController *) instantiateDownloadViewControllerFromFrontViews: (BOOL) isFromFrontViews isFromGenericViews:(BOOL) isFromGenericViews;

@end
