//
//  OEXSubtitleLabel.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 10/03/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXSubtitleLabel.h"

@implementation OEXSubtitleLabel

-(id)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if(self){
        self.edgeInset=UIEdgeInsetsMake(0,0,0,0);
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self=[super initWithCoder:aDecoder];
    if(self){
        self.edgeInset=UIEdgeInsetsMake(0,0,0,0);
    }
    return self;
}

-(void)drawTextInRect:(CGRect)rect{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect,self.edgeInset)];
}

-(CGSize)sizeThatFits:(CGSize)size{
    CGSize newSize=[super sizeThatFits:size];
    float width=newSize.width+self.edgeInset.left + self.edgeInset.right;
    return CGSizeMake(width,newSize.height);
    
}

@end
