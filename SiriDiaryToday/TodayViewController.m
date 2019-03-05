//
//  TodayViewController.m
//  SiriDiaryToday
//
//  Created by Kuei on 2019/1/8.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>
{
    __weak IBOutlet UILabel *theLabel;
    __weak IBOutlet UIButton *addBtn;
}
@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    if( board.string ){
       theLabel.text = board.string;
       addBtn.layer.borderColor = [UIColor blackColor].CGColor;
       addBtn.layer.borderWidth = 1.0;
       addBtn.layer.cornerRadius = 5.0;
    }
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

-(IBAction)addBtnClicked:(id)sender{
    NSLog(@"Got %@", theLabel.text);
    if( theLabel.text != nil ){
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"YOUR-ID://translate?sourceText=%@",[theLabel.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet] ] ]];
       
        [self.extensionContext openURL:url completionHandler:^(BOOL success) {
            if( !success ){
                NSLog(@"cannot open main app");
            }
        }];
    }

}


@end
