//
//  HintViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/16.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "HintViewController.h"

@interface HintViewController ()

@end

@implementation HintViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	donBtn.layer.cornerRadius = 5.0;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)doneBtnClicked:(id)sender{
	[self dismissViewControllerAnimated:true completion:nil];	
	// save setting
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:true forKey:@"WasHint"];
	[ud synchronize];
}

@end
