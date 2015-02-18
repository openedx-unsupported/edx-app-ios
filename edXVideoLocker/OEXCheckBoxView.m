//
//  OEXCustomCheckBox.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCheckBoxView.h"

NSString *const kOEXSelctedImage=@"";
NSString *const kOEXDeSelctedImage=@"";

@interface OEXCheckBoxView ()
{
    UIButton *checkBox;
    UILabel  *label;
    
}
@end


@implementation OEXCheckBoxView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        
        checkBox=[[UIButton alloc] initWithFrame:self.bounds];
        [checkBox addTarget:self action:@selector(checkBoxClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:checkBox];
        label=[[UILabel alloc] initWithFrame:self.bounds];
        label.numberOfLines=0;
        label.lineBreakMode=NSLineBreakByWordWrapping;
        [self addSubview:label];
    }
    return self;
}

-(IBAction)checkBoxClicked:(id)sender{
    
    [self changeButtonState];
    
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [self changeButtonState];
}

-(void)setSelected:(BOOL)selected{
    checkBox.selected=selected;
    [self changeButtonState];
}

-(BOOL)isSelected{
    return checkBox.selected;
}

-(void)setLabelText:(NSString *)title{
    label.text=title;
    [self setNeedsDisplay];
}

-(void)layoutSubviews{
    
    [super layoutSubviews];
    NSInteger horizontalSpacing=20;
    NSInteger verticalSpacing=20;
    NSInteger offset=verticalSpacing;
    NSInteger width=self.frame.size.width-horizontalSpacing;
    NSInteger checkboxWidth=25;
    
    checkBox.frame=CGRectMake(horizontalSpacing, verticalSpacing,checkboxWidth, checkboxWidth);
    
    NSInteger labelWidth=width-checkboxWidth-horizontalSpacing;
    
    NSDictionary *attributes = @{NSFontAttributeName:label.font};
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes
                                           context:nil];
    
    NSInteger origin=horizontalSpacing+checkboxWidth+horizontalSpacing;
    [label setFrame:CGRectMake(origin,verticalSpacing,labelWidth,rect.size.height)];
    offset=offset+rect.size.height;
    
}

-(void)changeButtonState{
    checkBox.selected=!checkBox.selected;
    if(checkBox.selected){
        [checkBox setBackgroundImage:[UIImage imageNamed:kOEXSelctedImage] forState:UIControlStateNormal];
    }else{
        [checkBox setBackgroundImage:[UIImage imageNamed:kOEXDeSelctedImage] forState:UIControlStateNormal];
    }
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
