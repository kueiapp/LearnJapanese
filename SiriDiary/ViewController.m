//
//  ViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/3.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "ViewController.h"
#import "SecondViewController.h"
#import "AppDelegate.h"
#import "MenuTableViewController.h"
#import "MyClass.h"
#import "SSKeychain.h"
#import "HintViewController.h"
@import AVFoundation;
@import Intents;
@import IntentsUI;


#define kMainQueue dispatch_get_main_queue()
#define kGADSimulatorID @"YOU-ID"
#define kRemoveAdsProductIdentifier @"com.kueiapp.YOUR-ID"
#define kCloudStorageProductIdentifier @"com.kueiapp.YOUR-ID"
#define kGroupName @"group.com.kueiapp.YOUR-ID"
#define LANG_CODE @{@"en":@0,@"zh-Hant":@1,@"ja":@2}

@interface ViewController ()
{
	// private members
	BOOL keyboardVisible;
    MenuTableViewController *menuvc;
	NSInteger selectedRow;
    NSString *removeAdsPurchased, *cloudStoragePurchased;
	__weak IBOutlet NSLayoutConstraint *containerViewHeight;
	AVSpeechSynthesizer *synthesizer;
   UIView *whiteRoundedCornerView;
   __weak IBOutlet UIView *statusView;
}
@end

@implementation ViewController

@synthesize theTableView;

static CGFloat speechSpeed;
static NSMutableDictionary *sourceLang;

#pragma mark -- public methods --
-(void) setDataDic: (NSMutableDictionary *)newDic atIndex:(NSInteger)index{
	dataMArray[index] = newDic.mutableCopy;
	
	[theTableView reloadData];	
}
-(void)setSettingDic:(NSDictionary *)dic{
	sourceLang = dic[@"sourceLang"];
	speechSpeed = [dic[@"speechSpeed"] floatValue];
}
-(void)setDataArray:(NSMutableArray *)newArray{
    dataMArray = [NSMutableArray arrayWithArray: newArray];
}
// AppDelegate load AppGroup data and add into it
-(void)addDataArray:(NSMutableArray *)newArray{
	if(newArray != nil && dataMArray != nil)
	for(NSDictionary *dic in newArray){
		[dataMArray insertObject:dic.mutableCopy atIndex:0];
		[theTableView reloadData];
	}
}
-(IBAction)showHintVC:(id)sender{
	HintViewController *hintVC = [self.storyboard instantiateViewControllerWithIdentifier:@"HintViewController"];
	[self presentViewController:hintVC animated:true completion:nil];
}
#pragma mark -- App lifecycle --
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	
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
   
 
// Init speaker
	synthesizer = [[AVSpeechSynthesizer alloc] init];
	[self styleContainerView];
	
// Init
   AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
   NSArray *arr = [app getNotesArray];
   if( arr && arr.count > 0 ){
      dataMArray = [NSMutableArray arrayWithArray:arr];
   }
   else{
      dataMArray = [[NSMutableArray alloc] initWithArray:@[
        [NSMutableDictionary dictionaryWithDictionary: @{
          @"sourceText":@"Notes your daily sentences",
          @"translatedText":@"あなたの用語をメモして",
          @"imagePath":@""
        }],
        [NSMutableDictionary dictionaryWithDictionary:@{
           @"sourceText":@"寫下你每天的字句",
           @"translatedText":@"あなたの用語をメモして",
           @"imagePath":@""
        }]
      ]];
   }

// Getting setting file
   NSMutableDictionary *dicM = [NSMutableDictionary dictionaryWithDictionary:[app getSetting]];
   NSLog(@"get setting values: %@",dicM);
   
   if(dicM){
      sourceLang = [dicM objectForKey:@"sourceLang"];
      speechSpeed = [[dicM objectForKey:@"speechSpeed"] floatValue];
   }
   else{
      speechSpeed = 0.4;
      sourceLang = [NSMutableDictionary dictionaryWithDictionary:@{
       @"code": @"zh",
       @"name": @"Chinese"
      }];
   }
   
   
// keyboard observer
    [self registerForKeyboardNotifications];
    
    theTableView.delegate = self;
    theTableView.dataSource = self;
    theSearchBar.delegate = self;
   
    UILabel *lbl = [[UILabel alloc] initWithFrame:(CGRectMake(10, -35, theTableView.frame.size.width, 44))];
    lbl.text = @"Translated by Google";
	 [theTableView addSubview: lbl];
   
// Set new image for bookmark button
    [theSearchBar setImage:[UIImage imageNamed:@"ic_more_vert_black_24dp"] forSearchBarIcon:(UISearchBarIconBookmark) state:(UIControlStateNormal)];
   
// Add gesture to tableview and cell
    UILongPressGestureRecognizer *g = [UILongPressGestureRecognizer new];
    [g addTarget:self action:@selector(handleCopyJP:)];
    g.delegate = self;
    [theTableView addGestureRecognizer:g];
	
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:true];
	
	containerViewHeight.constant = 0;
	
// IAP
	removeAdsPurchased = [SSKeychain passwordForService:@"isPurchased"
												account:kRemoveAdsProductIdentifier];
	
	// Google Ads
	[self loadAds];
	
}
-(void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:true];
   
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:true];
    [self removeKeyboardNotifications];
	
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(void)viewWillLayoutSubviews{
   if (@available(iOS 11.0, *)) {
      [theTableView setInsetsContentViewsToSafeArea:true];
   }
   
   [theTableView setContentInset:(UIEdgeInsetsMake(70, 0, 66, 0))];
   
   if( [MyClass isIphoneX] )
      [theTableView setContentOffset:(CGPointMake(0,-90)) animated:true];
   else
      [theTableView setContentOffset:(CGPointMake(0,-66)) animated:true];
   
}
-(void)styleContainerView{
	
	theContainerView.layer.cornerRadius = 5.0;
	theContainerView.layer.backgroundColor = [UIColor clearColor].CGColor;
	theContainerView.backgroundColor = [UIColor clearColor];
	
	for(NSLayoutConstraint *c in theContainerView.constraints){
		if( [c.identifier isEqualToString:@"ContainerViewHeight"] ){
			NSLog(@"got constraint height");
		}
	}
	
// background view
	UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(
		 0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	
// Blur View
	if (!UIAccessibilityIsReduceTransparencyEnabled()) {
		blackView.backgroundColor = [UIColor clearColor];
		
		UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
		UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		blurEffectView.frame = blackView.bounds;
		blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		[blackView addSubview:blurEffectView];
		[blackView sendSubviewToBack:blurEffectView];
	}
	else {
		NSLog(@"it's black bg");
		blackView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.9];
	}
	
	[theContainerView addSubview:blackView];
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
    if(removeAdsPurchased.boolValue){
      for( NSLayoutConstraint *height in adsBannerView.constraints ){
         if( [height.identifier isEqualToString:@"adsHeightConstraint"] ){
            NSLog(@"height.identifier: %@ = 0",height.identifier);
            height.constant = 0.0;
         }
      }
    }
}
/** Tells the delegate an ad request failed */
- (void)adView:(DFPBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

#pragma mark -- Segue --
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	 Get the new view controller using [segue destinationViewController].
//	 Pass the selected object to the new view controller.
	if([segue.identifier isEqualToString:@"SecondViewSegue"]){
		SecondViewController *vc = [segue destinationViewController];
		NSIndexPath *index = [theTableView indexPathForSelectedRow];
		NSMutableDictionary *dataMDic = [dataMArray[index.row] mutableCopy];
		vc.dataUnwindBackDic = [@{@"indexPath":index,@"data":dataMDic} mutableCopy];
	}
	
}
#pragma mark -- unwind action --
-(IBAction) unwindToThisView:(UIStoryboardSegue *)sender {
	SecondViewController *vc = sender.sourceViewController;
	NSMutableDictionary *dataBack = vc.dataUnwindBackDic.mutableCopy;
   
	NSIndexPath *indexPath = dataBack[@"indexPath"];
	dataMArray[indexPath.row] = [dataBack[@"data"] mutableCopy];
	
	[theTableView reloadData];	
	[self saveToDevice];
	
}
#pragma mark -- UITableview datasource --
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{

	NSDictionary *dic  = dataMArray[indexPath.row];
	NSString *sourceText = dic[@"sourceText"], *translatedText = dic[@"translatedText"];
		
	CGFloat rowHeight = 150.0;
	@try{
		
		if ( @available(iOS 11.0, *) ) { // iOS11以上

			NSString *lang = [NSLinguisticTagger dominantLanguageForString:sourceText];

			unsigned int srcRow = 2, targetRow = 2;
			CGFloat srclabelHeight = 20, dstLabelHeight = 46;
         
			switch ( [[LANG_CODE objectForKey:lang] intValue] ) {
				case 0:{ // en
					srcRow = ceil( (float)sourceText.length / 29 );
					break;
				}
				case 1:{ // zh-Hang
					srcRow = ceil( (float)sourceText.length / 13);
					break;
				}
            case 2:{ // ja
               srcRow = ceil( (float)sourceText.length / 12);
               break;
            }
			}
         
         if ( [[LANG_CODE objectForKey:lang] intValue] == 2 ){
// if jp is input, original source lang is target lang
// srclabelHeight = 47; dstLabelHeight = 34;
            lang = sourceLang[@"code"];
            switch ( [[LANG_CODE objectForKey:lang] intValue] ) {
               case 0:{ // en
                  targetRow = ceil( (float)translatedText.length / 21 );
                  break;
               }
               case 1:{ // zh-Hang
                  targetRow = ceil( (float)translatedText.length / 7);
                  break;
               }
               case 2:{ // ja
                  targetRow = ceil( (float)translatedText.length / 6);
                  break;
               }
            }
         }
         else{
            targetRow = ceil( (float)translatedText.length / 5);
         }
         
         if( targetRow == 1) targetRow = 2;
         if( srcRow == 1) srcRow = 2;
         
			rowHeight = srcRow * srclabelHeight + targetRow * dstLabelHeight;
			
		} else {
      // Fallback on earlier versions
			rowHeight = 150.0;
		}
	
	}
	@catch( NSException *e){
		NSLog(@"set height of row dynamically throw: %@",e.description);	
	}
	
	return rowHeight;
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataMArray.count;
}
#pragma mark -- do translation --
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell 
forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    // To translate nontranstaled text only
    NSString *translatedText = dataMArray[indexPath.row][@"translatedText"],
      *sourceText = dataMArray[indexPath.row][@"sourceText"];
    if( translatedText.length == 0 ){
   // prepare to connect
		NSString *token = [sourceText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
      NSString *query;
      
      if ( @available(iOS 11.0, *) ) { // iOS11以上
          NSString *lang = [NSLinguisticTagger dominantLanguageForString:sourceText];
          // 偵測來源文字語言
          switch ( [[LANG_CODE objectForKey:lang] intValue] ) {
             case 2:{ // ja
                query = [NSString stringWithFormat:@"LINK-TO-TRANSLATES-SERVICE?query=%@&source=%@&target=%@",token,@"ja",sourceLang[@"code"]];
                
                break;
             }
             default:{ // en, zh
                query  = [NSString stringWithFormat:@"LINK-TO-TRANSLATES-SERVICE?query=%@&source=%@&target=ja",token,sourceLang[@"code"]];
                
                break;
             }
          }
         
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
                       NSLog(@"result: %@", result.description);
                      
                       if( result != nil && [result[@"code"] intValue] == 200 ){
                           self->dataMArray[indexPath.row][@"translatedText"] = result[@"translatedText"];
                           // Update UI
                           dispatch_async(kMainQueue, ^{
                              [self updateUI:(NSIndexPath *)indexPath];
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
       else{
          NSLog(@"iOS version is lower than 11");
       }
    }
   
    [self addShadowToCellView:cell];
}

-(void)addShadowToCellView:(UITableViewCell *)cell{
   
// shadowing
    cell.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];

   theTableView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.9];
   for(UIView *v in cell.contentView.subviews ){
      if(v.tag == 9839){
         [v removeFromSuperview];
      }
   }
   
   UIView *whiteRoundedCornerView = [[UIView alloc] initWithFrame:CGRectMake(10,5,cell.frame.size.width-20,cell.frame.size.height-10)];
   whiteRoundedCornerView.tag = 9839;
   whiteRoundedCornerView.backgroundColor = [UIColor whiteColor];
   whiteRoundedCornerView.layer.borderColor = [UIColor whiteColor].CGColor;
   whiteRoundedCornerView.layer.borderWidth = 1.0;
   whiteRoundedCornerView.layer.masksToBounds = NO;
   whiteRoundedCornerView.layer.cornerRadius = 5.0;
   
   whiteRoundedCornerView.layer.shadowOffset = CGSizeMake(0, 0);
   whiteRoundedCornerView.layer.shadowOpacity = 0.4;
   whiteRoundedCornerView.layer.shadowColor = [UIColor blackColor].CGColor;
   [cell.contentView addSubview:whiteRoundedCornerView];
   [cell.contentView sendSubviewToBack:whiteRoundedCornerView];
   
}
-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
   NSLog(@"end display cell.....");
}

-(UITableViewCell*)tableView:(UITableView *)tableView
       cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell" ;
    UITableViewCell *cell = nil;
    
    // Configure the cell...
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil){
        cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier
                                                                 forIndexPath:indexPath];
    }
    
    // Customize cell
    NSDictionary *dic = dataMArray[indexPath.row];
    cell.textLabel.text = dic[@"sourceText"];
    cell.detailTextLabel.text = dic[@"translatedText"];
   
    // Accessory View button
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setImage:[UIImage imageNamed:@"speaker.png"] forState:(UIControlStateNormal)];
    [btn setFrame:CGRectMake(0, 0, 66, 66)];
    btn.tag = indexPath.row;
    [btn addTarget:self action:@selector(speakSentence:) forControlEvents:(UIControlEventTouchUpInside)];
    
    cell.accessoryView = btn;
   
   
   
    return cell;
    
}

-(BOOL)tableView:(UITableView *)tableView
canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return true;
}
- (BOOL)tableView:(UITableView *)tableView
canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return false;
}

-(NSString*)tableView:(UITableView *)tableView  titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath * _Nonnull)indexPath{
    return @"Delete";
}
#pragma mark -- UITableView delegate --
-(void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete){
      // Delete data
        [dataMArray removeObjectAtIndex:indexPath.row];
		// Save to device first
        [self saveToDevice];
      // Remove UI
        [theTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationFade)];
    }
   
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
	selectedRow = indexPath.row;
	
}


#pragma mark -- trigger child ViewController --
-(void)dismissMenu:(UITapGestureRecognizer *)gesture{
    NSLog(@"tap on blackView");
    [UIView animateWithDuration:1.0 animations:^{
        self->menuvc.view.frame = CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width*2/3, self.view.frame.size.height);
       
    } completion:^(BOOL finished) {
       
        // Remove menuvc
        if(self->menuvc){
            [self->menuvc.view removeFromSuperview];
            [self->menuvc removeFromParentViewController];
            self->menuvc = nil;
        }
        for(UIView *v in self.view.subviews){
            if(v.tag == 6666 || v.tag == 7777){
                // Black view and containerView
                [v removeFromSuperview];
            }
        }
       
   // update Setting values
        AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
        NSMutableDictionary *dicM = [app getSetting];
        if(dicM){
           sourceLang = [dicM objectForKey:@"sourceLang"];
           speechSpeed = [[dicM objectForKey:@"speechSpeed"] floatValue];
        }
       
    }];
}
-(void)triggerMenu{
   UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
   [blackView setTag:6666];
   [blackView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.7]];
   [self.view addSubview:blackView];
   
   UIView *blackView2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/5, self.view.frame.size.height)];
   [blackView2 setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.0]];
   UITapGestureRecognizer  *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
              action:@selector(dismissMenu:)];
   [blackView2 setGestureRecognizers:@[tap]];
   [blackView addSubview:blackView2];
   
   UIView *containerView = [UIView new];
   [containerView setTag:7777];

   containerView.frame = CGRectMake(self.view.frame.size.width, 0, 0, self.view.frame.size.height);
   
   [blackView addSubview:containerView];
   
   menuvc = [self.storyboard instantiateViewControllerWithIdentifier:@"MenuViewController"];
   menuvc.view.frame = containerView.bounds;
   [menuvc didMoveToParentViewController:self];
   [self addChildViewController: menuvc];
   [containerView addSubview: menuvc.view];
   
// Display view+
   [UIView animateWithDuration:1.0 animations:^{
      containerView.frame = CGRectMake(self.view.frame.size.width/5, 0, self.view.frame.size.width*4/5, self.view.frame.size.height);
   }];
   
}
#pragma mark -- SearchBar delegate --
-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
// Hide keyboard
    [theSearchBar resignFirstResponder];
    [theSearchBar endEditing:true];
    theSearchBar.showsCancelButton = false;
// Clear
    theSearchBar.text = @"";
}

#pragma mark -- SearchBar delegate Menu ViewController --
-(void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar{
   
   [self triggerMenu];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    // show cancel button
    theSearchBar.showsCancelButton = true;
    // show keyboard and shrink tableview
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [self addDiary:searchBar.text];
    searchBar.text = @"";
}

-(IBAction)menuBtnClicked:(id)sender{
   [self triggerMenu];
}

#pragma mark -- Keyboard events --
- (void)registerForKeyboardNotifications
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardUp:) name:UIKeyboardDidShowNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDown:) name:UIKeyboardDidHideNotification object:nil];
}
-(void)removeKeyboardNotifications{
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}
- (void)keyboardUp:(NSNotification*)aNotification
{
    if(keyboardVisible){
        NSLog(@"ignore");
        return;
    }
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSLog(@"kbSize:%f",kbSize.height);
    // Modify contentSize (ContainerView)
    theTableView.contentSize = CGSizeMake(self.view.frame.size.width,theTableView.contentSize.height+kbSize.height);
   
    keyboardVisible = true;
    
}
- (void)keyboardDown:(NSNotification*)aNotification
{
    
    if (!keyboardVisible) {
        NSLog(@"Keyboard already hidden. Ignoring notification.");
        return;
    }
    NSLog(@"keyboardWillBeHidden");
    keyboardVisible = false;
}
#pragma mark -- functions --
-(void)updateUI:(NSIndexPath *)indexPath{
// Refresh UI
	[theTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:(UITableViewRowAnimationAutomatic)];
// Save to device first
	[self saveToDevice];
	
}
-(void)addDiary:(NSString *)inputString{
    if( inputString != nil ){
        [dataMArray insertObject:
          [NSMutableDictionary dictionaryWithDictionary: @{@"sourceText":inputString,@"translatedText":@"",@"imagePath":@""}] atIndex: 0];
      // Update UI then do translation
        [theTableView reloadData];
		
    }
}
#pragma mark -- speak words in a row --
-(void)speakSentence:(UIButton *)btn{
    
    UITableViewCell *cell = (UITableViewCell *) btn.superview;
    NSIndexPath *indexPath = [theTableView indexPathForCell:cell];
    NSLog(@"accessory index:%ld",(long)indexPath.row);
   
    if( ![cell.detailTextLabel.text isEqualToString:@""] ){
       
       // Speech API
       AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
       
       // detect codec of translatedText
       int langNo = 0;
       if (@available(iOS 11.0, *)) {
          NSString *lang = [NSLinguisticTagger dominantLanguageForString:cell.detailTextLabel.text];
          langNo = [[LANG_CODE objectForKey:lang] intValue];
       }

       AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:(langNo==2?cell.detailTextLabel.text:cell.textLabel.text)];
       
        utterance.rate = speechSpeed;
        // Speech language
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
        [synthesizer speakUtterance:utterance];
       
      // Detect audio is pause
      
    }
    else{
        NSLog(@"no sentence");
    }
}
/** Detecting audio is end */
-(void)audioIsEnd:(NSNotification *)notification{
   NSLog(@"userInfo = %@",notification.userInfo);
}

#pragma mark -- iCloud --
-(void) loadSettingValues{
   
   AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
  NSMutableDictionary *dicM = [NSMutableDictionary dictionaryWithDictionary:[app getSetting]];
  if(dicM){
     sourceLang = [dicM objectForKey:@"sourceLang"];
     speechSpeed = [[dicM objectForKey:@"speechSpeed"] floatValue];
  }
  
  [theTableView reloadData];
  
}
-(NSDictionary *) getSettingValues{
	return @{@"speed":@(speechSpeed)};
}

-(void) saveToDevice{
   AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
   app.notesMArray = [NSMutableArray arrayWithArray:dataMArray];
   app.cloudStoragePurchased = [SSKeychain passwordForService:@"isPurchased"
                                                      account:kCloudStorageProductIdentifier];
   
   [app saveNotes];
   
}
-(void)readFromAppGroup{
	NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
	NSMutableArray *arr = [[user valueForKey: @"intent"] mutableCopy];
	NSLog(@"from group: %@", arr);
	if(arr != nil){
		for(NSDictionary *dic in arr){
			[dataMArray insertObject:dic.mutableCopy atIndex:0];
		}
		[theTableView reloadData];
      [self clearAppGroup];
	}
}

-(void) clearAppGroup{
   NSUserDefaults *user = [[NSUserDefaults alloc] initWithSuiteName: kGroupName];
   NSMutableArray *arr = [[user valueForKey: @"intent"] mutableCopy];
   [arr removeAllObjects];
   [user setObject:arr forKey:kGroupName];
}

#pragma mark -- Siri Shortcut --
-(IBAction)pauseTalk:(id)sender{
	[synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate]; 
}
-(IBAction)talkAllDiaries:(id)sender{
   
   AVAudioSession *session = [AVAudioSession sharedInstance];
   [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
   
	for(NSDictionary *dic in dataMArray){
		// Speech API
		if( ![dic[@"translatedText"] isEqualToString:@""]){
         // detect codec of translatedText
         int langNo = 0;
         if (@available(iOS 11.0, *)) {
            NSString *lang = [NSLinguisticTagger dominantLanguageForString:dic[@"translatedText"]];
            langNo = [[LANG_CODE objectForKey:lang] intValue];
         } else {
            // Fallback on earlier versions
         }
         
         AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:(langNo==2?dic[@"translatedText"]:dic[@"sourceText"])];
			// 可調速
			utterance.rate = speechSpeed;
			// Speech language
			utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
			[synthesizer speakUtterance:utterance];
		}
		else{
			NSLog(@"no sentence");
		}
	}
}

-(void)addDiaryFromSiri:(NSString *)msg{
	// Add to table data
	NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary: 
								@{@"sourceText":msg,@"translatedText":@""}];
	[dataMArray insertObject:dic atIndex:0];
	[theTableView reloadData];
}
-(void)openDetailPageAtRow:(NSInteger)row{
	// Select a row
	selectedRow = row;
	
	SecondViewController *vc = (SecondViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"SecondViewController"];
	NSMutableDictionary *mDic = [dataMArray[row] mutableCopy];
	NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
	vc.dataUnwindBackDic = [@{@"indexPath":fromIndexPath,@"data":mDic} mutableCopy];
	
	[self presentViewController:vc animated:true completion:nil];
	
	[theContainerView addSubview:vc.view];
	
	[UIView animateWithDuration:1.0 animations:^{
		self->containerViewHeight.constant = self.view.frame.size.height - 60;
	}];
}
-(void)speak:(NSString *)msg{
	AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:msg];
	utterance.rate = speechSpeed;
// Speech language
	utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
	[synthesizer speakUtterance:utterance];
}

#pragma mark -- 長按複製日本語 --
-(void)handleCopyJP:(UILongPressGestureRecognizer *)gesture{
    if( gesture.state == UIGestureRecognizerStateBegan ){
        // 判斷gesture在哪一個位置被觸發
        CGPoint location = [gesture locationInView:theTableView];
        NSIndexPath *ip = [theTableView indexPathForRowAtPoint:location];
        NSInteger row = ip.row;
        // Copy to clipboard
        if( [dataMArray[row] objectForKey:@"translatedText"] ){
            UIPasteboard *board = [UIPasteboard generalPasteboard];
            board.string = dataMArray[row][@"translatedText"];
           
            UIAlertController *ac =  [MyClass showAlertControllerWithMessage:@"The Japanese sentence was copied."];
            [self presentViewController:ac animated:true completion:nil];
        }
        else{
            // translatedText なし
            NSLog(@"沒有翻譯後的文字...");
        }
       
    }
}



@end
