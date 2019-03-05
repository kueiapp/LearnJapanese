//
//  InterfaceController.m
//  SiriDiaryWatch Extension
//
//  Created by Kuei on 2/14/19.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "InterfaceController.h"
#import "TableRowController.h"
#import "ExtensionDelegate.h"
@import WatchConnectivity;
@import AVFoundation;

@interface InterfaceController () <WCSessionDelegate>
{
   NSArray *dataArray;
   WCSession *wcsession;
}
@end


@implementation InterfaceController

@synthesize theTable,alertLabel,labelGroup;

- (void)awakeWithContext:(id)context {
   [super awakeWithContext:context];
   
   NSLog(@"awakeWithContext");
    // Configure interface objects here.
   [self setTitle:NSLocalizedString(@"JP Diary", nil)];
   
   // New way to communitate with WatchOS2
   if ([WCSession isSupported]) {
      wcsession = [WCSession defaultSession];
      wcsession.delegate = self;
      [wcsession activateSession];
   }
   else{
      NSLog(@"WCSession is not supported");
   }
   
   // Load from file
   [self loadDataArray];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
   [super willActivate];
   NSLog(@"willActivate........");
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

#pragma mark -- watch table configuration --
- (void)configureTableWithData:(NSArray*)dataObjects {
   
   [theTable setNumberOfRows:dataObjects.count withRowType:@"TableRowController"];
   
   for (NSInteger i = 0; i < self.theTable.numberOfRows; i++) {
      TableRowController* theRow = [self.theTable rowControllerAtIndex:i];
      NSDictionary* dataObj = dataObjects[i];
      NSString *lang = [NSLinguisticTagger dominantLanguageForString:dataObj[@"translatedText"]];
      
      if( ![lang isEqualToString:@"ja"] ){
         [theRow.titleLabel setText:dataObj[@"sourceText"]];
         NSInteger txtLength = [dataObj[@"sourceText"] length];
         NSLog(@"length = %dd", txtLength);
         if( txtLength <=9 ){
            [theRow.titleLabel setHeight:44.0];
         }
         else{
            [theRow.titleLabel setHeight:44.0 * (txtLength % 9)];
         }
      }
      else{
         [theRow.titleLabel setText:dataObj[@"translatedText"]];
         NSInteger txtLength = [dataObj[@"translatedText"] length];
         NSLog(@"length = %dd", txtLength);
         if( txtLength <=9 ){
            [theRow.titleLabel setHeight:44.0];
            [labelGroup setHeight:44.0];
         }
         else{
            [theRow.titleLabel setHeight:44.0 * (txtLength % 9)];
            [labelGroup setHeight:44.0 * (txtLength % 9)];
         }
      }
      
   }
   
   if( (int)self.theTable.numberOfRows > 0 ) [alertLabel setHidden:true];
   
}
-(void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex{
   [self speak:dataArray[rowIndex][@"translatedText"]];
}

-(void)loadDataArray{
   NSArray *dirPath =
   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   NSString *dir = [dirPath objectAtIndex:0];
   // File path
   NSString *notesString = [dir stringByAppendingPathComponent:@"notes"];
   NSArray *arr = [[NSArray alloc] initWithContentsOfFile:notesString];
   
   @try{
      if(arr){
         dataArray = [NSArray arrayWithArray:arr];
         [alertLabel setHidden:true];
      }
      else{
         dataArray = [NSArray new];
         [alertLabel setHidden:false];
      }
      // update UI
      [self configureTableWithData:dataArray];
   }
   @catch( NSException *e ){
      NSLog(@"load file err: %@", e.description);
   }
   
}

-(void)saveDataArray{
   NSArray *dirPath =
   NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
   NSString *dir = [dirPath objectAtIndex:0];
   // Create Documents folder
   if( ![NSFileManager.defaultManager fileExistsAtPath:dir] ){
      [NSFileManager.defaultManager createDirectoryAtPath:dir withIntermediateDirectories:true attributes:nil error:nil];
   }
   // File path
   NSString *notesString = [dir stringByAppendingPathComponent:@"notes"];
   // 如果檔案不存在則初始化array到真實路徑
   if ( ![NSFileManager.defaultManager fileExistsAtPath:notesString] ){
      // 利用NSFileManager操作檔案的增刪
      [NSFileManager.defaultManager createFileAtPath:notesString contents:nil attributes:nil];
   }
   // Write data
   [dataArray writeToFile:notesString atomically:true];
   NSLog(@"saved to %@", notesString);
}

#pragma mark -- WCSession delegate --
-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message{
   
   NSLog(@"got message from watch: %@", message);
   NSArray *arr;
   @try{
      arr = message[@"data"];
      if(arr != nil){
         dataArray = [NSArray arrayWithArray:arr];
      }
      else{
         dataArray = [NSArray new];
      }
      NSLog(@"read array: %@", arr.description);
      [self configureTableWithData:dataArray];
      [self saveDataArray];
   }
   @catch(NSException *e){
      NSLog(@"exception: %@", e.description);
   }
   
}

#pragma mark -- AVAudio --
-(void)speak:(NSString *)msg{
   AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:msg];
   utterance.rate = 0.4;
   // Speech language
   utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
   
   AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
   [synthesizer speakUtterance:utterance];
}

- (IBAction)reloadMenuClicked {
   NSLog(@"reload message............");
   [self loadDataArray];
}





@end



