//
//  OEXTextStyle.h
//  edXVideoLocker
//
//  Created by Akiva Leffert on 3/24/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OEXTextFont) {
    OEXTextFontSystem,
    OEXTextFontSystemBold,
    OEXTextFontThemeSans,
    OEXTextFontThemeSansBold
};

NS_ASSUME_NONNULL_BEGIN

@interface OEXTextStyle : NSObject <NSCopying, NSMutableCopying>

- (id)initWithFont:(OEXTextFont)font size:(CGFloat)size;
- (id)initWithFont:(OEXTextFont)font size:(CGFloat)size color:(nullable UIColor*)color NS_DESIGNATED_INITIALIZER;

+ (instancetype)styleWithThemeSansAtSize:(CGFloat)size;

@property (readonly, assign, nonatomic) NSTextAlignment alignment;
@property (readonly, strong, nonatomic, nullable) UIColor* color;
@property (readonly, assign, nonatomic) OEXTextFont font;
@property (readonly, assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacing;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (readonly, assign, nonatomic) CGFloat size;

@property (readonly, nonatomic) NSDictionary* attributes;

/// Duplicates the current style but makes it bold if it is not already
- (OEXTextStyle*)asBold;
/// Duplicates the current style but with the specified font size
@property (readonly, copy, nonatomic) OEXTextStyle*(^withSize)(CGFloat size);
/// Duplicates the current style but with the specified color
@property (readonly, copy, nonatomic) OEXTextStyle*(^withColor)(UIColor* color);

/// Note: This will not apply paragraph style properties. Be careful
- (void)applyToLabel:(nullable UILabel*)label;
- (void)applyToTextView:(nullable UITextView*)textView;

- (NSAttributedString*)attributedStringWithText:(NSString*)text;

@end

@interface OEXMutableTextStyle : OEXTextStyle

+ (instancetype)style;

@property (assign, nonatomic) NSTextAlignment alignment;
@property (strong, nonatomic, nullable) UIColor* color;
@property (assign, nonatomic) OEXTextFont font;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) CGFloat size;

@end

NS_ASSUME_NONNULL_END

