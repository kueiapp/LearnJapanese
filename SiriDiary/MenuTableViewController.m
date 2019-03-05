//
//  MenuTableViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/7.
//  Copyright © 2019 Kuei. All rights reserved.
//
@import SafariServices;
#import "MenuTableViewController.h"
#import "SSKeychain.h"
#import "PurchaseTableViewController.h"
#import "ViewController.h"
#import "AppDelegate.h"
@import Intents;
#import "MyClass.h"

#define kMainQueue dispatch_get_main_queue()
#define kCloudStorageProductIdentifier @"com.kueiapp.YOUR-ID"
#define kLanguageKoreanProductIdentifier @"com.kueiapp.YOUR-ID"
#define kSiriShortcutId @"com.kueiapp.YOUR-ID"

@interface MenuTableViewController () 
{
    NSMutableDictionary *sourceLang;
    CGFloat speechSpeed;
    __weak IBOutlet UILabel *versionLabel;
    __weak IBOutlet UILabel *langLabel;
    __weak IBOutlet UILabel *speedLabel;
	__weak IBOutlet UILabel *activateSiriLabel;
    NSString *cloudStoragePurchased, *koreanPurchased;
}
@end

@implementation MenuTableViewController


/** 當shortcut被呼叫時執行 */
-(void)setupSiriShourtcut{
	if (@available(iOS 12.0, *)) {
		// 顯示在 iOS Setting Siri Shortcut 頁面
		NSUserActivity *ua = [[NSUserActivity alloc] initWithActivityType:kSiriShortcutId];
		ua.title = NSLocalizedString(@"Listen to Japanese diaries", nil);
		ua.userInfo = @{@"speech":@"talk"};
		[ua setEligibleForSearch: true];
		[ua setEligibleForPrediction: true];
		
		[ua setPersistentIdentifier:kSiriShortcutId];
		
		[self.view setUserActivity:ua];
		[ua becomeCurrent];
		
	}
	else {
		// Fallback on earlier versions
		[MyClass showAlertControllerWithMessage:@"Your iOS is not supported to Siri Shortcut, please upgrade it."];
	}
}

-(void)activateSiriClicked:(id)sender{
	
	// Siri shortcut and Intent extension
	if (@available(iOS 10.0, *)) {
		if( INPreferences.siriAuthorizationStatus != INSiriAuthorizationStatusAuthorized){
			[INPreferences requestSiriAuthorization:^(INSiriAuthorizationStatus status) {
				// init intent for Siri
				self->activateSiriLabel.text =  @"Authorized";
				[self setupSiriShourtcut];
				
			} ];
		}
		else{
			activateSiriLabel.text =  @"Authorized";	
		}
	} else {
		// Fallback on earlier versions
		[MyClass showAlertControllerWithMessage:@"Your iOS is not supported Siri, please upgrade it."];
	}
	
}
-(void) saveSettingWithLang:(NSDictionary *)sourceLang andSpeed:(float)speechSpeed{
   
  AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
  [app saveSettingWithData:@{@"sourceLang":sourceLang,@"speechSpeed":@(speechSpeed)}];
  
}
-(void) loadSettingValues{

  AppDelegate *app = (AppDelegate *)UIApplication.sharedApplication.delegate;
  NSMutableDictionary *dicM = [app getSetting];
  
  if(dicM){
     sourceLang = [NSMutableDictionary dictionaryWithDictionary:[dicM objectForKey:@"sourceLang"]];
     speechSpeed = [[dicM objectForKey:@"speechSpeed"] floatValue];
  }
  else{
      speechSpeed = 0.4;
      sourceLang = [NSMutableDictionary dictionaryWithDictionary:@{
          @"code": @"zh",
          @"name": @"Chinese"
       }];
     [app saveSettingWithData:@{@"sourceLang":sourceLang,@"speechSpeed":@(speechSpeed)}];
  }
  
  langLabel.text = sourceLang[@"name"];
  speedLabel.text = [NSString stringWithFormat:@"%.1f", speechSpeed];
  [self.tableView reloadData];
  
}

#pragma mark -- life cycle --
- (void)viewDidLoad {
   
    [super viewDidLoad];
	
    // Init
    versionLabel.text = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
   
   
   // Load from iCloud
   [self loadSettingValues];
   
}
-(void)viewWillAppear:(BOOL)animated{
   
	[super viewWillAppear:true];

	// IAP
	cloudStoragePurchased = [SSKeychain passwordForService:@"isPurchased"
												   account:kCloudStorageProductIdentifier];
	koreanPurchased = [SSKeychain passwordForService:@"isPurchased"
											 account:kLanguageKoreanProductIdentifier];
	
	
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:true];
}
#pragma mark - Table view data source
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *str = nil;
    
    switch (section) {
        case 0:{
            str = @"Setting";
            break;
        }
        case 1:{
            str = @"About";
            break;
        }
        case 2:{
            str = @"Purchase";
            break;
        }
    }
   
    [str sizeWithAttributes:@{
      NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:22],
      NSFontAttributeName: [UIColor redColor]
    }];
    
    return str;
    
}
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


#pragma mark -- UITableView delegate --
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if( indexPath.section == 0){
        // Setting
        switch (indexPath.row) {
            case 0:{
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:cell.textLabel.text message:@"Please choose one you want." preferredStyle:UIAlertControllerStyleActionSheet];
               
                [ac addAction:[UIAlertAction actionWithTitle:@"Chinese" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    self->sourceLang[@"code"] = @"zh";
                    self->sourceLang[@"name"] = @"Chinese";
                    dispatch_async(kMainQueue, ^{
                        self->langLabel.text = self->sourceLang[@"name"];
                        [self saveSettingWithLang:self->sourceLang andSpeed:self->speechSpeed];
                    });
                }]];
               
                [ac addAction:[UIAlertAction actionWithTitle:@"English" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                    self->sourceLang[@"code"] = @"en";
                    self->sourceLang[@"name"] = @"English";                
                    dispatch_async(kMainQueue, ^{
                        self->langLabel.text = self->sourceLang[@"name"];
                    });
                    [self saveSettingWithLang:self->sourceLang andSpeed:self->speechSpeed];
                }]];
               
               
               /* Korean */
               if( koreanPurchased.boolValue ){
                [ac addAction:[UIAlertAction actionWithTitle:@"Korean" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                   self->sourceLang[@"code"] = @"ko";
                   self->sourceLang[@"name"] = @"Korean";
                   dispatch_async(kMainQueue, ^{
                      self->langLabel.text = self->sourceLang[@"name"];
                   });
                  [self saveSettingWithLang:self->sourceLang andSpeed:self->speechSpeed];
                }]];
               }
               
               
            // Cancel button
                [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleDestructive) handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(kMainQueue, ^{
                        [ac dismissViewControllerAnimated:true completion:nil];
                    });
                }]];
                [self presentViewController:ac animated:true completion:nil];
                break;
            }
            case 1:{
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:cell.textLabel.text message:@"Please choose one you want." preferredStyle:UIAlertControllerStyleActionSheet];
               
                  [ac addAction:[UIAlertAction actionWithTitle:@"0.4" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                       self->speechSpeed = 0.4;
                       dispatch_async(kMainQueue, ^{
                           self->speedLabel.text = [NSString stringWithFormat:@"%.1f",self->speechSpeed];
                       });
                     [self saveSettingWithLang:self->sourceLang andSpeed:self->speechSpeed];
                   }]];
               
                   [ac addAction:[UIAlertAction actionWithTitle:@"0.6" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                       self->speechSpeed = 0.6;
                       dispatch_async(kMainQueue, ^{
                           self->speedLabel.text = [NSString stringWithFormat:@"%.1f",self->speechSpeed];
                       });
                     [self saveSettingWithLang:self->sourceLang andSpeed:self->speechSpeed];
                   }]];
               
                   [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleDestructive) handler:^(UIAlertAction * _Nonnull action) {
                       dispatch_async(kMainQueue, ^{
                           [ac dismissViewControllerAnimated:true completion:nil];
                       });
                   }]];
               
                [self presentViewController:ac animated:true completion:nil];
                break;
            }
              
			// to activate Siri
			case 2:{
				[self activateSiriClicked:cell];
				break;
			}
        }//switch
       
        [self.tableView reloadData];
    
    }//if
    else if( indexPath.section == 1 ){
        SFSafariViewController *vc = nil;
        // About
        switch (indexPath.row) {
            case 1:{
                vc = [[SFSafariViewController alloc] initWithURL:
                  [NSURL URLWithString:@"https://jpdiary.kueiapp.com/privacy.html"]];
                break;
            }
            case 2:{
                vc = [[SFSafariViewController alloc] initWithURL:
                  [NSURL URLWithString:@"https://jpdiary.kueiapp.com/frameworks.html"]];
                break;
            }
        }
        
        [self presentViewController:vc animated:true completion:nil];
    }
    else if( indexPath.section == 2 ){
        // Purchase
        PurchaseTableViewController *purchasevc = [self.storyboard instantiateViewControllerWithIdentifier:@"PurchaseTableViewController"];
        [self presentViewController:purchasevc animated:true completion:nil];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (IBAction)showWebPage:(id)sender {
    SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:
                                  [NSURL URLWithString:@"https://kueiapp.com"]];
    [self showViewController:vc sender:self];
}

@end
