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

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[application setStatusBarHidden:YES];

	NSArray *imageNames = @[@"playback", @"capture", @"compose", @"share"];

	UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
	NSUInteger i = 0;
	for (UITabBarController *controller in tabBarController.viewControllers) {
		UIImage *selectedImage = [UIImage imageNamed:[NSString stringWithFormat:@"tb_%@_selected", imageNames[i]]];
		UIImage *unselectedImage = [UIImage imageNamed:[NSString stringWithFormat:@"tb_%@", imageNames[i]]];
		[controller.tabBarItem setFinishedSelectedImage:selectedImage withFinishedUnselectedImage:unselectedImage];
		i++;
	}


	NSString *bgImageName = @"tb_background";
	NSString *bgSelectionImageName = @"tb_selection_background";

	// If not iPhone 5
	if (!IS_IPHONE_5) {
		bgImageName = [bgImageName stringByAppendingString:@"_ios4"];
		bgSelectionImageName = [bgSelectionImageName stringByAppendingString:@"_ios4"];
	}

	// Change the tabbar's background and selection image through the appearance proxy
	[[UITabBar appearance] setBackgroundImage:[UIImage imageNamed:bgImageName]];
	[[UITabBar appearance] setSelectionIndicatorImage:[UIImage imageNamed:bgSelectionImageName]];

	UIEdgeInsets insets;
	insets = UIEdgeInsetsZero;
	UIImage *navbarImage = [[UIImage imageNamed:@"app_navbar_background"] resizableImageWithCapInsets:insets];
	[[UINavigationBar appearance] setBackgroundImage:navbarImage forBarMetrics:UIBarMetricsDefault];

	insets = UIEdgeInsetsMake(10, 10, 10, 10);
	UIImage *barButtonImage = [[UIImage imageNamed:@"dark_bar_button_background"] resizableImageWithCapInsets:insets];
	[[UIBarButtonItem appearance] setBackgroundImage:barButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
	return YES;
}

@end
