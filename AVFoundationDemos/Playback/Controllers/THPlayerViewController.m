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

#import "THPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "THPlayerView.h"
#import "AVPlayerItem+THVideoPlayerAdditions.h"
#import "THTransportView.h"

#define STATUS_KEYPATH @"status"
#define REFRESH_INTERVAL 0.5f

// Define this constant for the key-value observation context.
static const NSString *PlayerItemStatusContext;

@interface THPlayerViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) id itemEndObserver;
@property (nonatomic, assign) BOOL scrubbing;
@property (nonatomic, assign) float lastPlaybackRate;
@property (nonatomic, assign) BOOL autoplayContent;
@end

@implementation THPlayerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.autoplayContent = YES;
	self.transportView.playButton.hidden = YES;
	self.navigationBar.topItem.title = self.title;
	[self prepareToPlay];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	if (self.itemEndObserver) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.itemEndObserver
		                                                name:AVPlayerItemDidPlayToEndTimeNotification
			                                          object:self.player.currentItem];
		self.itemEndObserver = nil;
	}
}

#pragma mark - Prepare AVPlayerItem for playback

- (void)prepareToPlay {

	self.playerItem = [AVPlayerItem playerItemWithAsset:self.asset];

	[self.playerItem addObserver:self forKeyPath:STATUS_KEYPATH options:0 context:&PlayerItemStatusContext];

	[self addItemEndObserverForPlayerItem:self.playerItem];

	self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
	self.playerView.player = self.player;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PlayerItemStatusContext) {
		dispatch_async(dispatch_get_main_queue(), ^{

			[self addPlayerItemTimeObserver];

			if (self.autoplayContent) {
				[self.player play];
				self.transportView.pauseButton.hidden = NO;
				self.transportView.playButton.hidden = YES;
			} else {
				[self pauseButtonTapped:nil];
			}

			[self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
		});
	}
}

- (void)addPlayerItemTimeObserver {
	__weak id weakSelf = self;
	self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(REFRESH_INTERVAL, NSEC_PER_SEC)
	                                                              queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
				// Update UI state
				[weakSelf syncScrubberView];
			}];
}

- (void)addItemEndObserverForPlayerItem:(AVPlayerItem *)playerItem {
	__weak id weakSelf = self;
	self.itemEndObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
	                                                                         object:playerItem
		                                                                      queue:[NSOperationQueue mainQueue]
			                                                             usingBlock:^(NSNotification *notification) {
				                                                             // The the transport button state appropriately
				                                                             // and set player to time zero.
				                                                             [weakSelf pauseButtonTapped:nil];
				                                                             [[weakSelf player] seekToTime:kCMTimeZero];
			                                                             }];
}

- (void)syncScrubberView {
	if ([self.playerItem hasValidDuration]) {

		double currentTime = CMTimeGetSeconds([self.player currentTime]);
		double duration = CMTimeGetSeconds(self.playerItem.duration);

		self.transportView.scrubberSlider.minimumValue = 0;
		self.transportView.scrubberSlider.maximumValue = duration;

		if (!self.scrubbing) {
			self.transportView.scrubberSlider.value = currentTime;
		}

		[self updateScrubberLabelsWithDuration:duration andCurrentTime:currentTime];
	} else {
		self.transportView.currentTimeLabel.text = @"-- : --";
	}
}

- (void)updateScrubberLabelsWithDuration:(double)duration andCurrentTime:(double)currentTime {
	NSInteger currentSeconds = ceilf(currentTime);
	double remainingTime = duration - currentTime;
	self.transportView.currentTimeLabel.text = [self formatSeconds:currentSeconds];
	self.transportView.scrubbingTimeLabel.text = [self formatSeconds:currentSeconds];
	self.transportView.remainingTimeLabel.text = [self formatSeconds:remainingTime];
}

- (NSString *)formatSeconds:(NSInteger)value {
	NSInteger seconds = value % 60;
	NSInteger minutes = value / 60;
	return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

#pragma mark - Scrubber Event Handling

- (IBAction)scrubbingDidStart:(id)sender {
	self.transportView.currentTimeLabel.text = @"-- : --";
	self.transportView.remainingTimeLabel.text = @"-- : --";
	self.lastPlaybackRate = self.player.rate;
	self.scrubbing = YES;
	[self.player pause];
	[self.player removeTimeObserver:self.timeObserver];
}

- (IBAction)scrubbing:(id)sender {
	UISlider *slider = (UISlider *)sender;
	[self.player seekToTime:CMTimeMakeWithSeconds([slider value], NSEC_PER_SEC)];
	NSInteger currentSeconds = ceilf([slider value]);
	self.transportView.scrubbingTimeLabel.text = [self formatSeconds:currentSeconds];
}

- (IBAction)scrubbingDidEnd:(id)sender {
	self.scrubbing = NO;
	[self addPlayerItemTimeObserver];
	if (self.lastPlaybackRate > 0.0f) {
		[self.player play];
	}
}

#pragma mark - Close Handler

- (IBAction)closePlayer:(id)sender {
	[self.player setRate:0.0f];
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Transport Button Handling

- (IBAction)playButtonTapped:(id)sender {
	[self.player play];
	self.transportView.playButton.hidden = YES;
	self.transportView.pauseButton.hidden = NO;
}

- (IBAction)pauseButtonTapped:(id)sender {
	[self.player pause];
	self.transportView.playButton.hidden = NO;
	self.transportView.pauseButton.hidden = YES;
}

#pragma mark - Gesture Handling

- (IBAction)togglePlaybackControls:(id)sender {
	CGFloat newAlpha = self.overlayView.alpha == 1.0 ? 0.0f : 1.0f;
	[UIView animateWithDuration:0.3 animations:^{
		self.overlayView.alpha = newAlpha;
	}];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
	return !self.scrubbing;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	return touch.view.superview != self.overlayView;
}


@end
