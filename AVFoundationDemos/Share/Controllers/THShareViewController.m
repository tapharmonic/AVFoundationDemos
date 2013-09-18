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

#import "THShareViewController.h"
#import <Social/Social.h>
#import "UIView+THAdditions.h"

@implementation THShareViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	if (!IS_IPHONE_5) {
		self.logoImageView.frameX -= 12.0f;
		self.logoImageView.frameWidth *= 0.80f;
		self.logoImageView.frameHeight *= 0.80f;
		self.containerView.frameX += 12.0f;
	}
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)tweetIt:(id)sender {
	[self postMessageWithName:@"@bobmccune" toService:SLServiceTypeTwitter];
}

- (IBAction)shareIt:(id)sender {
	[self postMessageWithName:@"Bob McCune" toService:SLServiceTypeFacebook];
}

- (void)postMessageWithName:(NSString *)name toService:(NSString *)service {
	SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:service];
	NSString *message = [NSString stringWithFormat:@"Are you interested in AV Foundation?  Check out this demo from %@.", name];
	[controller setInitialText:message];
	[controller addURL:[NSURL URLWithString:@"https://github.com/tapharmonic/AVFoundationDemos"]];
	[self presentViewController:controller animated:YES completion:nil];
}

@end
