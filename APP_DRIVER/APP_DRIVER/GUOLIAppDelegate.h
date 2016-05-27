//
//  GUOLIAppDelegate.h
//  APP_DRIVER
//
//  Created by xiaobin on 15-12-9.
//  Copyright (c) 2015年 renda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationTracker.h"//LW

@class GUOLIViewController;

@interface GUOLIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GUOLIViewController *viewController;


@property LocationTracker * locationTracker;//LW
@property (nonatomic) NSTimer* locationUpdateTimer;//LW
//- (void)setUpLocationTraker;//LW
//- (void)updateLocation;//LW

@end
