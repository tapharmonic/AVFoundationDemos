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

#import "THTransportView.h"
#import <QuartzCore/QuartzCore.h>

@interface THTransportView ()
@property (nonatomic, assign) CGFloat sliderOffset;
@property (nonatomic, assign) CGFloat infoViewOffset;
@end

@implementation THTransportView

- (void)awakeFromNib {

	self.scrubberSlider.value = 0.0f;

	self.layer.shadowOpacity = 0.5f;
	self.layer.shadowOffset = CGSizeMake(0, 2);
	self.layer.shadowRadius = 10.0f;
	self.layer.shadowColor = [UIColor colorWithWhite:0.200 alpha:1.000].CGColor;

	UIEdgeInsets trackImageInsets = UIEdgeInsetsMake(0, 8, 0, 8);

	UIImage *thumbNormalImage = [UIImage imageNamed:@"tp_scrubber_knob"];
	UIImage *thumbHighlightedImage = [UIImage imageNamed:@"tp_scrubber_knob_highlighted"];
	UIImage *maxTrackImage = [[UIImage imageNamed:@"tp_track_flex"] resizableImageWithCapInsets:trackImageInsets];
	UIImage *minTrackImage = [[UIImage imageNamed:@"tp_track_highlight_flex"] resizableImageWithCapInsets:trackImageInsets];

	// Customize slider appearance
	[self.scrubberSlider setMaximumTrackImage:maxTrackImage forState:UIControlStateNormal];
	[self.scrubberSlider setMinimumTrackImage:minTrackImage forState:UIControlStateNormal];
	[self.scrubberSlider setThumbImage:thumbNormalImage forState:UIControlStateNormal];
	[self.scrubberSlider setThumbImage:thumbHighlightedImage forState:UIControlStateHighlighted];

	self.infoView.hidden = YES;

	[self.infoView sizeToFit];
	self.infoViewOffset = CGRectGetWidth(self.infoView.frame) / 2;
	CGRect trackRect = [self.scrubberSlider trackRectForBounds:self.scrubberSlider.bounds];
	self.sliderOffset = self.scrubberSlider.frame.origin.x + trackRect.origin.x + 10;

	// Set up actions
	[self.scrubberSlider addTarget:self action:@selector(showPopupUI) forControlEvents:UIControlEventValueChanged];
	[self.scrubberSlider addTarget:self action:@selector(hidePopupUI) forControlEvents:UIControlEventTouchUpInside];
	[self.scrubberSlider addTarget:self action:@selector(unhidePopupUI) forControlEvents:UIControlEventTouchDown];
}

- (void)showPopupUI {
	self.infoView.hidden = NO;
	CGRect trackRect = [self.scrubberSlider trackRectForBounds:self.scrubberSlider.bounds];
	CGRect thumbRect = [self.scrubberSlider thumbRectForBounds:self.scrubberSlider.bounds trackRect:trackRect value:self.scrubberSlider.value];

	CGRect rect = self.infoView.frame;
	// The +1 is a fudge factor due to the scrubber knob being larger than normal
	rect.origin.x = (self.sliderOffset + thumbRect.origin.x + 1) - self.infoViewOffset;
	self.infoView.frame = rect;
}

- (void)unhidePopupUI {
	self.infoView.hidden = NO;
	self.infoView.alpha = 0.0f;
	[UIView animateWithDuration:0.2f animations:^{
		self.infoView.alpha = 1.0f;
	}                completion:^(BOOL complete) {
	}];
}

- (void)hidePopupUI {
	[UIView animateWithDuration:0.3f animations:^{
		self.infoView.alpha = 0.0f;
	}                completion:^(BOOL complete) {
		self.infoView.alpha = 1.0f;
		self.infoView.hidden = YES;
	}];
}

@end
