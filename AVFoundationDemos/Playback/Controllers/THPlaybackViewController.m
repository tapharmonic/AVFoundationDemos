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

#import "THPlaybackViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "HCYoutubeParser.h"
#import "THPlayerViewController.h"
#import "UIView+THAdditions.h"
#import "UIAlertView+THAdditions.h"

#define YOUTUBE_URL @"http://youtu.be/Zce-QT7MGSE"

#define LOCAL_SEGUE        @"localSegue"
#define STREAMING_SEGUE @"streamingSegue"

@interface THPlaybackViewController ()
@property (nonatomic, strong) AVAsset *localAsset;
@property (nonatomic, strong) AVAsset *streamingAsset;
@end

@implementation THPlaybackViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	if (!IS_IPHONE_5) {
		[self fixLayout];
	}

	// Init local asset
	NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:@"charlie" withExtension:@"mp4"];
	self.localAsset = [AVURLAsset assetWithURL:bundleURL];

	// Init streaming asset
	[HCYoutubeParser h264videosWithYoutubeURL:[NSURL URLWithString:YOUTUBE_URL] completeBlock:^(NSDictionary *urls, NSError *error) {
		self.streamingAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:urls[@"hd720"]]];
	}];
}

// Not ready to swallow auto-layout.  Manually adjust UI to accomodate pre-iPhone 5 dimensions
- (void)fixLayout {
	[self scaleView:self.localPlaybackButton];
	[self scaleView:self.remotePlaybackButton];
	self.remotePlaybackButton.frameX += 40;

	[self centerLabel:self.localLabel inRect:self.localPlaybackButton.frame];
	[self centerLabel:self.remoteLabel inRect:self.remotePlaybackButton.frame];
}

- (void)scaleView:(UIView *)view {
	view.frameWidth *= 0.85f;
	view.frameHeight *= 0.85f;
}

- (void)centerLabel:(UILabel *)label inRect:(CGRect)rect {
	label.center = CGPointMake(CGRectGetMidX(rect), label.center.y - 10.0f);
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
	if ([identifier isEqualToString:LOCAL_SEGUE] && !self.localAsset) {
		return [self alertError];
	} else if ([identifier isEqualToString:STREAMING_SEGUE] && !self.streamingAsset) {
		return [self alertError];
	}
	return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	AVAsset *asset = [segue.identifier isEqualToString:LOCAL_SEGUE] ? self.localAsset : self.streamingAsset;
	THPlayerViewController *controller = [segue destinationViewController];
	controller.title = [self titleForAsset:asset];
	controller.asset = asset;
}

- (NSString *)titleForAsset:(AVAsset *)asset {
	// This could be read from metadata, but I'm not up for that right now
	return (asset == self.localAsset) ? @"Charlie the Unicorn" : @"NFL: Bad Lip Reading";
}

- (BOOL)alertError {
	[UIAlertView showAlertWithTitle:@"Asset Unavailable"
							message:@"The requested asset could not be loaded."];
	return NO;
}

@end
