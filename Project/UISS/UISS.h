//
//  UISS.h
//  UISS
//
//  Created by Robert Wijas on 10/7/11.
//  Copyright (c) 2011 57things. All rights reserved.
//

#import "UISSConfig.h"
#import "UISSStyle.h"

extern NSString *const UISSWillApplyStyleNotification;
extern NSString *const UISSDidApplyStyleNotification;

extern NSString *const UISSWillRefreshViewsNotification;
extern NSString *const UISSDidRefreshViewsNotification;

@interface UISS : NSObject

@property (nonatomic, strong) UISSConfig *config;
@property (nonatomic, assign) NSTimeInterval refreshInterval;
@property (nonatomic, assign) BOOL statusWindowEnabled;

@property (nonatomic, strong) UISSStyle *style;

- (void)reload;
- (void)registerReloadGestureRecognizerInView:(UIView *)view;

- (void)generateCodeForUserInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom 
                              codeHandler:(void (^)(NSString *code, NSArray *errors))codeHandler;

+ (UISS *)configureWithJSONFilePath:(NSString *)filePath;
+ (UISS *)configureWithDefaultJSONFile;

@end
