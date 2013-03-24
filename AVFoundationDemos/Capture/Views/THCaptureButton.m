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

#import "THCaptureButton.h"
#import <QuartzCore/QuartzCore.h>

#define IMAGE_NAME @"record_indicator_off"
#define IMAGE_NAME_SELECTED @"record_indicator_on"
#define IMAGE_NAME_SELECTED_GLOW [NSString stringWithFormat:@"%@_glow", IMAGE_NAME_SELECTED]

@interface THCaptureButton ()
@property (nonatomic, strong) CALayer *glowLayer;
@property (nonatomic, assign) CGFloat imageHeight;
@property (nonatomic, assign) CGFloat imageWidth;
@end

@implementation THCaptureButton

- (id)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		// Make these the button image instead of the background image so that the button's
		// internal imageView gets initialized.  This is necessary to get the glow effect I need.
		[self setImage:[UIImage imageNamed:IMAGE_NAME] forState:UIControlStateNormal];
		[self setImage:[UIImage imageNamed:IMAGE_NAME_SELECTED] forState:UIControlStateSelected];
	}
	return self;
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	if (selected) {
		[self pulse];
	} else {
		[self clearAnimations];
	}
}

- (BOOL)pulsing {
	return self.glowLayer.animationKeys.count > 0;
}

- (void)clearAnimations {
	[self.glowLayer removeAllAnimations];
	[self.glowLayer removeFromSuperlayer];
	[self.imageView.layer removeAllAnimations];
}

- (void)pulse {
	self.glowLayer = [CALayer layer];
	self.glowLayer.frame = self.imageView.bounds;
	self.glowLayer.contents = (id)[UIImage imageNamed:IMAGE_NAME_SELECTED_GLOW].CGImage;
	self.glowLayer.opacity = 0.0f;
	[self.imageView.layer addSublayer:self.glowLayer];

	CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	pulseAnimation.toValue = @1.0f;
	pulseAnimation.delegate = self;
	[self setAnimationTiming:pulseAnimation];
	[self.glowLayer addAnimation:pulseAnimation forKey:@"pulse"];
}

- (void)setAnimationTiming:(CABasicAnimation *)animation {
	animation.duration = 0.7f;
	animation.repeatCount = HUGE_VALF;
	animation.autoreverses = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	[self clearAnimations];
}

@end
