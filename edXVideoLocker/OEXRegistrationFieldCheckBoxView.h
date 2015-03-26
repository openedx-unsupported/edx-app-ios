//
//  OEXRegistrationFieldCheckBoxView.h
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OEXRegistrationFieldCheckBoxView : UIView
{
    UIButton* inputView;
    UILabel* errorLabel;
    UILabel* instructionLabel;
}

- (void)takeValue:(BOOL)value;

@property(nonatomic, strong) NSString* errorMessage;
@property(nonatomic, strong) NSString* instructionMessage;
@property(nonatomic, strong) NSString* label;
- (void)clearError;
- (BOOL )currentValue;

@end