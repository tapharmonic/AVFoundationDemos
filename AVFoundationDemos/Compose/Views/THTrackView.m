//
//  MIT License
//
//  Copyright (c) 2013 Bob McCune http://bobmccune.com/
//  Copyright (c) 2013 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//

#import "THTrackView.h"
#import "UIColor+THAdditions.h"
#import "UIView+THAdditions.h"

@interface THTrackView ()
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

@implementation THTrackView

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	// Draw rounded rect gradient background
	CGContextSaveGState(context);

	UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(8, 8)];
	CGContextAddPath(context, roundedPath.CGPath);
	CGContextClip(context);

	// Define Colors
	UIColor *bgStartColor = self.trackColor.lighterColor;
	UIColor *bgEndColor = self.trackColor.darkerColor;
	NSArray *bgColors = @[(__bridge id)bgStartColor.CGColor, (__bridge id)bgEndColor.CGColor];

	// Define Color Locations
	CGFloat bgLocations[] = {0.0, 1.0};

	// Create Gradient

	CGGradientRef bgGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)bgColors, bgLocations);

	// Define start and end points and draw gradient
	CGPoint bgStartPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	CGPoint bgEndPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

	CGContextDrawLinearGradient(context, bgGradient, bgStartPoint, bgEndPoint, 0);

	CGGradientRelease(bgGradient);
	CGColorSpaceRelease(colorSpace);
	CGContextRestoreGState(context);


	// Draw shine layer over top
	CGContextScaleCTM(context, 1.0, 1.0);
	CGRect shineRect = CGRectMake(0, 0, CGRectGetWidth(rect), CGRectGetHeight(rect) / 2);
	CGPathRef highlightPath = [UIBezierPath bezierPathWithRoundedRect:shineRect
	                                                byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
					                                      cornerRadii:CGSizeMake(8.0f, 8.0f)].CGPath;
	CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.100].CGColor);
	CGContextAddPath(context, highlightPath);
	CGContextFillPath(context);
}

@end
