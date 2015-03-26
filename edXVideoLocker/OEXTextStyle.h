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

@interface OEXTextStyle : NSObject <NSCopying, NSMutableCopying>

- (id)initWithFont:(OEXTextFont)font size:(CGFloat)size NS_DESIGNATED_INITIALIZER;

+ (instancetype)styleWithThemeSansAtSize:(CGFloat)size;

@property (readonly, strong, nonatomic) UIColor* color;
@property (readonly, assign, nonatomic) OEXTextFont font;
@property (readonly, assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacing;
@property (readonly, assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (readonly, assign, nonatomic) CGFloat size;

@property (readonly, nonatomic) NSDictionary* attributes;

/// Duplicates the current style but makes it bold if it is not already
- (OEXTextStyle*)asBold;
/// Duplicates the current style but with the specified font size
- (OEXTextStyle*(^)(CGFloat size))withSize;

/// Note: This will not apply paragraph style properties. Be careful
- (void)applyToLabel:(UILabel*)label;

- (NSAttributedString*)attributedStringWithText:(NSString*)text;

@end

@interface OEXMutableTextStyle : OEXTextStyle

+ (instancetype)style;

@property (strong, nonatomic) UIColor* color;
@property (assign, nonatomic) OEXTextFont font;
@property (assign, nonatomic) NSLineBreakMode lineBreakMode;
@property (assign, nonatomic) CGFloat paragraphSpacing;
@property (assign, nonatomic) CGFloat paragraphSpacingBefore;
@property (assign, nonatomic) CGFloat size;

@end