//
//  ViewController.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/3.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>
@import GoogleMobileAds;

@interface ViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,GADAdSizeDelegate,GADBannerViewDelegate,UIGestureRecognizerDelegate>
{
	// protected members
    __weak IBOutlet UISearchBar *theSearchBar;
    __weak IBOutlet GADBannerView *adsBannerView;
	__weak IBOutlet UIView *theContainerView;
	
    NSMutableArray *dataMArray;
}

// public members
@property (weak) IBOutlet UITableView *theTableView;

// public methods
-(void) setDataDic: (NSMutableDictionary *)newDic atIndex:(NSInteger)index;
-(void) setDataArray:(NSMutableArray *)newArray;
-(void) setSettingDic:(NSDictionary *)dic;
-(void) loadSettingValues;
-(NSDictionary *) getSettingValues;
-(IBAction)talkAllDiaries:(id)sender;
-(void)addDataArray:(NSMutableArray *)newArray;
-(void)openDetailPageAtRow:(NSInteger)row;


@end

