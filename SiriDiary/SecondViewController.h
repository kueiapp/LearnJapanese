//
//  SecondViewController.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/14.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SecondViewController : UIViewController <UITextViewDelegate,UIScrollViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
	__weak IBOutlet UILabel *sourceLabel, *sourceTitleLabel, *translatedLabel, *imgLabel;
	__weak IBOutlet UITextView *translatedTextView;
	__weak IBOutlet UIImageView *imgView;
	__weak IBOutlet UIScrollView *theScrollView;
	__weak IBOutlet UIView *containerView;
}


//@property NSMutableDictionary *mDicFromOne;
//@property NSIndexPath *fromIndexPath;
@property NSDictionary *dataUnwindBackDic;

@end

NS_ASSUME_NONNULL_END
