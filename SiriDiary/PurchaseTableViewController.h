//
//  PurchaseTableViewController.h
//  SiriDiary
//
//  Created by Kuei on 2019/1/8.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "SSKeychain.h"
#import "SKProduct+priceAsString.h"

NS_ASSUME_NONNULL_BEGIN

@interface PurchaseTableViewController : UITableViewController<SKProductsRequestDelegate, SKPaymentTransactionObserver, UITableViewDataSource, UITableViewDelegate, SKRequestDelegate, UITextFieldDelegate, SKRequestDelegate>
{
	BOOL areAdsRemoved;
	id adsFreeUsers;
	
	NSMutableArray *productsMArray;
	SKReceiptRefreshRequest *receiptRequest;
	SSKeychain *keychain;
	
	NSInteger selectedIndex;
	NSString *selectedProductId;
	
	UITextField *adsFreeUserTextField;
	UIView *comfirmView;
	NSMutableArray *purchasedItemIDs;
	NSString *adsFreeCode;
	
	enum USERACTION{
		REQUEST_PURCHASE,
		TAP_RESTORE,
		TAP_BUY
	};
	enum USERACTION userAction;
	
	UIView *indicatorView;
	__weak IBOutlet UIBarButtonItem *restoreBtn;
	
}

@end

NS_ASSUME_NONNULL_END
