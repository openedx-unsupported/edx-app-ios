//
//  OEXTextView.m
//  edXVideoLocker
//
//  Created by Jotiram Bhagat on 20/02/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import "OEXPlaceholderTextView.h"
#import "OEXStyles.h"

@implementation OEXPlaceholderTextView
#pragma mark - UIView
- (id)initWithCoder:(NSCoder*)aDecoder {
    if((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        [self initialize];
    }
    return self;
}

- (void)setPlaceholder:(NSString*)string {
    if([string isEqualToString:_placeholder]) {
        return;
    }
    _placeholder = string;
    [self setNeedsDisplay];
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
    [super setContentInset:contentInset];
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    [super setTextAlignment:textAlignment];
    [self setNeedsDisplay];
}

- (void) updateConstraints {
    [super updateConstraints];
    [self setNeedsDisplay];
}

#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if(self.text.length == 0 && self.placeholder) {
        rect = [self placeholderRectForBounds:self.bounds];
        UIFont* font = self.font ? self.font : self.typingAttributes[NSFontAttributeName];
        NSAssert(font != nil, @"Font should not be nil value");
        // Draw the text
        NSMutableParagraphStyle* textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        textStyle.lineBreakMode = NSLineBreakByWordWrapping;
        textStyle.alignment = self.textAlignment;
        NSDictionary* attributes = @{NSFontAttributeName:font, NSForegroundColorAttributeName:self.placeholderTextColor, NSParagraphStyleAttributeName:textStyle, NSBackgroundColorAttributeName:[UIColor clearColor]};
        [self.placeholderTextColor set];
        [self.placeholder drawInRect:rect withAttributes:attributes];
    }
}

#pragma mark - Placeholder

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    // Inset the rect
    CGRect rect = UIEdgeInsetsInsetRect(bounds, self.contentInset);
    rect = UIEdgeInsetsInsetRect(rect, self.textContainerInset);
    if(self.typingAttributes) {
        NSMutableParagraphStyle* style = self.typingAttributes[NSParagraphStyleAttributeName];
        if(style) {
            rect.origin.x += style.headIndent;
            rect.origin.y += style.firstLineHeadIndent;
        }
    }
    return rect;
}

#pragma mark - Private

- (void)initialize {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];

    self.placeholderTextColor = [[OEXStyles sharedStyles] neutralDark];
}

- (void)textChanged:(NSNotification*)notification {
    [self setNeedsDisplay];
}


@end
