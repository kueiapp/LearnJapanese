//
//  WebViewController.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/21.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

@interface WebViewController : UIViewController<UIWebViewDelegate>
{
	NSString *urlPath,*musicPath;
	__weak IBOutlet UIWebView *theWebView;
}

@property NSString *urlPath, *musicPath;




@end

NS_ASSUME_NONNULL_END
