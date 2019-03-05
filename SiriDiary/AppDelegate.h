//
//  AppDelegate.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/3.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleMobileAds;
@import WatchConnectivity;

@interface AppDelegate : UIResponder <UIApplicationDelegate,WCSessionDelegate>
{
   NSString *cloudStoragePurchased;
   WCSession *wcsession;
}

@property (strong, nonatomic) UIWindow *window;
@property NSMutableArray *notesMArray;
@property NSString *cloudStoragePurchased;

-(NSMutableArray *)getNotesArray;
-(void) saveNotes;
-(void) saveSettingWithData:(NSDictionary *)dic;
-(NSMutableDictionary *)getSetting;



@end

