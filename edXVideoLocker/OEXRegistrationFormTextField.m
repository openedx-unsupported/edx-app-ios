//
//  OEXRegistrationFormTextField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormTextField.h"
#import "OEXRegistrationFieldWrapperView.h"

@interface OEXRegistrationFormTextField ()
{
    OEXRegistrationFieldWrapperView *registrationWrapper;
}
@end

static NSString *const textFieldBackgoundImage=@"bt_grey_default.png";
static NSInteger const textFieldHeight=40;
@implementation OEXRegistrationFormTextField
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        inputView=[[UITextField alloc] initWithFrame:CGRectZero];
        inputView.font=[UIFont fontWithName:@"OpenSans" size:13.f];
        inputView.textColor=[UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:1.0];
        inputView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [inputView setBackground:[UIImage imageNamed:textFieldBackgoundImage]];
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        inputView.leftView = paddingView;
        inputView.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:inputView];
        registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:registrationWrapper];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    CGFloat paddingHorizontal=20;
    CGFloat frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    NSInteger paddingTop=0;
    CGFloat offset=paddingTop;
    CGFloat paddingBottom=10;
    [inputView setFrame:CGRectMake(paddingHorizontal,paddingTop,frameWidth,textFieldHeight)];
    [inputView setPlaceholder:self.placeholder];
    offset=offset+textFieldHeight;
    [registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [registrationWrapper setNeedsLayout];
    [registrationWrapper layoutIfNeeded];
    [registrationWrapper setFrame:CGRectMake(0,offset,self.bounds.size.width,registrationWrapper.frame.size.height)];
    if([self.errorMessage length]>0 || [self.instructionMessage length]>0 )
    {
        offset=offset+registrationWrapper.frame.size.height;
    }
    CGRect frame=self.frame;
    frame.size.height=offset+paddingBottom;
    self.frame=frame;
}

-(NSString *)currentValue{
    return inputView.text;
}

-(void)clearError{
    self.errorMessage=nil;
}

-(void)setErrorMessage:(NSString *)errorMessage{
    _errorMessage=errorMessage;
    [registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [registrationWrapper layoutIfNeeded];
    [self setNeedsLayout];
}


@end
