//
//  OEXRegistrationFieldSelectView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationOption.h"
@interface OEXRegistrationFieldSelectView : OEXRegistrationFormTextField

@property(nonatomic,strong)NSArray *options;

-(OEXRegistrationOption *)selected;

@end
