//
//  OEXRegistrationAgreementView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 19/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationAgreementView.h"

@implementation OEXRegistrationAgreementView

-(instancetype)initWithFrame:(CGRect)frame{
    
    self=[super initWithFrame:self.bounds];
    if(self){
        
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        inputView=[[UIButton alloc] initWithFrame:CGRectZero];
        inputView.titleLabel.font=[UIFont fontWithName:@"OpenSans" size:10.f];
        inputView.titleLabel.textColor=[UIColor blueColor];
        inputView.titleLabel.text=self.agreement;
        [self addSubview:inputView];
        
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
    NSInteger paddingTop=10;
    NSInteger offset=paddingTop;
    NSInteger buttonHeight=20;
    [inputView setFrame:CGRectMake(paddingHorizontal,paddingTop,frameWidth,buttonHeight)];
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

-(NSString *)currentValue{
    // Return true by default
    return @"true";
}


-(void)clearError{
    self.errorMessage=nil;
}


@end
