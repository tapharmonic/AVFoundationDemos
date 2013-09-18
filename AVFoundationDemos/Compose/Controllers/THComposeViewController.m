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

#import "THComposeViewController.h"
#import "THTrackView.h"
#import "UIView+THAdditions.h"
#import "UIAlertView+THAdditions.h"

#define TRACK_HEIGHT 56
#define TRACKS_KEY @"tracks"
#define STATUS_KEYPATH @"status"
#define HAS_SEEN_INSTRUCTION_KEY @"hasSeenInstruction"

#define GTR_TAG 100
#define BASS_TAG 200
#define DRUMS_TAG 300

static const NSString *PlayerItemStatusContext;

@interface THComposeViewController ()

@property (nonatomic, strong) NSMutableArray *preparationQueue;

@property (nonatomic, strong) NSArray *guitarLoops;
@property (nonatomic, strong) NSArray *bassLoops;
@property (nonatomic, strong) NSArray *drumLoops;

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVMutableComposition *composition;

@property (nonatomic, strong) NSArray *guitarCompositionTracks;
@property (nonatomic, strong) NSArray *bassCompositionTracks;
@property (nonatomic, strong) NSArray *drumCompositionTracks;

@property (nonatomic, strong) CALayer *handLayer;

@end

@implementation THComposeViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// Disable interaction until composition is ready
	self.playButton.userInteractionEnabled = NO;

	UIColor *guitarColor = [UIColor colorWithRed:0.506 green:0.722 blue:0.871 alpha:1.000];
	UIColor *bassColor = [UIColor colorWithRed:0.569 green:0.757 blue:0.333 alpha:1.000];
	UIColor *drumColor = [UIColor colorWithRed:0.982 green:0.612 blue:0.233 alpha:1.000];

	[self configureScrollView:self.guitarScrollView trackColor:guitarColor loops:[self guitarLoops]];
	[self configureScrollView:self.bassScrollView trackColor:bassColor loops:[self bassLoops]];
	[self configureScrollView:self.drumsScrollView trackColor:drumColor loops:[self drumLoops]];

	[self prepareAssets];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self stopPlayer:nil];
}

- (void)configureScrollView:(UIScrollView *)scrollView trackColor:(UIColor *)trackColor loops:(NSArray *)loops {
	CGFloat width = self.view.boundsWidth;
	CGFloat height = self.view.boundsHeight;
	CGFloat trackWidth = fmaxf(width, height) - 19.0f;
	scrollView.contentSize = CGSizeMake((trackWidth) * [loops count], scrollView.frame.size.height);
	scrollView.showsHorizontalScrollIndicator = NO;
	CGFloat currentX = 0;
	for (AVAsset *loop in loops) {
		CGRect rect = CGRectMake(currentX, 0, trackWidth, TRACK_HEIGHT);
		THTrackView *trackView = [[THTrackView alloc] initWithFrame:rect];
		trackView.trackColor = trackColor;
		[scrollView addSubview:trackView];
		currentX += trackWidth;
	}
}

- (void)prepareAssets {
	self.preparationQueue = [NSMutableArray array];
	[self.preparationQueue addObjectsFromArray:[self guitarLoops]];
	[self.preparationQueue addObjectsFromArray:[self bassLoops]];
	[self.preparationQueue addObjectsFromArray:[self drumLoops]];

	NSArray *keys = @[TRACKS_KEY];
	for (AVAsset *asset in self.preparationQueue) {
		[asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{

			NSError *error;
			AVKeyValueStatus status = [asset statusOfValueForKey:TRACKS_KEY error:&error];

			dispatch_async(dispatch_get_main_queue(), ^{

				if (status == AVKeyValueStatusLoaded) {
					[self.preparationQueue removeObject:asset];
					if (self.preparationQueue.count == 0) {
						[self prepareComposition];
					}
				} else {
					// Cancel loading of remaining assets
					for (AVAsset *asset in self.preparationQueue) {
						[asset cancelLoading];
					}
					[self.preparationQueue removeAllObjects];
					[self handlePreparationFailure:error];
				}

			});
		}];
	}
}

- (void)prepareComposition {
	dispatch_async(dispatch_queue_create("com.tapharmonic.CompositionQueue", NULL), ^{
		self.composition = [self buildComposition];
		dispatch_async(dispatch_get_main_queue(), ^{
			AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:[self.composition copy]];
			[playerItem addObserver:self forKeyPath:STATUS_KEYPATH options:0 context:&PlayerItemStatusContext];
			self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
			self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
		});
	});
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (context == &PlayerItemStatusContext) {
		if (self.player.status == AVPlayerItemStatusReadyToPlay) {
			self.playButton.userInteractionEnabled = YES;
		}
	}
}

- (void)handlePreparationFailure:(NSError *)error {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Face Palm"
	                                                    message:@"An error was encountered preparing assets."
		                                               delegate:nil cancelButtonTitle:@"OK"
				                              otherButtonTitles:nil, nil];
	[alertView show];
}

- (AVMutableComposition *)buildComposition {

	AVMutableComposition *composition = [AVMutableComposition composition];

	self.guitarCompositionTracks = [self addAssets:[self guitarLoops] toComposition:composition];
	self.bassCompositionTracks = [self addAssets:[self bassLoops] toComposition:composition];
	self.drumCompositionTracks = [self addAssets:[self drumLoops] toComposition:composition];

	return composition;
}

- (NSArray *)addAssets:(NSArray *)assets toComposition:(AVMutableComposition *)composition {
	NSMutableArray *compositionTracks = [NSMutableArray arrayWithCapacity:assets.count];

	for (AVAsset *asset in assets) {
		NSError *error;

		CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
		AVAssetTrack *assetTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];

		AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio
		                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];

		CMTime cursorTime = kCMTimeZero;

		// Loop 2 minutes ((30 * 4 seconds) / 60 seconds)
		for (int i = 0; i < 30; i++) {
			[compositionTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:cursorTime error:&error];
			cursorTime = CMTimeAdd(cursorTime, asset.duration);
		}
		[compositionTracks addObject:compositionTrack];
	}
	return compositionTracks;
}

- (AVAudioMix *)defaultAudioMix {

	AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];

	NSMutableArray *parameters = [NSMutableArray array];

	[parameters addObjectsFromArray:[self defaultAudioMixInputParametersForTracks:self.guitarCompositionTracks]];
	[parameters addObjectsFromArray:[self defaultAudioMixInputParametersForTracks:self.bassCompositionTracks]];
	[parameters addObjectsFromArray:[self defaultAudioMixInputParametersForTracks:self.drumCompositionTracks]];

	audioMix.inputParameters = parameters;

	return audioMix;
}

- (NSArray *)defaultAudioMixInputParametersForTracks:(NSArray *)tracks {
	NSMutableArray *parametersArray = [NSMutableArray arrayWithCapacity:tracks.count];
	for (int i = 0, count = tracks.count; i < count; i++) {
		AVAssetTrack *track = [tracks objectAtIndex:i];
		AVMutableAudioMixInputParameters *params = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
		// Enable the first track.  Mute the others.
		CGFloat volume = (i == 0) ? 1.0f : 0.0f;
		[params setVolume:volume atTime:kCMTimeZero];
		[parametersArray addObject:params];
	}
	return parametersArray;
}

#pragma mark - Adjusting Audio Mix

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

	CGFloat width = scrollView.contentSize.width;
	CGFloat pointX = scrollView.contentOffset.x;

	NSArray *tracks = [self tracksForScrollView:scrollView];

	NSMutableArray *parametersArray = [NSMutableArray array];

	// Calculate index of visible view in the scrollview
	// to determine which track to solo and which ones to mute
	NSUInteger selectedTrackIndex = pointX / (width / tracks.count);

	for (int i = 0; i < tracks.count; i++) {
		AVAssetTrack *track = [tracks objectAtIndex:i];
		AVMutableAudioMixInputParameters *params = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
		[params setVolume:(i == selectedTrackIndex) ? 1.0 : 0.0f atTime:kCMTimeZero];
		[parametersArray addObject:params];
	}

	AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
	audioMix.inputParameters = parametersArray;
	self.player.currentItem.audioMix = audioMix;
}

- (NSArray *)tracksForScrollView:(UIScrollView *)scrollView {
	NSArray *tracks;
	if (scrollView.tag == GTR_TAG) {
		tracks = self.guitarCompositionTracks;
	} else if (scrollView.tag == BASS_TAG) {
		tracks = self.bassCompositionTracks;
	} else {
		tracks = self.drumCompositionTracks;
	}
	return tracks;
}

#pragma mark - AVPlayer Actions

- (IBAction)startPlayer:(id)sender {
	// If the player item doesn't already have an audio mix, give it the default
	if (!self.player.currentItem.audioMix) {
		self.player.currentItem.audioMix = [self defaultAudioMix];
	}
	[self.player seekToTime:kCMTimeZero];
	[self.player play];
	self.playButton.hidden = YES;
	self.stopButton.hidden = NO;
	[self showInstructionIfNeeded];
}


- (IBAction)stopPlayer:(id)sender {
	self.player.rate = 0.0f;
	self.stopButton.hidden = YES;
	self.playButton.hidden = NO;
}

#pragma mark - Initialize Assets

- (NSArray *)guitarLoops {
	if (!_guitarLoops) {
		_guitarLoops = [self assetsNamed:@[@"guitar_funky", @"guitar_rock", @"guitar_metal"]];
	}
	return _guitarLoops;
}

- (NSArray *)bassLoops {
	if (!_bassLoops) {
		_bassLoops = [self assetsNamed:@[@"bass_funky", @"bass_groovin", @"bass_rock"]];
	}
	return _bassLoops;
}

- (NSArray *)drumLoops {
	if (!_drumLoops) {
		_drumLoops = [self assetsNamed:@[@"drums_funky", @"drums_club", @"drums_rock"]];
	}
	return _drumLoops;
}

- (NSArray *)assetsNamed:(NSArray *)names {
	NSMutableArray *assets = [NSMutableArray arrayWithCapacity:names.count];
	NSBundle *bundle = [NSBundle mainBundle];
	// Set AVURLAssetPreferPreciseDurationAndTimingKey to YES since we're adding it to a composition
	NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey : @YES};
	for (NSString *name in names) {
		NSURL *assetURL = [bundle URLForResource:name withExtension:@"caf"];
		[assets addObject:[AVURLAsset URLAssetWithURL:assetURL options:options]];
	}
	return assets;
}

#pragma mark - Visual Instruction Layer

- (void)showInstructionIfNeeded {
	// Only show the user this the first time they hit the play button
	if (![[NSUserDefaults standardUserDefaults] boolForKey:HAS_SEEN_INSTRUCTION_KEY]) {
		[self performSelector:@selector(showInstructionLayer) withObject:nil afterDelay:1.0];
	}
}

- (void)showInstructionLayer {
	CGFloat startX = self.view.boundsWidth - 150.0f;
	CGFloat endX = 150.0f;
	CGFloat yPos = 150.0f;

	UIImage *image = [UIImage imageNamed:@"co_hand_icon"];
	self.handLayer = [CALayer layer];
	self.handLayer.contents = (id)image.CGImage;
	self.handLayer.bounds = CGRectMake(0, 0, image.size.width, image.size.height);
	self.handLayer.position = CGPointMake(endX, yPos);
	self.handLayer.opacity = 0.0f;
	[self.view.layer addSublayer:self.handLayer];

	CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeInAnimation.fromValue = @0.0f;
	fadeInAnimation.toValue = @1.0f;
	fadeInAnimation.duration = 0.3f;
	fadeInAnimation.fillMode = kCAFillModeForwards;

	CABasicAnimation *moveAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	moveAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(startX, yPos)];
	moveAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(endX, yPos)];
	moveAnimation.duration = 0.8f;
	moveAnimation.beginTime = 0.1;
	moveAnimation.fillMode = kCAFillModeBoth;
	moveAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

	CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeOutAnimation.fromValue = @1.0f;
	fadeOutAnimation.toValue = @0.0f;
	fadeOutAnimation.duration = 0.25f;
	fadeOutAnimation.beginTime = 1.0f;
	fadeOutAnimation.fillMode = kCAFillModeForwards;

	CAAnimationGroup *group = [CAAnimationGroup animation];
	group.duration = 1.25f;
	group.delegate = self;
	[group setAnimations:@[fadeInAnimation, moveAnimation, fadeOutAnimation]];
	[self.handLayer addAnimation:group forKey:@"animations"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	[self.handLayer removeAllAnimations];
	[self.handLayer removeFromSuperlayer];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:HAS_SEEN_INSTRUCTION_KEY];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Pending Features

- (IBAction)exportComposition:(id)sender {
	[UIAlertView showAlertWithTitle:@"Export" message:@"This feature coming soon to a demo app near you."];
}

- (IBAction)showMixer:(id)sender {
	[UIAlertView showAlertWithTitle:@"Mixer" message:@"This feature coming soon to a demo app near you."];
}

@end
