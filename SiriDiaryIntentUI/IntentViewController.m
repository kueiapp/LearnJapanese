//
//  IntentViewController.m
//  SiriDiaryIntentUI
//
//  Created by Kuei on 2019/1/12.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "IntentViewController.h"
@import Intents;
@import AVFoundation;

#define kMainQueue dispatch_get_main_queue()
#define kGroupName @"com.kueiapp.YOUR-GROUP-NAME"
#define LANG_CODE @{@"en":@0,@"zh-Hant":@1}

@interface IntentViewController ()
{
	NSString *inputString,*outputString;
	NSMutableArray *dataMArray;	
}
@end

@implementation IntentViewController

-(void)translateWords:(NSString *)txt{
   // To translate nontranstaled text only
   if( txt ){
      // prepare to connect
      NSCharacterSet *utf8Set = [NSCharacterSet URLFragmentAllowedCharacterSet];
      NSString *token = [txt stringByAddingPercentEncodingWithAllowedCharacters:utf8Set];
      
      NSDictionary *sourceLang = @{@"code":@"zh"};
      NSDictionary *tmp = [NSUserDefaults.standardUserDefaults objectForKey:@"Lang_Setting"];
      if(tmp)sourceLang = tmp;
         
      NSString *query = [NSString stringWithFormat:@"YOUR-TRANSLATE-SERVICE?query=%@&source=%@",token,sourceLang[@"code"]];
      
      
      NSURL *url = [NSURL URLWithString: query];
      NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
      request.HTTPMethod = @"GET";
      request.allHTTPHeaderFields = @{@"Content-Type":@"application/json"};
      
      NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
         // Get http code in response
         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
         if( !error && httpResponse.statusCode == 200){
            @try{
               // Convert JSON to object
               NSJSONSerialization *jsonDecode = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
               // Convert jsonObject to object
               NSDictionary *result = (NSDictionary*) jsonDecode;
               
               if( result != nil && [result[@"code"] intValue] == 200 ){
                  // Update UI
                  self->outputString = result[@"translatedText"];
                  
                  dispatch_async(kMainQueue, ^{
                     self->outputLabel.text = result[@"translatedText"];
                  });
               }
            }
            @catch( NSException *e){
               NSLog(@"parse json error: %@", e.description);
            }
         }
         else{
            NSLog(@"task error: %@", error.description);
         }
      }] ;
      
      [task resume];
    }
}

-(void)speakWords:(NSString *)txt{
   AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:txt];
   AVSpeechSynthesizer *synthesizer = [AVSpeechSynthesizer new];
   utterance.rate = 0.4;
   // Speech language
   utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
   [synthesizer speakUtterance:utterance];
}

-(void)saveToAppGroup{
	NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
	[user setObject: dataMArray forKey: @"intent"];
	[user synchronize];
}


-(void)readFromAppGroup{
	NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
	NSMutableArray *arr = [user valueForKey: @"intent"];
	if(arr != nil){
		[dataMArray arrayByAddingObjectsFromArray:arr];
	}
}
#pragma mark -- App life --
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	outputString = [NSString new];
	dataMArray = [NSMutableArray new];
	[self readFromAppGroup];
	
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:true];
	// Do any additional setup after loading the view.
	inputLabel.text = @"Siri is listening...";
	NSLog(@"viewWillAppear");
}
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:true];
	// Do any additional setup after loading the view.
	inputLabel.text = inputString;
   // Speak
   if( ![outputString isEqualToString:@""] && outputString ){
      NSLog(@"to speak %@", outputString);
      [self speakWords: outputString];
   }
}
- (void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:true];
	if(inputString != nil){
		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary: @{@"sourceText":inputString,@"translatedText":@"",@"imagePath":@""}];
		[dataMArray addObject:dic];
		
		[self saveToAppGroup];	
	}
	else{
		NSLog(@"inputString is nil");	
	}
}
#pragma mark - INUIHostedViewSiriProviding protocol
-(BOOL)displaysMessage{
	return true;
}
-(BOOL)displaysPaymentTransaction{
	return true;
}
-(void)configureWithInteraction:(INInteraction *)interaction context:(INUIHostedViewContext)context completion:(void (^)(CGSize))completion{
   
	if( [[interaction.intent class] isEqual:[INSendMessageIntent class]] ){
		inputLabel.text = [interaction.intent valueForKey:@"content"];
		inputString = [interaction.intent valueForKey:@"content"];
		[inputLabel sizeToFit];
      NSLog(@"got text = %@", inputLabel.text);
      // do transltation
      if( [outputString isEqualToString:@""] ){
         [self translateWords:inputLabel.text];
         
      }
	}
   
	if (completion) {
      completion([self desiredSize]);
		
	}
   
}

- (CGSize)desiredSize {
	return CGSizeMake(320, 180);
}

@end
