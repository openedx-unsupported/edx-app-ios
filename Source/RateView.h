/*
 The MIT License (MIT)
 
 Copyright (c) 2014 Tarun Tyagi
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
*/

#import <UIKit/UIKit.h>

#if !__has_feature(objc_arc)
#error RateView requires ARC. Please turn on ARC for your project or \
       add -fobjc-arc flag for RateView.m file in Build Phases -> Compile Sources.
#endif

typedef enum
{
    StarFillModeInvalid = 0,
    StarFillModeHorizontal,
    StarFillModeVertical,
    StarFillModeAxial
}StarFillMode;

@class RateView;
@protocol RateViewDelegate <NSObject>

@optional
-(void)rateView:(RateView*)rateView didUpdateRating:(float)rating;

@end

@interface RateView : UIView
{
    
}
// Rating to be used with RateView (0.0 to 5.0)
@property(nonatomic,assign)float rating;

// User can rate using rate view or not (Permission flag)
@property(nonatomic,assign)BOOL canRate;

// Rating step when user can rate (0.0 to 1.0)
@property(nonatomic,assign)float step;

// Star Normal, Fill & Border Colors
@property(nonatomic,strong)UIColor* starNormalColor;
@property(nonatomic,strong)UIColor* starFillColor;
@property(nonatomic,strong)UIColor* starBorderColor;

// Star Fill modes Horizontal, Vertical or Axial, starSize in points
@property(nonatomic,assign)StarFillMode starFillMode;
@property(nonatomic,assign)CGFloat starSize;

// RateViewDelegate, register in order to listen to rating changes
@property(nonatomic,weak)id<RateViewDelegate> delegate;

// Class Helper for Rate View instantiation
+(RateView*)rateViewWithRating:(float)rating;

@end
