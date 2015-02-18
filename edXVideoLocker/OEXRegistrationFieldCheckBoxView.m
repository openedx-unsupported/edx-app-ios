//
//  OEXRegistrationFieldCheckBoxView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldCheckBoxView.h"
#import "OEXCheckBoxView.h"

@interface OEXRegistrationFieldCheckBoxView ()
{
    OEXCheckBoxView *checkBox;
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
        
        errorLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        errorLabel.numberOfLines=0;
        errorLabel.lineBreakMode=NSLineBreakByWordWrapping;
        [self addSubview:errorLabel];
        
        instructionLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        instructionLabel.lineBreakMode=NSLineBreakByWordWrapping;
        instructionLabel.numberOfLines=0;
        [self addSubview:instructionLabel];
        
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
    }
    
    
    CGRect frame=self.frame;
    frame.size.height=offset;
    self.frame=frame;

}

-(void)clearError{
    
    self.errorMessage=nil;
}
@end
