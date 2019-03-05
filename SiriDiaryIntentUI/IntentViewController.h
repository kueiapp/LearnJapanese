//
//  IntentViewController.h
//  SiriDiaryIntentUI
//
//  Created by Kuei on 2019/1/12.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <IntentsUI/IntentsUI.h>

@interface IntentViewController : UIViewController <INUIHostedViewControlling,INUIHostedViewSiriProviding>
{
	__weak IBOutlet UILabel *alertLabel;
	__weak IBOutlet UILabel *inputLabel, *outputLabel;
}
@end
