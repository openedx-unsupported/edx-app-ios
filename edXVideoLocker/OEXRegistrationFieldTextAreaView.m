//
//  OEXRegistrationFormTextAreaView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXRegistrationFieldTextAreaView.h"
static NSString *const textAreaBackgoundImage=@"bt_grey_default.png";
@implementation OEXRegistrationFieldTextAreaView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
       
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        inputView=[[OEXTextView alloc] initWithFrame:CGRectZero];

        [inputView setContentInset:UIEdgeInsetsMake(0,0, 5, 0)];
        //[inputView setBackgroundColor:[UIColor lightGrayColor]];
        [inputView setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:13.f]];
        //27.5, 29, 31.4
        [inputView setTextColor:[UIColor colorWithRed:0.275 green:0.29 blue:0.314 alpha:0.9]];
        [inputView setPlaceholderTextColor:[UIColor colorWithRed:0.675 green:0.69 blue:0.614 alpha:0.9]];
        [self addSubview:inputView];
        
        errorLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        errorLabel.numberOfLines=0;
        errorLabel.lineBreakMode=NSLineBreakByWordWrapping;
        [self addSubview:errorLabel];
        
        instructionLabel=[[UILabel alloc] initWithFrame:CGRectZero];
        instructionLabel.lineBreakMode=NSLineBreakByWordWrapping;
        instructionLabel.numberOfLines=0;
        [self addSubview:instructionLabel];
        [inputView.layer setBorderColor:[[[UIColor grayColor] colorWithAlphaComponent:0.5] CGColor]];
        [inputView.layer setBorderWidth:2.0];
        //The rounded corner part, where you specify your view's corner radius:
        inputView.layer.cornerRadius = 5;
        inputView.clipsToBounds = YES;
        
    }
    return self;
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    CGFloat offset=20;
    CGFloat paddingHorizontal=20;
    CGFloat bottomPadding=50;
    CGFloat frameWidth = self.bounds.size.width-2 *paddingHorizontal;
    [inputView setFrame:CGRectMake(paddingHorizontal,offset,frameWidth,100)];
    [inputView setPlaceholder:@"Placeholder"];
    offset=offset+50;
    
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
    frame.size.height=offset+bottomPadding;
    self.frame=frame;
    
}


-(NSString *)currentValue{
    return inputView.text;
}

-(void)clearError{
    
    self.errorMessage=nil;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
