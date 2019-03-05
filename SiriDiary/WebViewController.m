//
//  WebViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/21.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "WebViewController.h"
#import "MyClass.h"
@import AVFoundation;

#define kMainQueue dispatch_get_main_queue()

@interface WebViewController ()
{
   AVPlayer *avPlayer;
   bool isPlaying;
   UIBarButtonItem *mp3Item;
}
@end

@implementation WebViewController

@synthesize urlPath,musicPath;

- (void)viewDidLoad {

    [super viewDidLoad];
    // Do any additional setup after loading the view.
   UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:(UIBarButtonItemStyleDone) target:self action:@selector(reloadPage)];
   
   mp3Item = [[UIBarButtonItem alloc] initWithTitle:@"MP3" style:(UIBarButtonItemStyleDone) target:self action:@selector(playMusic)];
   mp3Item.tag = 890;
 
   self.navigationItem.rightBarButtonItems = @[reloadItem,mp3Item];
 
	theWebView.delegate = self;
	NSURL *url = [NSURL URLWithString: urlPath];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[theWebView loadRequest:request];
 
   [self.navigationItem setTitle:@""];
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
	UIApplication.sharedApplication.networkActivityIndicatorVisible = true;
	[MyClass showIndicatorInView:self.view];
}
-(void)webViewDidFinishLoad:(UIWebView *)webView{
	UIApplication.sharedApplication.networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.view];
}

-(void)reloadPage{
   NSURL *url = [NSURL URLWithString: urlPath];
   NSURLRequest *request = [NSURLRequest requestWithURL:url];
   [theWebView loadRequest:request];
}

-(void)playMusic{
   if( !isPlaying ){
   
      NSURL *musicUrl = [NSURL URLWithString:musicPath];
      for(UIBarButtonItem *item in self.navigationItem.rightBarButtonItems){
         if(item.tag == 890)[item setTitle:@"Pause"];
      }
      [self.view reloadInputViews];
      
      @try{
         NSError *err;
         [AVAudioSession.sharedInstance setCategory:(AVAudioSessionCategoryPlayback) error:&err];
         if( err ){
            [MyClass showAlertControllerWithMessage:[NSString stringWithFormat:@"Audio Player error: %@",err.description]];
         }
         else{
            NSLog(@"prepare av player");
            AVPlayerItem  *item = [AVPlayerItem  playerItemWithURL:musicUrl];
   // Local file
   //         avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicUrl error:&err];

   // Remote mp3 is using AVPlayer
            avPlayer = [AVPlayer playerWithPlayerItem:item];
            if( avPlayer){
               NSLog(@"avPlayer is playing");
               AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
               layer.frame = CGRectMake(0, 0, 10, 55);
               [self.view.layer addSublayer:(layer)];
               
               [avPlayer play];
               
               // Detect audio is pause
               [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(audioIsEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayer.currentItem];
            }
            else{
               NSLog(@"avPlayer is not ready");
            }

         }
      }
      @catch( NSException *e ){
         NSLog(@"music playing err: %@", e.description);
      }
   }
   else{
      if( avPlayer ){
         [avPlayer pause];
         // update UI
         for(UIBarButtonItem *item in self.navigationItem.rightBarButtonItems){
            if(item.tag == 890)[item setTitle:@"MP3"];
         }
         [self.view reloadInputViews];
      }
   }
   
   isPlaying = !isPlaying;
}
/** Detecting audio is end */
-(void)audioIsEnd:(NSNotification *)notification{

   dispatch_async(kMainQueue, ^{
      for(UIBarButtonItem *item in self.navigationItem.rightBarButtonItems){
         if(item.tag == 890)[item setTitle:@"MP3"];
      }
   });
   
}

@end
