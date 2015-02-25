//
//  OEXUserLicenseAgreementViewController.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OEXRegistrationAgreement;
@interface OEXUserLicenseAgreementViewController : UIViewController
@property(nonatomic,strong)NSURL *contentUrl;
@property(nonatomic,copy)NSString *agreementTitle;
@end
