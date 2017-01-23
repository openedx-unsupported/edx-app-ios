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

#import "RateView.h"

#pragma mark </************* STAR - BEGINS *************/>

@interface Star : UIView
{

}
//color - Normal Background Color (Unfilled)
@property(nonatomic,strong)UIColor* color;

//fillColor - Filled Upto Current Value
@property(nonatomic,strong)UIColor* fillColor;

//borderColor - Border Color for Star
@property(nonatomic,strong)UIColor* borderColor;

//fillMode - can be Horizontal, Vertical, Axial
@property(nonatomic,assign)StarFillMode fillMode;

//currentValue - upto which Star is to be filled
@property(nonatomic,assign)CGFloat currentValue;

//size - Star size
@property(nonatomic,assign)CGFloat size;

//Class Helper for Star instantiation
+(Star*)starWithColor:(UIColor*)color fillColor:(UIColor*)fillColor
               origin:(CGPoint)origin andSize:(CGFloat)size;

@end


@implementation Star

#define DefaultBorderColor [UIColor whiteColor]

#pragma mark
#pragma mark<View Initializers & Drawing>
#pragma mark

+(Star*)starWithColor:(UIColor*)color fillColor:(UIColor*)fillColor
               origin:(CGPoint)origin andSize:(CGFloat)size
{
    return [[self alloc] initWithColor:color fillColor:fillColor
                                origin:origin andSize:size];
}

-(id)initWithColor:(UIColor*)color fillColor:(UIColor*)fillColor
            origin:(CGPoint)origin andSize:(CGFloat)size
{
    if(self = [super initWithFrame:CGRectMake(origin.x, origin.y, size, size)])
    {
        // By default, background doesn't have any color
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;

        // Assign the color, fillColor & other defaults
        _color = color;
        _fillColor = fillColor;
        _borderColor = DefaultBorderColor;

        _fillMode = StarFillModeHorizontal;
        _currentValue = 0.0f;
    }

    return self;
}

/*
 * Only override drawRect: if you perform custom drawing.
 * An empty implementation adversely affects performance during animation.
 */
-(void)drawRect:(CGRect)rect
{
    // Get Current Context & Clear for transparent background
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);

    /*
     * We expect a square for the 'rect',
     * so arm = rect.size.width = rect.size.height
     */
    CGFloat arm = rect.size.width;

    // Create a path for star shape
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, arm*0.0, arm*0.35);
    CGPathAddLineToPoint(path, NULL, arm*0.35, arm*0.35);
    CGPathAddLineToPoint(path, NULL, arm*0.50, arm*0.0);
    CGPathAddLineToPoint(path, NULL, arm*0.65, arm*0.35);
    CGPathAddLineToPoint(path, NULL, arm*1.00, arm*0.35);
    CGPathAddLineToPoint(path, NULL, arm*0.75, arm*0.60);
    CGPathAddLineToPoint(path, NULL, arm*0.85, arm*1.00);
    CGPathAddLineToPoint(path, NULL, arm*0.50, arm*0.75);
    CGPathAddLineToPoint(path, NULL, arm*0.15, arm*1.00);
    CGPathAddLineToPoint(path, NULL, arm*0.25, arm*0.60);
    CGPathAddLineToPoint(path, NULL, arm*0.0, arm*0.35);

    /*
     * Add this path's copy(Only for border) to context, stroke it for the border to appear.
     * Add the original path to context, Clip the context for this path.
     * This way, we will be able to draw inside star shaped path only
     */
    CGContextSaveGState(context);

    CGPathRef pathCopy = CGPathCreateCopy(path);
    CGContextAddPath(context, pathCopy);
    CGPathRelease(pathCopy);

    CGContextSetLineWidth(context, 1);
    CGContextSetStrokeColorWithColor(context, _borderColor.CGColor);
    CGContextStrokePath(context);

    CGContextAddPath(context, path);
    CGContextClip(context);

    // Fill the color in Star for regular backgroundColor
    CGContextSetFillColorWithColor(context, _color.CGColor);
    CGContextFillRect(context, rect);

    // Decide where to start filling & upto where it's gonna be
    CGPoint source = CGPointZero;
    CGPoint destination = CGPointZero;

    if(_fillMode == StarFillModeHorizontal)
    {
        // left arm mid point
        source = CGPointMake(0, arm/2);

        // progress x++
        destination = CGPointMake(_currentValue*arm, arm/2);
    }
    else if(_fillMode == StarFillModeVertical)
    {
        // bottom arm mid point
        source = CGPointMake(arm/2, arm);

        // progress y--
        destination = CGPointMake(arm/2, arm - _currentValue*arm);
    }
    else if(_fillMode == StarFillModeAxial)
    {
        // bottom left corner
        source = CGPointMake(0, arm);

        /*
         * progress should be y-- (arm - _currentValue*arm)
         * but have to fix instead, it goes diagonally very fast
         * need to adjust the star shape area coverage a bit
         * (with y--, 0.75f almost covers it fully)
         * We know diagonally d*d = x*x + y*y
         * If (x=y, on axial line), then d*d = 2*x*x
         * this means x = d/sqrt(2)
         * it should work, surprisingly in this scenario,
         * area contained within star does still create problems
         * y works just fine with sqrt(2) i.e. 1.414
         * x had to be tuned to 1.07 from 1.5 to 1.0 through Hit-N-Trial
         * it's the closest I could get to it.
         * Needs further refinement.
         */

        if(_currentValue > 0.0f)
            destination = CGPointMake((_currentValue*arm)/1.07, arm - (_currentValue*arm)/sqrt(2));
        else
            destination = source;
    }

    /*
     * Set fillColor to stroke color,
     * line width thick enough to cover every possible corner of the star
     */
    CGContextSetStrokeColorWithColor(context, _fillColor.CGColor);
    CGContextSetLineWidth(context, 2*arm);

    /*
     * Add a very thick line from source to destination
     * line's thickness will cover the entire star width
     * giving us the required fill
     */
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, source.x, source.y);
    CGContextAddLineToPoint(context, destination.x, destination.y);
    CGContextClosePath(context);

    // Stroke the line
    CGContextStrokePath(context);

    // Restore Context State
    CGContextRestoreGState(context);

    CGPathRelease(path);
}

#pragma mark
#pragma mark<Property Setters>
#pragma mark
/*
 * As soon as a property is altered, it notifies the view that
 * view needsDisplay accordingly with change in property
 * setNeedsDisplay causes drawRect: to fire & UI reflects
 * the expected changes.
 */
-(void)setColor:(UIColor*)color
{
    _color = color;
    [self setNeedsDisplay];
}

-(void)setFillColor:(UIColor*)fillColor
{
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

-(void)setBorderColor:(UIColor*)borderColor
{
    _borderColor = borderColor;
    [self setNeedsDisplay];
}

-(void)setFillMode:(StarFillMode)fillMode
{
    _fillMode = fillMode;
    [self setNeedsDisplay];
}

-(void)setCurrentValue:(CGFloat)currentValue
{
    _currentValue = currentValue;
    [self setNeedsDisplay];
}

-(void)setSize:(CGFloat)size
{
    _size = size;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, _size, _size);
    [self setNeedsDisplay];
}

@end

#pragma mark </************* STAR - ENDS *************/>


@implementation RateView

#define DefaultRateViewFrame CGRectMake(0, 0, 150, 30)

#define DefaultStarNormalColor [UIColor darkGrayColor]
#define DefaultStarFillColor   [UIColor lightGrayColor]
#define DefaultStarBorderColor [UIColor whiteColor]

#define DefaultStarSize 30
#define MinimumRating   0.0
#define MaximumRating   5.0
#define TagOffset       10000

#ifdef DEBUG
#define RVLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define RVLog(format, ...)
#endif

#pragma mark
#pragma mark<View Initializers>
#pragma mark

+(RateView*)rateViewWithRating:(float)rating
{
    return [[self alloc] initWithRating:rating];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return [self initWithRating:0 andFrame:self.frame];
}

-(id)initWithRating:(float)rating
{
    return [self initWithRating:rating andFrame:DefaultRateViewFrame];
}

-(id)initWithRating:(float)rating andFrame:(CGRect)newFrame
{
    if(self = [super initWithFrame:newFrame])
    {
        self.backgroundColor = [UIColor clearColor];

        _rating = rating;

        _step = 0.0f;

        // Check Rating Max / Min
        if(_rating > MaximumRating)
        {
            RVLog(@"RateView : MaximumRating <= 5.0 \n"
                  "You can't have rating more than 5.0, Making it 5.0 for now");
            _rating = MaximumRating;
        }
        else if(_rating < MinimumRating)
        {
            RVLog(@"RateView : MinimumRating >= 0.0 \n"
                  "You can't have rating less than 0.0, Making it 0.0 for now");
            _rating = MinimumRating;
        }

        //Assign default values to required properties
        _canRate = NO;

        _starNormalColor = DefaultStarNormalColor;
        _starFillColor = DefaultStarFillColor;
        _starBorderColor = DefaultStarBorderColor;

        _starFillMode = StarFillModeHorizontal;
        _starSize = DefaultStarSize;

        //Call setRating: so that view's UI gets updated
        self.rating = rating;
    }

    return self;
}

-(void)updateRateView
{
    // Update frame for self to accommodate desired width for 5 stars
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
                            5*_starSize, _starSize);

    // Check if stars have been added to self previously or not
    if([self.subviews count] == 0)
    {
        // If not, add 5 stars to self with desired frames
        for(int i=1; i<=5; i++)
        {
            Star* star = [Star starWithColor:_starNormalColor fillColor:_starFillColor
                                      origin:CGPointMake((i-1)*_starSize, 0) andSize:_starSize];
            [self addSubview:star];
            star.tag = TagOffset+i;
        }
    }
}

#pragma mark
#pragma mark<Property Setters>
#pragma mark

-(void)setRating:(float)rating
{
    _rating = rating;
    [self updateRateView];

    // Update Stars appearance for currentValue
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];

        if(_rating >= i)
        {
            star.currentValue = 1.0f;
        }
        else
        {
            float expectedRating = _rating - (i-1);
            star.currentValue = (expectedRating < 0.0f) ? 0.0f : expectedRating;
        }
    }

    // Notify the delegate object about rating change
    if([_delegate respondsToSelector:@selector(rateView:didUpdateRating:)])
        [_delegate rateView:self didUpdateRating:_rating];
}

-(void)setCanRate:(BOOL)canRate
{
    _canRate = canRate;
}

- (void) setStep:(float)step
{
    if (step < 0.0f) {
        _step = 0.0f;
    }
    else if (step > 1.0f) {
        _step = 1.0f;
    }
    else {
        _step = step;
    }
}

-(void)setStarNormalColor:(UIColor*)starNormalColor
{
    _starNormalColor = starNormalColor;
    [self updateRateView];

    // Update Stars appearance for color
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];
        star.color = _starNormalColor;
    }
}

-(void)setStarFillColor:(UIColor*)starFillColor
{
    _starFillColor = starFillColor;
    [self updateRateView];

    // Update Stars appearance for fillColor
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];
        star.fillColor = _starFillColor;
    }
}

-(void)setStarBorderColor:(UIColor*)starBorderColor
{
    _starBorderColor = starBorderColor;
    [self updateRateView];

    // Update Stars appearance for borderColor
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];
        star.borderColor = _starBorderColor;
    }
}

-(void)setStarFillMode:(StarFillMode)starFillMode
{
    _starFillMode = starFillMode;
    [self updateRateView];

    // Update Stars appearance for fillMode
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];
        star.fillMode = _starFillMode;
    }
}

-(void)setStarSize:(CGFloat)starSize
{
    _starSize = starSize;
    [self updateRateView];

    // Update Stars appearance for size
    for(int i=1; i<=5; i++)
    {
        Star* star = (Star*)[self viewWithTag:TagOffset+i];
        star.size = _starSize;
        star.frame = CGRectMake((i-1)*starSize, 0, _starSize, _starSize);
    }
}

-(void)setFrame:(CGRect)frame
{
    // Check if frame asked to set is more
    if(frame.size.width != 5*_starSize || frame.size.height != _starSize)
    {
        frame.size.width = 5*_starSize;
        frame.size.height = _starSize;
    }

    [super setFrame:frame];
}

#pragma mark
#pragma mark <UIResponder Methods>
#pragma mark

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches];
}

-(void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches];
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches];
}

-(void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self handleTouches:touches];
}

-(void)handleTouches:(NSSet*)touches
{
    if(_canRate)
    {
        CGPoint location = [[touches anyObject] locationInView:self];
        RVLog(@"%@", NSStringFromCGPoint(location));
        // Compute location
        float x = location.x;
        if(x < 0.0f)
            x = 0.0f;
        else if(x > self.frame.size.width)
            x = self.frame.size.width;
        else if (self.step) {
            float div = (self.frame.size.width * self.step) / 5;
            x = (x / div) + self.step;
            x = div * (int)x;
        }
        self.rating = x / _starSize;
    }
}

#pragma mark
#pragma mark <Auto Layout Helpers>
#pragma mark

- (CGSize)intrinsicContentSize {
    return CGSizeMake(self.starSize * 5, self.starSize);
}

@end
