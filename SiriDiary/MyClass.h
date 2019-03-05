//
//  MyClass.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/8.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MyClass : NSObject

+(UIAlertController *)showAlertControllerWithMessage:(NSString *)msg;
+(void)removeIndicatorInView:(UIView *)view;
+(void)showIndicatorInView:(UIView *)view;
+(void) saveFiles:(NSArray *)_arr  At:(NSString *)_filePath;
+(NSArray *) loadFilesFrom:(NSString *)_filePath;
+(bool)isIphoneX;

@end
