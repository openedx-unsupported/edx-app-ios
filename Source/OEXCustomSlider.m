//
//  OEXCustomSlider.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 15/07/14.
//  Copyright (c) 2014 edX. All rights reserved.
//

#import "OEXCustomSlider.h"

@interface OEXCustomSlider ()
{
}

@property(nonatomic, strong) UIProgressView* progressView;
@property(nonatomic, assign) CGFloat width;

@end

@implementation OEXCustomSlider

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self loadSubviews];

        // Initialization code
    }
    return self;
}
- (id)initWithCoder:(NSCoder*)aDecoder {
    self = [super initWithCoder:aDecoder];

    if(self) {
        [self loadSubviews];
    }

    return self;
}

- (void)loadSubviews {
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [_progressView setProgress:.7f];
    self.backgroundColor = [UIColor clearColor];
    self.maximumTrackTintColor = [UIColor clearColor];
    [self addSubview:_progressView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _progressView.frame = CGRectMake(2, self.frame.size.height / 2 - 1, self.frame.size.width - 2, self.frame.size.height);
}

- (void)setSecondaryProgress:(CGFloat)secondaryProgress {
    [_progressView setProgress:secondaryProgress];
}

- (void)setSecondaryTrackColor:(UIColor*)secondaryTrackColor {
    [_progressView setProgressTintColor:secondaryTrackColor];
    [self setNeedsDisplay];
}

- (void)setSecondaryTrackImage:(UIImage*)secondaryTrackImage {
    [_progressView setProgressImage:secondaryTrackImage];
    [self setNeedsDisplay];
}

@end
