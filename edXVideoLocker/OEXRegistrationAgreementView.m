//
//  OEXRegistrationAgreementView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreementView.h"

@interface OEXRegistrationAgreementView ()
@property(nonatomic,strong)UIButton *inputView;
@end

@implementation OEXRegistrationAgreementView

-(instancetype)initWithFrame:(CGRect)frame{
    
    self=[super initWithFrame:self.bounds];
    if(self){
        
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.inputView=[[UIButton alloc] initWithFrame:CGRectZero];
        self.inputView.titleLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        [self.inputView setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.inputView.titleLabel.text=self.agreement;
        [self.inputView setUserInteractionEnabled:NO];
        [self addSubview:self.inputView];
        
        errorLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        errorLabel.numberOfLines=0;
        errorLabel.lineBreakMode=NSLineBreakByWordWrapping;
        errorLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        errorLabel.textColor=[UIColor redColor];
        [self addSubview:errorLabel];
        
        instructionLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        instructionLabel.lineBreakMode=NSLineBreakByWordWrapping;
        instructionLabel.numberOfLines=0;
        instructionLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        [self addSubview:instructionLabel];
    }
    return self;
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    NSInteger paddingHorizontal=40;
    NSInteger frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    NSInteger paddingTop=0;
    NSInteger offset=paddingTop;
    NSInteger buttonHeight=30;
    [self.inputView  setTitle:self.agreement forState:UIControlStateNormal];
    [self.inputView setFrame:CGRectMake(paddingHorizontal,paddingTop,frameWidth,buttonHeight)];
    offset=offset+buttonHeight;
    
    if(self.errorMessage){
        NSDictionary *attributes = @{NSFontAttributeName:errorLabel.font};
        errorLabel.text=self.errorMessage;
        CGRect rect = [self.errorMessage boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attributes
                                                      context:nil];
        
        [errorLabel setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,rect.size.height)];
        
        offset=offset+rect.size.height;
    }else{
        [errorLabel setFrame:CGRectZero];
    }
    
    if(self.instructionMessage){
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
    frame.size.height=offset;
    self.frame=frame;
    
}

-(BOOL)currentValue{
    // Return true by default
    return YES;
}


-(void)clearError{
    self.errorMessage=nil;
}


@end
