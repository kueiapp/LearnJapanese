//
//  NewsViewController.m
//  SiriDiary
//
//  Created by Kuei on 2/15/19.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "NewsViewController.h"
#import "WebViewController.h"
#import "MyClass.h"
#import "SSKeychain.h"
@import AVFoundation;

#define kRemoveAdsProductIdentifier @"com.kueiapp.YOUR-ID"
#define APPKEY @"YOUR-ID"
#define kMainQueue dispatch_get_main_queue()


@interface NewsViewController () <UITableViewDelegate,UITableViewDataSource>
{
   int loadedPage;
   NSArray *dataArray;
   __weak IBOutlet UITableView *theTableView;
   AVPlayer *avPlayer;
   bool isPlaying;
   NSString *removeAdsPurchased;
   UIButton *g_btn;
   __weak IBOutlet UIView *statusView;
}
@end

@implementation NewsViewController

- (void)viewDidLoad {
   
   [super viewDidLoad];
    // Do any additional setup after loading the view.
   [self.navigationItem setTitle:NSLocalizedString(@"NHK Easy News", nil)];
   
 // Status view
   for( NSLayoutConstraint *height in statusView.constraints ){
      if( [height.identifier isEqualToString:@"statusHeightConstraint"] ){
         if( [MyClass isIphoneX ]){
            height.constant = 44;
         }
         else{
            height.constant = 22;
         }
      }
   }
   
   UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:(UIBarButtonItemStyleDone) target:self action:@selector(reloadPage)];
   
   self.navigationItem.leftBarButtonItems = @[reloadItem];
   
   theTableView.delegate = self;
   theTableView.dataSource = self;
   dataArray = [NSArray new];
   
   // Observe if audio playing is interrupted
   [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(musicInterrupted:) name:AVAudioSessionInterruptionNotification object:nil];
   
   loadedPage = 0;
   [self getNewsWithPage: loadedPage];
   
}

-(void)viewWillAppear:(BOOL)animated{
   [super viewWillAppear:true];
   removeAdsPurchased = [SSKeychain passwordForService:@"isPurchased"
                                    account:kRemoveAdsProductIdentifier];
  
   // Google Ads
   [self loadAds];
}
-(void)viewDidDisappear:(BOOL)animated{
   [super viewDidDisappear:true];
   
   [NSNotificationCenter.defaultCenter removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
   [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
-(void)viewWillLayoutSubviews{
   if (@available(iOS 11.0, *)) {
      [theTableView setInsetsContentViewsToSafeArea:true];
   }
   
   [theTableView setContentInset:(UIEdgeInsetsMake(30, 0, 70, 0))];
   if( [MyClass isIphoneX] ){
      NSLog(@"this is iPhoneX");
      [theTableView setContentOffset:(CGPointMake(0,-100)) animated:true];
   }
   else{
      [theTableView setContentOffset:(CGPointMake(0,-60)) animated:true];
   }
}
#pragma mark -- functions --
-(void)reloadPage{
   [self getNewsWithPage:0];
}

-(void)getNewsWithPage:(int)page{

   [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
   [theTableView setHidden:true];
   [MyClass showIndicatorInView:self.view];
   
   NSString *urlpath = [NSString stringWithFormat:@"YOUR-SERVICE?appid=%@&page=%d",APPKEY,page];
   
   NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlpath]];
   
   // Create the Method "GET" or "POST"
   [urlRequest setHTTPMethod:@"GET"];
   
   NSURLSession *session = [NSURLSession sharedSession];
   NSURLSessionDataTask *dataTask =
   [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
      NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
      if(httpResponse.statusCode == 200){
         NSError *parseError = nil;
         NSDictionary *responseObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
         if( parseError ){
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Opppps"
                     message:@"Cannot get data! Please reload it again"
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:
             [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                              handler:nil]];
            
            dispatch_async(kMainQueue, ^{
               [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
               [self showDetailViewController:alert sender:nil];
               
               [self->theTableView setHidden:true];
               [MyClass removeIndicatorInView:self.view];
            });
            
            NSArray *arr = [MyClass loadFilesFrom:@"easynhk_list.plist"];
            if( arr ){
               self->dataArray = [NSArray arrayWithArray:arr];
            }
            else{
               self->dataArray = [NSArray new];
            }
            
         }
         else{
            if( [responseObj[@"status"] isEqualToString:@"OK"] ){
               // Save to file
               [MyClass saveFiles:responseObj[@"data"] At:@"easynhk_list.plist"];
               dispatch_async(kMainQueue, ^{
                  [self updateUI: responseObj[@"data"]];
                  
                  [UIApplication sharedApplication].networkActivityIndicatorVisible = false;
                  [self->theTableView setHidden:false];
                  [MyClass removeIndicatorInView:self.view];
               });
            }
         }
      }
      else{
         dispatch_async(kMainQueue, ^{
            [MyClass showAlertControllerWithMessage:error.localizedDescription];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
            [self->theTableView setHidden:true];
            [MyClass removeIndicatorInView:self.view];
         });
         
         NSArray *arr = [MyClass loadFilesFrom:@"easynhk_list.plist"];
         if( arr ){
            self->dataArray = [NSArray arrayWithArray:arr];
         }
         else{
            self->dataArray = [NSArray new];
         }
      }
      
   }];
   // Start session
   [dataTask resume];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    UITableViewCell *cell = (UITableViewCell *) sender;
    NSIndexPath *indexPath = [theTableView indexPathForCell:cell];
   
    WebViewController *webV = (WebViewController *)segue.destinationViewController;
    webV.urlPath = dataArray[indexPath.row][@"easy_link"];
    webV.musicPath = dataArray[indexPath.row][@"mp3_url"];
}


-(void)updateUI:(NSArray *)arr{
   dataArray = [NSArray arrayWithArray:arr];
   [theTableView reloadData];
}
#pragma mark UITableview datasource--------
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataArray.count;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   return 148.0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath{

   cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
   
   theTableView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
   for(UIView *v in cell.contentView.subviews ){
      if(v.tag == 8939){
         [v removeFromSuperview];
      }
   }
   
   theTableView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
   UIView *whiteRoundedCornerView = [[UIView alloc] initWithFrame:CGRectMake(10,5,cell.frame.size.width-20,cell.frame.size.height-10)];
   whiteRoundedCornerView.tag = 8939;
   whiteRoundedCornerView.backgroundColor = [UIColor whiteColor];
   whiteRoundedCornerView.layer.borderColor = [UIColor whiteColor].CGColor;
   whiteRoundedCornerView.layer.borderWidth = 1.0;
   whiteRoundedCornerView.layer.masksToBounds = NO;
   whiteRoundedCornerView.layer.cornerRadius = 5.0;
   
   whiteRoundedCornerView.layer.shadowOffset = CGSizeMake(0, 0);
   whiteRoundedCornerView.layer.shadowOpacity = 0.2;
   whiteRoundedCornerView.layer.shadowColor = [UIColor blackColor].CGColor;
   [cell.contentView addSubview:whiteRoundedCornerView];
   [cell.contentView sendSubviewToBack:whiteRoundedCornerView];
}

-(UITableViewCell*)tableView:(UITableView *)tableView
cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SubtitleCell" ;
    UITableViewCell *cell = nil;
   
 // Configure the cell...
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil){
        cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                 forIndexPath:indexPath];
    }
   
 // Customize cell
    NSDictionary *dic = dataArray[indexPath.row];
    cell.textLabel.text = dic[@"title"];
    cell.detailTextLabel.text = dic[@"publish_date"];
   
// Customize accessoryView
    UIButton *btn = [UIButton buttonWithType:(UIButtonTypeRoundedRect)];
    [btn setFrame:CGRectMake(0, 0, 66, 66)];
    [btn addTarget:self action:@selector(playMusic:) forControlEvents:(UIControlEventTouchUpInside)];
    [btn setImage:[UIImage imageNamed:@"speaker.png"] forState:(UIControlStateNormal)];
    cell.accessoryView = btn;
   
    return cell;

}
#pragma mark UITableView delegate -------------
-(void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

#pragma mark -- Music playing ---
-(void)pauseMusic{
   if( isPlaying ){
      if( avPlayer ){
         isPlaying = false;
         [avPlayer pause];
      }
   }
   // update UI
   [theTableView reloadData];
   self.navigationItem.rightBarButtonItems = nil;
   [self.view reloadInputViews];
}

-(void)addPauseButtonAtTop{
   
   UIBarButtonItem *pauseItem = [[UIBarButtonItem alloc] initWithTitle:@"Pause" style:(UIBarButtonItemStyleDone) target:self action:@selector(pauseMusic)];
   
   self.navigationItem.rightBarButtonItems = @[pauseItem];
   [self.view reloadInputViews];
}

-(void)playMusic:(id)sender{
   
   if( isPlaying ){
      if( avPlayer ){
         isPlaying = false;
         [avPlayer pause];
         // update UI
         [g_btn setImage:[UIImage imageNamed:@"speaker.png"] forState:(UIControlStateNormal)];
         [self.view reloadInputViews];
      }
   }
   
   UITableViewCell *cell = (UITableViewCell *)[sender superview];
   NSIndexPath *indexPath = [theTableView indexPathForCell:cell];
   NSString *musicPath = dataArray[indexPath.row][@"mp3_url"];
   NSURL *musicUrl = [NSURL URLWithString:musicPath];
   
   @try{
      NSError *err;
      // 背景播放
      [AVAudioSession.sharedInstance setCategory:(AVAudioSessionCategoryPlayback) error:&err];
      
      if( err ){
         [MyClass showAlertControllerWithMessage:[NSString stringWithFormat:@"Audio Player error: %@",err.description]];
      }
      else{
         NSLog(@"prepare av player");
         AVPlayerItem  *item = [AVPlayerItem  playerItemWithURL:musicUrl];

      // Remote mp3 is using AVPlayer
         avPlayer = [AVPlayer playerWithPlayerItem:item];
         if( avPlayer){
            
            [self addPauseButtonAtTop];

         
          // update UI
            UIButton *btn = (UIButton *)sender;
            [btn setImage:[UIImage imageNamed:@"pause.png"] forState:(UIControlStateNormal)];
            g_btn = btn;
            
            [avPlayer play];
            isPlaying = true;
            
         // Detect audio is pause
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(audioIsEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayer.currentItem];
         }
         else{
            [MyClass showAlertControllerWithMessage:@"Something wrong when getting audio, please try later."];
         }

      }
   }
   @catch( NSException *e ){
      NSLog(@"music playing err: %@", e.description);
   }

   
}
/** Detecting audio is end */
-(void)audioIsEnd:(NSNotification *)notification{

   dispatch_async(kMainQueue, ^{
      [self->g_btn setImage:[UIImage imageNamed:@"speaker.png"] forState:(UIControlStateNormal)];
   });
   
}
/** Detecting audio interruption */
-(void)musicInterrupted:(NSNotification *)notification{
   NSDictionary *userinfo = notification.userInfo;
   NSNumber *interruptionKey = userinfo[AVAudioSessionInterruptionTypeKey];
   
   if( interruptionKey.unsignedIntValue == AVAudioSessionInterruptionTypeBegan ){
      NSLog(@"music interrupted");
   }
   else if( interruptionKey.unsignedIntValue == AVAudioSessionInterruptionTypeEnded ){
      NSLog(@"music ends interruption");
      NSNumber *interruptionOptionKey = userinfo[AVAudioSessionInterruptionOptionKey];
      if( interruptionOptionKey.unsignedIntValue == AVAudioSessionInterruptionOptionShouldResume ){
         [avPlayer play];
      }
   }
}

#pragma mark -- Google ads --
-(void)loadAds{
    // Google ads
    adsBannerView.adUnitID = @"YOUR-ADS-ID";
    adsBannerView.rootViewController = self;
    adsBannerView.delegate = self;
    adsBannerView.adSizeDelegate = self;
    // Load an ad
    [DFPRequest request].testDevices = @[ kGADSimulatorID ];
    [adsBannerView loadRequest:[GADRequest request]];
   
   // Paid and no ads
   if( [removeAdsPurchased isEqualToString:@"1"] ){
         // Set ads bannerView's height as zero
      for( NSLayoutConstraint *height in adsBannerView.constraints ){
         if( [height.identifier isEqualToString:@"adsHeightConstraint"] ){
            
            height.constant = 0.0;
         }
      }
   }
   
   [self.view reloadInputViews];
}
-(void)adView:(GADBannerView *)bannerView willChangeAdSizeTo:(GADAdSize)size{
    NSLog(@"GAD size changed");
}
/** Tells the delegate an ad request loaded an ad */
- (void)adViewDidReceiveAd:(DFPBannerView *)adView {
    NSLog(@"adViewDidReceiveAd");
    adsBannerView.alpha = 0;
    [UIView animateWithDuration:1.0 animations:^{
        self->adsBannerView.alpha = 1;
    }];
}
/** Tells the delegate an ad request failed */
- (void)adView:(DFPBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

@end
