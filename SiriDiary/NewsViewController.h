//
//  NewsViewController.h
//  SiriDiary
//
//  Created by Kuei on 2/15/19.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface NewsViewController : UIViewController<GADAdSizeDelegate,GADBannerViewDelegate>
{
   __weak IBOutlet GADBannerView *adsBannerView;
}
@end

NS_ASSUME_NONNULL_END
