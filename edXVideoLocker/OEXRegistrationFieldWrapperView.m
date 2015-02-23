//
//  OEXRegistrationFieldError.m
//  edXVideoLocker
//
//  Created by Rahul Varma on 23/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldWrapperView.h"

@implementation OEXRegistrationFieldWrapperView

-(instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self)
    {
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



- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat paddingHorizontal=20;
    CGFloat frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    NSInteger paddingTop=0;
    NSInteger spacingTextFieldAndLabel=3;
    CGFloat offset=paddingTop;
    CGFloat paddingBottom=15;
    offset=offset;

    
    if([errorLabel.text length]>0){
        
        offset=offset+spacingTextFieldAndLabel;
        NSDictionary *attributes = @{NSFontAttributeName:errorLabel.font};
        CGRect rect = [errorLabel.text boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attributes
                                                    context:nil];
        [errorLabel setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,rect.size.height)];
        offset=offset+rect.size.height;
        
    }else{
        offset=offset+spacingTextFieldAndLabel;
        [errorLabel setFrame:CGRectZero];
    }
    
    
    if([instructionLabel.text length]>0){
        NSDictionary *attributes = @{NSFontAttributeName:instructionLabel.font};
        CGRect rect = [instructionLabel.text boundingRectWithSize:CGSizeMake(frameWidth, CGFLOAT_MAX)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                       attributes:attributes
                                                          context:nil];
        [instructionLabel setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,rect.size.height)];
        
        offset=offset+rect.size.height;
    }else{
        offset=offset+spacingTextFieldAndLabel;
        [instructionLabel setFrame:CGRectZero];
    }
 
    CGRect frame=self.frame;
    frame.size.height=paddingBottom;
    self.frame=frame;

}

- (void)setRegistrationErrorMessage:(NSString *)errorMessage andInstructionMessage:(NSString *)instructionMessage
{
    
    if([errorMessage length]>0)
    {
        errorLabel.text=errorMessage;
    }
    
    if([instructionMessage length]>0)
    {
        instructionLabel.text=instructionMessage;
    }
}

@end
