//
//  OEXRegistrationFieldCheckBoxView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldCheckBoxView.h"
#import "OEXCheckBoxView.h"
#import "OEXRegistrationFieldWrapperView.h"

@interface OEXRegistrationFieldCheckBoxView ()
{
    OEXCheckBoxView *checkBox;
    OEXRegistrationFieldWrapperView *registrationWrapper;
}
@end

@implementation OEXRegistrationFieldCheckBoxView
-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        checkBox=[[OEXCheckBoxView alloc] initWithFrame:self.bounds];
        [checkBox setLabelText:self.label];
        [self addSubview:checkBox];
        
        
        registrationWrapper = [[OEXRegistrationFieldWrapperView alloc] init];
        [self addSubview:registrationWrapper];
        
    }
    return self;
}

-(void)setLabel:(NSString *)label{
    
    _label=label;
    [checkBox setLabelText:label];
    [self setNeedsDisplay];
    
}

-(BOOL)currentValue{
    return [checkBox isSelected];
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    CGFloat offset=0;
    CGFloat paddingHorizontal=20;
    CGFloat frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    [checkBox setNeedsDisplay];
    
    [checkBox setFrame:CGRectMake(paddingHorizontal, offset,frameWidth,checkBox.frame.size.height)];
    
    offset=offset+100;
    [registrationWrapper setRegistrationErrorMessage:self.errorMessage andInstructionMessage:self.instructionMessage];
    [registrationWrapper setNeedsLayout];
    [registrationWrapper layoutIfNeeded];
    [registrationWrapper setFrame:CGRectMake(0,offset,self.bounds.size.width,registrationWrapper.frame.size.height)];
    if([self.errorMessage length]>0 || [self.instructionMessage length]>0 )
    {
        offset=offset+registrationWrapper.frame.size.height;
    }
    CGRect frame=self.frame;
    frame.size.height=offset;
    self.frame=frame;

}

-(void)clearError{
    
    self.errorMessage=nil;
}
@end
