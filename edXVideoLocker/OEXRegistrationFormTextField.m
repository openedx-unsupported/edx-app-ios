//
//  OEXRegistrationFormTextField.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFormTextField.h"

@interface OEXRegistrationFormTextField ()
@end

static NSString *const textFieldBackgoundImage=@"bt_grey_default.png";
static NSInteger const textFieldHeight=40;

@implementation OEXRegistrationFormTextField

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        inputView=[[UITextField alloc] initWithFrame:CGRectZero];
        inputView.font=[UIFont fontWithName:@"OpenSans-Semibold" size:13.f];
        [inputView setBackground:[UIImage imageNamed:textFieldBackgoundImage]];
        
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 40)];
        
        inputView.leftView = paddingView;
        inputView.leftViewMode = UITextFieldViewModeAlways;
        [self addSubview:inputView];
        
        errorLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        errorLabel.numberOfLines=0;
        errorLabel.lineBreakMode=NSLineBreakByWordWrapping;
        errorLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        errorLabel.textColor=[UIColor redColor];
      //  [errorLabel setBackgroundColor:[UIColor yellowColor]];
        [self addSubview:errorLabel];
        
        instructionLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        instructionLabel.lineBreakMode=NSLineBreakByWordWrapping;
        instructionLabel.numberOfLines=0;
        instructionLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        //[instructionLabel setBackgroundColor:[UIColor redColor]];
        [self addSubview:instructionLabel];
    }
    return self;
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    CGFloat paddingHorizontal=20;
    CGFloat frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    NSInteger paddingTop=0;
    NSInteger spacingTextFieldAndLabel=3;
    CGFloat offset=paddingTop;
    CGFloat paddingBottom=10;
    
    [inputView setFrame:CGRectMake(paddingHorizontal,paddingTop,frameWidth,textFieldHeight)];
    [inputView setPlaceholder:self.placeholder];
    offset=offset+textFieldHeight;
    if([self.errorMessage length]>0){
        
        offset=offset+spacingTextFieldAndLabel;
        NSDictionary *attributes = @{NSFontAttributeName:errorLabel.font};
        errorLabel.text=self.errorMessage;
        CGRect rect = [self.errorMessage boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attributes
                                                      context:nil];
        [errorLabel setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,rect.size.height)];
        offset=offset+rect.size.height;
        
    }else{
        offset=offset+spacingTextFieldAndLabel;
        [errorLabel setFrame:CGRectZero];
    }
    
    if([self.instructionMessage length]>0){
        NSDictionary *attributes = @{NSFontAttributeName:instructionLabel.font};
        CGRect rect = [self.instructionMessage boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                         attributes:attributes
                                                            context:nil];
        instructionLabel.text=self.instructionMessage;
        [instructionLabel setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,rect.size.height)];
        
        offset=offset+rect.size.height;
    }else{
        [instructionLabel setFrame:CGRectZero];
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



@end
