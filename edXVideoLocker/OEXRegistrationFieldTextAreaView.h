//
//  OEXRegistrationFormTextAreaView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OEXTextView.h"
@interface OEXRegistrationFieldTextAreaView : UIView
{
    OEXTextView   *inputView;
    UILabel      *errorLabel;
    UILabel      *instructionLabel;
}

@property(nonatomic,strong)NSString *errorMessage;
@property(nonatomic,strong)NSString *instructionMessage;
@property(nonatomic,strong)NSString *placeholder;
-(void)clearError;
-(NSString *)currentValue;
@end
