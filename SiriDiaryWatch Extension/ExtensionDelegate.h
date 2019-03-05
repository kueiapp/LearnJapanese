//
//  ExtensionDelegate.h
//  SiriDiaryWatch Extension
//
//  Created by Kuei on 2/14/19.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@import WatchConnectivity;

@interface ExtensionDelegate : NSObject <WKExtensionDelegate,WCSessionDelegate>
{
   NSArray *notesArray;
   WCSession *wcsession;
}
-(NSArray *)readNotesData;


@end
