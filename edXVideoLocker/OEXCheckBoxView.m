//
//  OEXCustomCheckBox.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 17/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXCheckBoxView.h"



static NSString *const OEXActiveCheckBoxImageImage=@"ic_checkbox_active.png";
static NSString *const OEXDefaultCheckBoxImage=@"ic_checkbox_default.png";

@interface OEXCheckBoxView ()
{
    UILabel  *label;
    
}
@property(nonatomic,strong)UIButton *checkBox;

@end


@implementation OEXCheckBoxView

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:self.bounds];
    if(self){
        
         self.checkBox=[[UIButton alloc] initWithFrame:self.bounds];
        [self.checkBox addTarget:self action:@selector(checkBoxTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.checkBox setBackgroundImage:[UIImage imageNamed:OEXActiveCheckBoxImageImage] forState:UIControlStateSelected];
        [self.checkBox setBackgroundImage:[UIImage imageNamed:OEXDefaultCheckBoxImage] forState:UIControlStateNormal];
        [self.checkBox setBackgroundColor:[UIColor redColor]];
        [self addSubview:self.checkBox];

        label=[[UILabel alloc] initWithFrame:self.bounds];
        label.numberOfLines=0;
        label.lineBreakMode=NSLineBreakByWordWrapping;
        [self addSubview:label];
    }
    return self;
}

-(IBAction)checkBoxTapped:(id)sender{
    [self toggleButtonState];
}

-(void)setSelected:(BOOL)selected{
     self.checkBox.selected=selected;
}

-(BOOL)isSelected{
    return self.checkBox.selected;
}

-(void)setLabelText:(NSString *)title{
    label.text=title;
    [self layoutIfNeeded];
}

-(void)layoutSubviews{
    [super layoutSubviews];
    NSInteger horizontalSpacing=20;
    NSInteger verticalSpacing=20;
    NSInteger width=self.frame.size.width-horizontalSpacing;
    NSInteger checkboxWidth=25;
    self.checkBox.frame=CGRectMake(horizontalSpacing, verticalSpacing,checkboxWidth, checkboxWidth);
    
    NSInteger labelWidth=width-checkboxWidth-horizontalSpacing;
    
    NSDictionary *attributes = @{NSFontAttributeName:label.font};
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes
                                           context:nil];
    
    NSInteger origin=horizontalSpacing+checkboxWidth+horizontalSpacing;
    [label setFrame:CGRectMake(origin,verticalSpacing,labelWidth,rect.size.height)];
}

-(void)toggleButtonState{
    self.checkBox.selected=!self.checkBox.selected;
}

@end
