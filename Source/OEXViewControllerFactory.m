//
//  OEXViewControllerFactory.m
//  edX
//
//  Created by Ehmad Zubair Chughtai on 24/04/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXViewControllerFactory.h"

@implementation OEXViewControllerFactory

+ (OEXDownloadViewController *) instantiateDownloadViewControllerFromFrontViews: (BOOL) isFromFrontViews isFromGenericViews:(BOOL) isFromGenericViews{
    
    OEXDownloadViewController *vc = [[UIStoryboard storyboardWithName:@"OEXDownload" bundle:nil] instantiateViewControllerWithIdentifier:@"OEXDownloadViewController"];
    if(isFromFrontViews)
    {
        vc.isFromFrontViews = isFromFrontViews;
    }
    if (isFromGenericViews)
    {
        vc.isFromGenericViews = isFromGenericViews;
    }
    return vc;
}

@end
