//
//  SecondViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/14.
//  Copyright © 2019 Kuei. All rights reserved.
//
#import <sys/utsname.h>
#import "SecondViewController.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "MyClass.h"
@import AVFoundation;

//DeviceList
#define HARDWARE @{@"i386": @"Simulator",@"x86_64": @"Simulator",@"iPod1,1": @"iPod Touch",@"iPod2,1": @"iPod Touch 2nd Generation",@"iPod3,1": @"iPod Touch 3rd Generation",@"iPod4,1": @"iPod Touch 4th Generation",@"iPhone1,1": @"iPhone",@"iPhone1,2": @"iPhone 3G",@"iPhone2,1": @"iPhone 3GS",@"iPhone3,1": @"iPhone 4",@"iPhone4,1": @"iPhone 4S",@"iPhone5,1": @"iPhone 5",@"iPhone5,2": @"iPhone 5",@"iPhone5,3": @"iPhone 5c",@"iPhone5,4": @"iPhone 5c",@"iPhone6,1": @"iPhone 5s",@"iPhone6,2": @"iPhone 5s",@"iPad1,1": @"iPad",@"iPad2,1": @"iPad 2",@"iPad3,1": @"iPad 3rd Generation ",@"iPad3,4": @"iPad 4th Generation ",@"iPad2,5": @"iPad Mini",@"iPad4,4": @"iPad Mini 2nd Generation - Wifi",@"iPad4,5": @"iPad Mini 2nd Generation - Cellular",@"iPad4,1": @"iPad Air 5th Generation - Wifi",@"iPad4,2": @"iPad Air 5th Generation - Cellular",@"iPhone7,1": @"iPhone 6 Plus",@"iPhone7,2": @"iPhone 6",@"iPhone8,1": @"iPhone 6S (GSM+CDMA)",@"iPhone8,2": @"iPhone 6S+ (GSM+CDMA)"}
#define kMainQueue dispatch_get_main_queue()


@interface SecondViewController ()
{
	float speechSpeed;
	NSMutableDictionary *dataDic;
	NSIndexPath *fromIndex;
	UIImageView *pickedImage;
}
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	// Load setting values
	ViewController *vc = (ViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"RootViewController"];
	NSDictionary *settingDic = vc.getSettingValues;
	speechSpeed = [settingDic[@"speed"] floatValue];
	
	[self loadSavedImage];
	[self styleUI];
	
	// Set dictionary data
	dataDic = [NSMutableDictionary dictionaryWithDictionary:self.dataUnwindBackDic[@"data"] ];
	fromIndex = self.dataUnwindBackDic[@"indexPath"];
	
	[sourceLabel setText: dataDic[@"sourceText"]];
	[translatedTextView setText: dataDic[@"translatedText"]];
	
	translatedTextView.delegate = self;
}
-(void)viewDidLayoutSubviews{
	theScrollView.contentSize = CGSizeMake(self.view.bounds.size.width, sourceLabel.bounds.size.height*8 + imgView.frame.size.height);
	[theScrollView setContentOffset: CGPointMake(0, theScrollView.contentOffset.y)];
	theScrollView.directionalLockEnabled = true;
}
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:true];
}
-(void)styleUI{
	// Bottom border
	CALayer *bottomBorder = [CALayer new];
	bottomBorder.frame = CGRectMake(0,sourceTitleLabel.frame.size.height-1, sourceTitleLabel.frame.size.width, 1.0);
	bottomBorder.backgroundColor = [UIColor grayColor].CGColor;
	[sourceTitleLabel.layer addSublayer:(bottomBorder)];
	
	CALayer *bottomBorder2 = [CALayer new];
	bottomBorder2.frame = bottomBorder.frame;
	bottomBorder2.backgroundColor = [UIColor grayColor].CGColor;
	[translatedLabel.layer addSublayer:bottomBorder];
	
	CALayer *bottomBorder3 = [CALayer new];
	bottomBorder3.frame = bottomBorder.frame;
	bottomBorder3.backgroundColor = [UIColor grayColor].CGColor;
	[imgLabel.layer addSublayer:bottomBorder];
	
	[translatedTextView.layer setBorderColor:[UIColor grayColor].CGColor];
	[translatedTextView.layer setBorderWidth:1.0];
	[translatedTextView.layer setCornerRadius:5.0];
}

-(IBAction)speakSentence:(id)sender{
	
	NSDictionary *data = self.dataUnwindBackDic[@"data"];
	
	if(data != nil){
		// Speech API
		AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
		if( ![ data[@"translatedText"] isEqualToString:@""] ){
			AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString: data[@"translatedText"]];
			
         utterance.rate = speechSpeed;
			NSLog(@"speed: %.1f",speechSpeed);
			// Speech language
			utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja"];
			[synthesizer speakUtterance:utterance];
		}
		else{
			NSLog(@"no sentence");
		}
	}
	else{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"No translated sentence is found" preferredStyle:(UIAlertControllerStyleAlert)];
		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
			[alert dismissViewControllerAnimated:true completion:nil];
		}]];
		[self presentViewController:alert animated:true completion:nil];
	}
}

#pragma mark -- Gesture --
-(IBAction)tapToResignTextview:(id)sender{
	[translatedTextView resignFirstResponder];
}
-(IBAction)tapToAddPhoto:(id)sender{
	// show action sheet
	UIAlertController *sheets = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
	// add actions
	UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Use Camera" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
		// 判斷是否有被授權用相機
		if( [UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)]){
			UIImagePickerController *picker = [UIImagePickerController new];
			// Picker抓資料的來源
			picker.sourceType = UIImagePickerControllerSourceTypeCamera;
			picker.delegate = self;
			dispatch_async(kMainQueue, ^{
				[self presentViewController:picker animated:true completion:nil];
			});
			
		}
		else{
			[MyClass showAlertControllerWithMessage:@"We are not allowed to use Camera, please turn it on."];
		}
	}];
	UIAlertAction *photosAction = [UIAlertAction actionWithTitle:@"From Photos" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
		// 判斷是否有被授權用相機
		if( [UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypePhotoLibrary)]){
			UIImagePickerController *picker = [UIImagePickerController new];
			// Picker抓資料的來源
			picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
			picker.delegate = self;
			dispatch_async(kMainQueue, ^{
				[self presentViewController:picker animated:true completion:nil];
			});
			
		}
		else{
			[MyClass showAlertControllerWithMessage:@"We are not allowed to use Camera, please turn it on."];
		}
	}];
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleDestructive) handler:^(UIAlertAction * _Nonnull action) {
		[sheets dismissViewControllerAnimated:true completion:nil];
	}];
	
	[sheets addAction:cameraAction];
	[sheets addAction:photosAction];
	[sheets addAction:cancelAction];
	
	// show alert
	[self presentViewController:sheets animated:true completion:nil];
}
-(void)loadSavedImage{
	if( [self.dataUnwindBackDic[@"data"] valueForKey:@"imagePath"] ){
		NSString *imgPath = self.dataUnwindBackDic[@"data"][@"imagePath"];
		
      imgView.image = [UIImage imageWithContentsOfFile: imgPath];
		imgView.contentMode = UIViewContentModeScaleAspectFit;
	}
}
#pragma mark -- UIImagePickerController delegate --
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
	
	if(picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary || picker.sourceType == UIImagePickerControllerSourceTypeCamera){
		UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
		imgView.image = image;
		imgView.contentMode = UIViewContentModeScaleAspectFit;
		
      NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		
      NSDate *today = [NSDate date];
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
		[formatter setDateFormat:@"yyyy_MM_dd_HH_mm_ss"];

		NSString *imagePath = [documentPath stringByAppendingPathComponent:[formatter stringFromDate:today] ];
		if(![NSFileManager.defaultManager fileExistsAtPath:imagePath]){
			@try{
				[UIImagePNGRepresentation(image) writeToFile:imagePath atomically:true];
				dataDic[@"imagePath"] = imagePath;
				self.dataUnwindBackDic = [@{@"indexPath":fromIndex,@"data":dataDic} mutableCopy];
			}
			@catch(NSException *e){
				NSLog(@"throw: %@",e.description);	
			}
		}
		
		[self dismissViewControllerAnimated:true completion:nil];
	}
}

#pragma mark -- textView delegate --
-(BOOL)textViewShouldEndEditing:(UITextView *)textView{
	dataDic[@"translatedText"] = textView.text;
	self.dataUnwindBackDic = [@{@"indexPath":fromIndex,@"data":dataDic} mutableCopy];
	
	return true;	
}
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
	return true;
}


@end
