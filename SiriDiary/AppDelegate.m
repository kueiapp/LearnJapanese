//
//  AppDelegate.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/3.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SSKeychain.h"
@import Intents;
@import CoreSpotlight;

#define kCloudStorageProductIdentifier @"com.kueiapp.YOUR-ID"
#define kGroupName @"com.kueiapp.YOUR-ID"
#define kMainQueue dispatch_get_main_queue()

@implementation AppDelegate

@synthesize notesMArray, cloudStoragePurchased;;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   // Override point for customization after application launch.
   //[UIApplication.sharedApplication setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
   

   // Watch connectivity session
   if ([WCSession isSupported]) {
      wcsession = [WCSession defaultSession];
      wcsession.delegate = self;
      [wcsession activateSession];
   }
   else{
      NSLog(@"WCSession is not supported");
   }

// Load notes
    self.notesMArray = [NSMutableArray new];
    [self loadNotesFromCloud];
   
   
    // Initialize Google Mobile Ads SDK
    [GADMobileAds configureWithApplicationID:@"YOUR-ADS-ID"];
   
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground.......");
//    [self saveToCloud];
	 [self clearAppGroup];
    [self setupSpotlightIndex];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	NSLog(@"applicationWillEnterForeground.......");
	[self readFromAppGroup];
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -- iCloud --
-(void)loadNotesFromCloud{
   NSLog(@"load notes from device....");
   NSFileManager *fm = NSFileManager.defaultManager;
   // local storage
   NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
   if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
   }
   path = [path stringByAppendingPathComponent:@"mynotes.txt"];
   NSArray *arr = [[NSArray alloc] initWithContentsOfFile:path];
   if(arr != nil ){
      NSLog(@"delegate load from device ok");
      // Init array
      notesMArray = [NSMutableArray arrayWithArray:arr];
      
   }
   
   cloudStoragePurchased = [SSKeychain passwordForService:@"isPurchased"
                                       account:kCloudStorageProductIdentifier];
                                       
#ifdef DEBUG
//   cloudStoragePurchased = @"1";
#endif
   
   if( cloudStoragePurchased.boolValue ){
      NSLog(@"load notes from cloud.....");
      NSFileManager *fm = [NSFileManager defaultManager];
      id token = [fm ubiquityIdentityToken];
      if(token){
         // cloud storage
         NSURL *fileURL = [fm URLForUbiquityContainerIdentifier:nil];
         // File path
         fileURL = [fileURL URLByAppendingPathComponent:@"mynotes.txt"];
         NSLog(@"load cloud path = %@",fileURL.path);
         @try{
            NSArray *arr = [[NSArray alloc] initWithContentsOfURL:fileURL];
            if(arr != nil ){
               NSLog(@"load from cloud arr ok: %@",arr.description);
               notesMArray = [NSMutableArray arrayWithArray:arr];
            }
         }
         @catch( NSException *e ){
            NSLog(@"load from cloud exception: %@",e.description);
         }
      }
      else{
         NSLog(@"cannot get icloud token");
      }
      
   }
   
}

#pragma mark -- App Group --
-(void)saveRecentNotesToWidget{
   NSFileManager *fm = [NSFileManager defaultManager];
   NSURL *baseURL = [fm containerURLForSecurityApplicationGroupIdentifier:@"group.com.kueiapp.YOUR-ID"];
   NSURL *url = [NSURL fileURLWithPath:@"recent_notes.plist" relativeToURL:baseURL];
   NSLog(@"group url = %@",url);
   @try{
      NSMutableArray *arr;
      if( notesMArray.count < 10 ){
         arr = [NSMutableArray arrayWithArray:notesMArray.copy];
      }
      else{
         arr = [NSMutableArray new];
         for( int i=0; i<10; i++ ){
            [arr addObject:notesMArray[i]];
         }
      }
      NSLog(@"prepare arr to save = %@", arr.description);
     
      [arr writeToURL:url atomically:true];
      
   }
   @catch(NSException *e){
      NSLog(@"exception: %@", e.description);
   }
   
}
-(void)saveRecentNotesToWatch{
   NSMutableArray *arr;
   if( notesMArray.count < 10 ){
      arr = [NSMutableArray arrayWithArray:notesMArray.copy];
   }
   else{
      arr = [NSMutableArray new];
      for( int i=0; i<10; i++ ){
         [arr addObject:notesMArray[i]];
      }
   }
   NSDictionary *dic = @{@"data": arr};
   [wcsession sendMessage:dic replyHandler:nil errorHandler:^(NSError * _Nonnull error) {
      NSLog(@"send to watch err: %@", error.description);
   }];
}

-(void)clearAppGroup{
	NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
	[user setObject: @[] forKey: @"intent"];
	[user synchronize];
}

-(void)readFromAppGroup{
	NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
	NSMutableArray *arr = [[user valueForKey: @"intent"] mutableCopy];
	if(arr != nil){
		for(NSDictionary *dic in arr){
			[notesMArray insertObject:dic.mutableCopy atIndex:0];
		}
		// 20190121改加入UITabBarController
		UITabBarController *tbvc = (UITabBarController *)self.window.rootViewController; 
		self.window.rootViewController = tbvc;
		ViewController *vc = tbvc.viewControllers.firstObject;
//		ViewController *vc = (ViewController *)self.window.rootViewController;
		[vc addDataArray:arr];
	}
}
#pragma mark -- Custom URL scheme --
-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    
    BOOL flag = false;
    NSLog(@"Got URL: %@",url.absoluteString);
   
    if ([url.absoluteString rangeOfString:@"?"].location != NSNotFound)
    {
        // Split string by "?"
        NSArray* foo = [url.absoluteString componentsSeparatedByString: @"?"];
        NSString *string1 = [foo objectAtIndex: 0];
        NSString *string2 = [foo objectAtIndex: 1];
        NSLog(@"get parameters: %@,%@", string1, string2);
        if ([string1 isEqualToString:@"YOUR-ID://translate"])
        {
            // sourceText=xx
            NSArray *param = [string2 componentsSeparatedByString: @"="];
            NSString *sourceText =param[1];
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
               @"sourceText": [sourceText stringByRemovingPercentEncoding], 
               @"translatedText": @"",
               @"imagePath": @""
            }];
            NSLog(@"sourceText = %@",[sourceText stringByRemovingPercentEncoding]);
            [self.notesMArray insertObject:dic atIndex:0];
            // Update UI
            UITabBarController *tbvc = (UITabBarController *)self.window.rootViewController;
            self.window.rootViewController = tbvc;
            ViewController *vc = tbvc.viewControllers.firstObject;
            [vc setDataArray: self.notesMArray];
            [vc.theTableView reloadData];
        }
    }
    
    return flag;
}

#pragma mark -- Siri shortcut and Spotlight search --
-(BOOL)application:(UIApplication *)application continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
   
	NSDictionary *dic = userActivity.userInfo;	
	NSLog(@"dic = %@",dic);
	
	UITabBarController *tbvc = (UITabBarController *)self.window.rootViewController; 
	self.window.rootViewController = tbvc;
	ViewController *vc = tbvc.viewControllers.firstObject;
	
	if ( [userActivity.activityType isEqualToString:@"com.kueiapp.YOUR-ID"]){
		[vc talkAllDiaries:nil];
	}	
	
	if ( [userActivity.activityType isEqualToString:@"INSendMessageIntent"]){
		NSLog(@"nothing");
	}
	
	if ( [userActivity.activityType isEqualToString:@"com.apple.corespotlightitem"]){
		NSInteger selectedIndex = [[[dic[@"kCSSearchableItemActivityIdentifier"] componentsSeparatedByString:@"."] lastObject] intValue];		
		NSLog(@"open page at row: %ld", (long)selectedIndex);
		[vc openDetailPageAtRow:selectedIndex];
	}
	
	return true;
}

-(void)application:(UIApplication *)application handleIntent:(nonnull INIntent *)intent completionHandler:(nonnull void (^)(INIntentResponse * _Nonnull))completionHandler{
	
	NSLog(@"handle intent from extension: %@",intent);
}

#pragma mark -- Public functions --
-(NSMutableDictionary *)getSetting{

  NSFileManager *fm = NSFileManager.defaultManager;
  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
  }
  path = [path stringByAppendingPathComponent:@"mynotes_setting.txt"];
  NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];

  if( cloudStoragePurchased.boolValue ){
     NSUbiquitousKeyValueStore *keyStore = [NSUbiquitousKeyValueStore defaultStore];
     NSMutableDictionary *sourceLang = [keyStore objectForKey:@"sourceLang"];
     float speechSpeed = [[keyStore objectForKey:@"speechSpeed"] floatValue];
     NSLog(@"source = %@, speed = %.1f",sourceLang,speechSpeed);
     if(sourceLang){
        dic = [NSMutableDictionary dictionaryWithDictionary:@{@"sourceLang":sourceLang,@"speechSpeed":@(speechSpeed)}];
        NSLog(@"get setting from cloud: %@",dic);
     }
  }
  
  if( !dic ){
     dic = [NSMutableDictionary new];
  }

  return dic;
}

-(void) saveSettingWithData:(NSDictionary *)dicData{
 
  NSDictionary *sourceLang = dicData[@"sourceLang"];
  float speechSpeed = [dicData[@"speechSpeed"] floatValue];

  NSFileManager *fm = NSFileManager.defaultManager;
  NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
  }
  path = [path stringByAppendingPathComponent:@"mynotes_setting.txt"];
  NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary: @{
      @"sourceLang":  sourceLang,
      @"speechSpeed": @(speechSpeed)
  }];

  @try{
      NSLog(@"write setting to %@", path);
      [dic writeToFile:path atomically:true];
  }
  @catch( NSException *e ){
      NSLog(@"write setting to device throw: %@", e.description);
  }
   
 if( cloudStoragePurchased.boolValue ){
     NSLog(@"saveSettingToCloud....");
     NSUbiquitousKeyValueStore *keyStore = [NSUbiquitousKeyValueStore defaultStore];
     [keyStore setObject:sourceLang forKey:@"sourceLang"];
     [keyStore setObject: @(speechSpeed) forKey:@"speechSpeed"];
     [keyStore synchronize];
 }

}
-(NSMutableArray *)getNotesArray{
	return notesMArray;
}

-(void) saveNotes{
   NSFileManager *fm = NSFileManager.defaultManager;
   // local storage
   NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
   if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
   }
   path = [path stringByAppendingPathComponent:@"mynotes.txt"];
   @try{
      [notesMArray writeToFile:path atomically:true];
   }
   @catch(NSException *e){
      NSLog(@"save to device throw: %@", e.description);
   }
   
   if( cloudStoragePurchased.boolValue ){
      NSLog(@"save notes to cloud");
      NSFileManager *fm = [NSFileManager defaultManager];
      // cloud storage token
      id token = [fm ubiquityIdentityToken];
      if(token){
         NSOperationQueue *qu = [NSOperationQueue new];
         [qu addOperationWithBlock:^{
            NSURL *fileURL = [fm URLForUbiquityContainerIdentifier:nil];
            
            if( ![fm fileExistsAtPath:fileURL.path] ){
               [fm createFileAtPath:fileURL.path contents:nil attributes:nil];
             }
            
             @try{
               // File path
                  fileURL = [fileURL URLByAppendingPathComponent:@"mynotes.txt"];
                  NSLog(@"save cloud path = %@",fileURL.path);
                  // 寫入
                  @try{
                     [self->notesMArray writeToURL:fileURL atomically:true];
                     NSLog(@"write to cloud ok");
                  }
                  @catch( NSException *e){
                     NSLog(@"write to cloud exception: %@", e.description);
                  }
               
              }
              @catch( NSException *e){
                  NSLog(@"create dic exception: %@", e.description);
              }
         }];
      }//endif
      else{
         NSLog(@"cannot find icloud token");
      }
   }
   
   [self saveRecentNotesToWatch];
}

#pragma mark -- Spotlight --
-(void)setupSpotlightIndex{
   // Set spotlight indexed item container
   NSMutableArray<CSSearchableItem *> *searchableItems = [NSMutableArray new];
   
   for(int i=0; i<[notesMArray count]; i++){
      NSLog(@"update setupSpotlightIndex");
      // Add items to container from data array
      NSDictionary *dic = notesMArray[i];
      // Set spotlight item attributes
      CSSearchableItemAttributeSet *itemAttribute = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:@"kUTTypeText"];
      itemAttribute.title = dic[@"sourceText"];
      itemAttribute.contentDescription = dic[@"translatedText"];
      
      // Set uniqueId to userInfo in NSUserActivity
      NSString *domainString = [NSString stringWithFormat:@"com.kueiapp.YOUR-ID.%d",i];
      CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:domainString domainIdentifier:@"notes" attributeSet:itemAttribute];
      
      [searchableItems addObject:item];
   }
   
   NSLog(@"index done");
   
   @try{
      // Trigger spotlight to start indexing
      [CSSearchableIndex.defaultSearchableIndex indexSearchableItems:searchableItems completionHandler:^(NSError * _Nullable error) {
         if( error ){
            NSLog(@"spolight err: %@", error.description);
         }
      }];
   }
   @catch( NSException *e ){
      NSLog(@"set spotlight index throw err: %@", e.description);
   }
   
   
}

#pragma mark -- WCSession delegate --
-(void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler{
   
   NSMutableArray *arr;
   if( notesMArray.count < 10 ){
      arr = [NSMutableArray arrayWithArray:notesMArray.copy];
   }
   else{
      arr = [NSMutableArray new];
      for( int i=0; i<10; i++ ){
         [arr addObject:notesMArray[i]];
      }
   }
   NSDictionary *dic = @{@"data": arr};
   
   if( [message[@"content"] isEqualToString:@"reload"] ){
      replyHandler(dic);
   }
}





@end
