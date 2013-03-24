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

#import "THCaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "THPlayerViewController.h"

#define VIDEO_FILE @"test.mov"

@interface THCaptureViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureOutput;
@property (nonatomic, weak) AVCaptureDeviceInput *activeVideoInput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@end

@implementation THCaptureViewController

- (void)viewDidLoad {
	[super viewDidLoad];

#if TARGET_IPHONE_SIMULATOR
	self.simulatorView.hidden = NO;
	[self.view bringSubviewToFront:self.simulatorView];
#else
	self.simulatorView.hidden = YES;
	[self.view sendSubviewToBack:self.simulatorView];
#endif

	// Hide the toggle button if device has less than 2 cameras. Does 3GS support iOS 6?
	self.toggleCameraButton.hidden = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] < 2;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self setUpCaptureSession];
	});
}

#pragma mark - Configure Capture Session

- (void)setUpCaptureSession {
	self.captureSession = [[AVCaptureSession alloc] init];


	NSError *error;

	// Set up hardware devices
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (videoDevice) {
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (input) {
			[self.captureSession addInput:input];
			self.activeVideoInput = input;
		}
	}
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	if (audioDevice) {
		AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		if (audioInput) {
			[self.captureSession addInput:audioInput];
		}
	}

	// Setup the still image file output
	AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
	[stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];

	if ([self.captureSession canAddOutput:stillImageOutput]) {
		[self.captureSession addOutput:stillImageOutput];
	}

	// Start running session so preview is available
	[self.captureSession startRunning];

	// Set up preview layer
	dispatch_async(dispatch_get_main_queue(), ^{
		self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
		self.previewLayer.frame = self.previewView.bounds;
		self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;

		[[self.previewLayer connection] setVideoOrientation:[self currentVideoOrientation]];
		[self.previewView.layer addSublayer:self.previewLayer];
	});
}

// Re-enable capture session if not currently running
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if (![self.captureSession isRunning]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self.captureSession startRunning];
		});
	}
}

// Stop running capture session when this view disappears
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if ([self.captureSession isRunning]) {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			[self.captureSession stopRunning];
		});
	}
}

#pragma mark - Toggle Front/Back Cameras

- (IBAction)toggleCameras:(id)sender {
	NSError *error;
	AVCaptureDevicePosition position = [[self.activeVideoInput device] position];

	AVCaptureDeviceInput *videoInput;
	if (position == AVCaptureDevicePositionBack) {
		videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionFront] error:&error];
		self.previewLayer.transform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
	} else {
		videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self cameraWithPosition:AVCaptureDevicePositionBack] error:&error];
		self.previewLayer.transform = CATransform3DIdentity;
	}

	if (videoInput) {
		[self.captureSession beginConfiguration];
		[self.captureSession removeInput:self.activeVideoInput];
		if ([self.captureSession canAddInput:videoInput]) {
			[self.captureSession addInput:videoInput];
			self.activeVideoInput = videoInput;
		}
		[self.captureSession commitConfiguration];
	}
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			return device;
		}
	}
	return nil;
}

#pragma mark - Start Recording

- (IBAction)startRecording:(id)sender {

	if ([sender isSelected]) {
		[sender setSelected:NO];
		[self.captureOutput stopRecording];

	} else {
		[sender setSelected:YES];

		if (!self.captureOutput) {
			self.captureOutput = [[AVCaptureMovieFileOutput alloc] init];
			[self.captureSession addOutput:self.captureOutput];
		}

		// Delete the old movie file if it exists
		[[NSFileManager defaultManager] removeItemAtURL:[self outputURL] error:nil];

		[self.captureSession startRunning];

		AVCaptureConnection *videoConnection = [self connectionWithMediaType:AVMediaTypeVideo fromConnections:self.captureOutput.connections];

		if ([videoConnection isVideoOrientationSupported]) {
			videoConnection.videoOrientation = [self currentVideoOrientation];
		}

		if ([videoConnection isVideoStabilizationSupported]) {
			videoConnection.enablesVideoStabilizationWhenAvailable = YES;
		}

		[self.captureOutput startRecordingToOutputFileURL:[self outputURL] recordingDelegate:self];
	}

	// Disable the toggle button if recording
	self.toggleCameraButton.enabled = ![sender isSelected];
}

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections {
	for (AVCaptureConnection *connection in connections) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:mediaType]) {
				return connection;
			}
		}
	}
	return nil;
}

#pragma mark - AVCaptureFileOutputRecordingDelegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
	if (!error) {
		[self presentRecording];
	} else {
		NSLog(@"Error: %@", [error localizedDescription]);
	}
}

#pragma mark - Show Last Recording

- (void)presentRecording {
	NSString *tracksKey = @"tracks";
	AVAsset *asset = [AVURLAsset assetWithURL:[self outputURL]];
	[asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:^{
		NSError *error;
		AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
		if (status == AVKeyValueStatusLoaded) {
			dispatch_async(dispatch_get_main_queue(), ^{
				UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
				THPlayerViewController *controller = [mainStoryboard instantiateViewControllerWithIdentifier:@"THPlayerViewController"];
				controller.title = @"Capture Recording";
				controller.asset = asset;
				[self presentViewController:controller animated:YES completion:nil];
			});
		}
	}];
}

#pragma mark - Handle Video Orientation

- (AVCaptureVideoOrientation)currentVideoOrientation {
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
	if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
		return AVCaptureVideoOrientationLandscapeRight;
	} else {
		return AVCaptureVideoOrientationLandscapeLeft;
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[[self.previewLayer connection] setVideoOrientation:[self currentVideoOrientation]];
}

#pragma mark - Recoding Destination URL

- (NSURL *)outputURL {
	NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *filePath = [documentsDirectory stringByAppendingPathComponent:VIDEO_FILE];
	return [NSURL fileURLWithPath:filePath];
}

@end
