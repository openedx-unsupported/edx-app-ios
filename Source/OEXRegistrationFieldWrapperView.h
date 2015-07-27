//
//  OEXRegistrationFieldError.h
//  edXVideoLocker
//
//  Created by Rahul Varma on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXRegistrationFieldWrapperView : UIView

- (void)setRegistrationErrorMessage:(NSString*)errorMessage instructionMessage:(NSString*)instructionMessage;
@end
