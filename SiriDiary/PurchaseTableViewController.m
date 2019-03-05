//
//  PurchaseTableViewController.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/8.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "PurchaseTableViewController.h"
#import "SSKeychain.h"
#import "MyClass.h"

#define kMainQueue dispatch_get_main_queue()
#define kRemoveAdsProductIdentifier @"com.kueiapp.YOUR-ID"
#define kCloudStorageProductIdentifier @"com.kueiapp.YOUR-ID"
#define kLanguageKoreanProductIdentifier @"com.kueiapp.YOUR-ID"


@interface PurchaseTableViewController ()

@end

@implementation PurchaseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

   [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
   [MyClass showIndicatorInView:self.tableView];
	
	// Init array
	productsMArray = [NSMutableArray new];
	purchasedItemIDs = [[NSMutableArray alloc] init];
	
	
	[self requestPurchase];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
		// Dispose of any resources that can be recreated.
		// It will go to method updatedTransactions
}
-(void)dealloc
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
#pragma mark SKProduct function -------
- (void)requestPurchase
{
	
		// Request
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	
	NSLog(@"User requests products");
	userAction = REQUEST_PURCHASE;
	[productsMArray removeAllObjects];
	
	if([SKPaymentQueue canMakePayments])
	{
		SKProductsRequest *productsRequest =
		[[SKProductsRequest alloc] initWithProductIdentifiers:
		 [NSSet setWithArray:@[kRemoveAdsProductIdentifier, kCloudStorageProductIdentifier, kLanguageKoreanProductIdentifier]]]; // 5/21
		productsRequest.delegate = self;
		[productsRequest start];
		
	}
	else
	{
		[MyClass showAlertControllerWithMessage:NSLocalizedString(@"User cannot make payments due to parental controls",nil)];
			//this is called the user cannot make payments, most likely due to parental controls
	}
	
	
}

	// Mark remove ads when purchasing is finished
-(void) doRemove
{
	NSLog(@"do remove item %d", (int)selectedIndex);
	SKPaymentQueue *queue = [SKPaymentQueue defaultQueue];
	
		//	SKPaymentTransaction *transaction = queue.transactions[selectedIndex];
		//	SKPaymentTransaction *transaction2 = queue.transactions[0];
	
	for(SKPaymentTransaction *transaction in queue.transactions)
	{
		
		NSString *productID = transaction.payment.productIdentifier;
		NSLog(@"product: %@", productID);
		if ([productID isEqualToString:selectedProductId])
		{
			if ([productID isEqualToString:kRemoveAdsProductIdentifier])
			{
				[SSKeychain setPassword:@"1"
							 forService:@"isPurchased"
								account:kRemoveAdsProductIdentifier];
			}
			else if( [productID isEqualToString:kCloudStorageProductIdentifier])
			{
				
				[SSKeychain setPassword:@"1"
							 forService:@"isPurchased"
								account:kCloudStorageProductIdentifier];
			}
			else if( [productID isEqualToString:kLanguageKoreanProductIdentifier])
			{
				
				[SSKeychain setPassword:@"1"
							 forService:@"isPurchased"
								account:kLanguageKoreanProductIdentifier];
			}
			
		}
		
		
	}
	//[MyClass showAlertControllerWithMessage: @"This item is purchased."];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.tableView reloadData];
	});
}

-(void) doRestore
{
	NSLog(@"do restore keychain");
	
	[SSKeychain setPassword:@"0"
				 forService:@"isPurchased"
					account:kRemoveAdsProductIdentifier];
	[SSKeychain setPassword:@"0"
				 forService:@"isPurchased"
					account:kCloudStorageProductIdentifier];
	
	[SSKeychain setPassword:@"0"
				 forService:@"isPurchased"
					account:kLanguageKoreanProductIdentifier];
	
}


- (void)purchase:(SKProduct *)product
{
	NSLog(@"to purchase product: %@", product.localizedDescription);
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

-(IBAction)restoreAllBtnClick
{
	[purchasedItemIDs removeAllObjects];
	
	// Request
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"JP Diary" message:@"Do you want to restore all purchased items if you had?" preferredStyle:(UIAlertControllerStyleAlert)];
	
	//OK
	UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
		NSLog(@"refresh receipt to restore items were bought by the user");
		[UIApplication sharedApplication].networkActivityIndicatorVisible = true;
		[MyClass showIndicatorInView:self.tableView];
		
		self->userAction = TAP_RESTORE;
		[self doRestore];
		[self restorePurchase];
	}];
	//Cancel
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleDestructive) handler:^(UIAlertAction * _Nonnull action) {
		NSLog(@"cancel restore all");
	}];
	
	[alert addAction:okAction];
	[alert addAction:cancelAction];
	
	[self presentViewController:alert animated:true completion:nil];;
	
}

- (void)restorePurchase
{
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}


#pragma mark StoreKit get product info delegate ------------------------------------
// Get receipt
- (void)productsRequest:(SKProductsRequest *)request
	 didReceiveResponse:(SKProductsResponse *)response
{
// Check if existing invalid products
	for (NSString *invalidProducts in response.invalidProductIdentifiers){
		NSLog(@"invalid products: %@", invalidProducts);
   }
	
// Prepare products array
	for (int i=0; i<response.products.count; i++){
		[productsMArray addObject:[NSNull null]];
   }
	
// Load product information
	for (SKProduct *product in response.products){
		NSLog(@"product: %@", product.productIdentifier);
		NSLog(@"isDownloadable: %d", product.isDownloadable);
		NSLog(@"downloadable: %d", product.downloadable);
		NSLog(@"localizedTitle: %@", product.localizedTitle);
		NSLog(@"localizedDescription: %@", product.localizedDescription);
		NSLog(@"price: %@", product.price);
		NSLog(@"isAccessibilityElement: %d", product.isAccessibilityElement);
		NSString *product_price = product.priceAsString;
		
		if ([product.productIdentifier isEqualToString:kRemoveAdsProductIdentifier])
		{
			[productsMArray replaceObjectAtIndex:0 withObject:@{@"name":product, @"price": product_price}];
		}
		else if ([product.productIdentifier isEqualToString:kCloudStorageProductIdentifier])
		{
			[productsMArray replaceObjectAtIndex:1 withObject:@{@"name":product, @"price": product_price}];
		}
		else if ([product.productIdentifier isEqualToString:kLanguageKoreanProductIdentifier])
		{
			[productsMArray replaceObjectAtIndex:2 withObject:@{@"name":product, @"price": product_price}];
		}
	}
	
	[self.tableView reloadData];
}

-(void)requestDidFinish:(SKRequest *)request
{
	if (userAction == TAP_RESTORE)
	{
		NSLog(@"request finish: %@", request.description);
	}
}

-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
	if (error != nil)
	{
		[MyClass showAlertControllerWithMessage:error.description];
	}
	[MyClass removeIndicatorInView:self.tableView];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
}

// Processing transaction
- (void)paymentQueue:(SKPaymentQueue *)queue
 updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction *transaction in transactions){
   
      dispatch_async(kMainQueue, ^{
         [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
         [MyClass showIndicatorInView:self.tableView];
      
      });
		
		switch( (int)transaction.transactionState )
      {
         case SKPaymentTransactionStatePurchasing:
         NSLog(@"Transaction state -> Purchasing");
            //[self.tableView reloadData];
         break;
         case SKPaymentTransactionStatePurchased:
         
         NSLog(@"Transaction state -> Purchased");
         [self completeTransaction:transaction];
         
         break;
         case SKPaymentTransactionStateRestored:
         NSLog(@"Transaction state -> Restored");
         [self restoreTransaction:transaction];
         
         break;
         case SKPaymentTransactionStateFailed:
         [self failedTransaction:transaction];
         
         break;
      }
   }
	
}

-(void)completeTransaction:(SKPaymentTransaction*)trans
{
	NSString * productIdentifier = trans.payment.productIdentifier;
	NSLog(@"completeTransaction id: %@", productIdentifier);
	
	[self doRemove];
	[[SKPaymentQueue defaultQueue] finishTransaction:trans];
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
}
-(void)restoreTransaction:(SKPaymentTransaction*)trans
{
		//[self restorePurchase];
	NSLog(@"restoreTransaction: %@", trans.payment.productIdentifier);
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
}
-(void)failedTransaction:(SKPaymentTransaction*)trans
{
	if(trans.error.code != SKErrorPaymentCancelled)
	{
		[MyClass showAlertControllerWithMessage:NSLocalizedString(@"Transaction failed.",nil)];
	}
	else
	{
		[MyClass showAlertControllerWithMessage:NSLocalizedString(@"You cancelled the purchase.",nil)];
	}
	
	[[SKPaymentQueue defaultQueue] finishTransaction:trans];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
#pragma mark restore delegate----------
	// Restore completed
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
	for (SKPaymentTransaction *transaction in queue.transactions)
   {
		NSString *productID = transaction.payment.productIdentifier;
		NSLog(@"restoring product id: %@", productID);
		
		if(transaction.transactionState == SKPaymentTransactionStateRestored ||
		   transaction.transactionState == SKPaymentTransactionStateDeferred)
			{
			NSLog(@"successfully restores a purchase");
            [purchasedItemIDs addObject:productID];
			}
		}
	
	[self.tableView reloadData];
	
// Remind users
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[MyClass showAlertControllerWithMessage:NSLocalizedString(@"Purchased items are restored.",nil)];
}

-(void)paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
	[MyClass showAlertControllerWithMessage:NSLocalizedString(@"Transaction failed.",nil)];
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//#warning Incomplete implementation, return the number of sections
    return 1;
}
-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	return NSLocalizedString(@"Thanks for supporting us", nil);
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//#warning Incomplete implementation, return the number of rows
    return productsMArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IAPCell" forIndexPath:indexPath];
	
    // Configure the cell...
	if (productsMArray[indexPath.row] != nil ){
		NSString *itemTitle = [productsMArray[indexPath.row][@"name"] localizedTitle],
			*itemDescription = [productsMArray[indexPath.row][@"name"] localizedDescription],
			*itemPrice = productsMArray[indexPath.row][@"price"];
		
		cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",itemTitle,itemPrice];
		cell.detailTextLabel.text = itemDescription;
	}
    
	// Restore button
	NSString *isPurchased = @"0";
	switch (indexPath.row) {
		case 0:{
			isPurchased = [SSKeychain passwordForService:@"isPurchased"
												 account:kRemoveAdsProductIdentifier];
			
			NSLog(@"remove ads isPurchased in cell: %@", isPurchased);
			break;
		}
		case 1:{
			isPurchased = [SSKeychain passwordForService:@"isPurchased"
												 account:kCloudStorageProductIdentifier];
			
			NSLog(@"cloud storage isPurchased in cell: %@", isPurchased);
			break;
		}
		case 2:{
			isPurchased = [SSKeychain passwordForService:@"isPurchased"
												 account:kLanguageKoreanProductIdentifier];
			
			NSLog(@"Korean isPurchased in cell: %@", isPurchased);
			break;
		}
	}
	if ([isPurchased boolValue]){
		// bought
		UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
		UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		buyBtn.frame = CGRectMake(0, 0, 44, 44);
		[buyBtn setImage:[UIImage imageNamed:@"ic_done_black_24dp"] forState:UIControlStateNormal];
		buyBtn.titleLabel.font = [UIFont systemFontOfSize:11];
		[buyBtn addTarget:self
				   action:@selector(buyProduct:)
		 forControlEvents:UIControlEventTouchUpInside];
		buyBtn.tag = indexPath.row;
		[container addSubview:buyBtn];
		
		cell.accessoryView = container;
	}
	else{
		// not bought
		// check is purchased on App Store
		switch (indexPath.row) {
			case 0:{
				if ((int)[purchasedItemIDs indexOfObject: kRemoveAdsProductIdentifier] != -1)
				{
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setImage:[UIImage imageNamed:@"ic_cloud_download_black_24dp"] forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				else
				{					
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setTitle:@"Buy" forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				break;
			}
			case 1:{
				if ((int)[purchasedItemIDs indexOfObject: kCloudStorageProductIdentifier] != -1)
				{
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setImage:[UIImage imageNamed:@"ic_cloud_download_black_24dp"] forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				else
				{
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setTitle:@"Buy" forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				break;
			}
			case 2:{
				if ((int)[purchasedItemIDs indexOfObject: kLanguageKoreanProductIdentifier] != -1)
				{
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setImage:[UIImage imageNamed:@"ic_cloud_download_black_24dp"] forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				else
				{
					UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
					UIButton *buyBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
					buyBtn.frame = CGRectMake(0, 0, 44, 44);
					[buyBtn setTitle:@"Buy" forState:UIControlStateNormal];
					[buyBtn addTarget:self
							   action:@selector(buyProduct:)
					 forControlEvents:UIControlEventTouchUpInside];
					buyBtn.tag = indexPath.row;
					[container addSubview:buyBtn];
					cell.accessoryView = container;
				}
				break;
			}
		}//switch
	}//ifelse
	
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = false;
	[MyClass removeIndicatorInView:self.tableView];
   
   return cell;
}

#pragma mark functions -----------
-(void)buyProduct:(UIButton*)btn
{
	userAction = TAP_BUY;
	
	// Request
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	
	int index = (int)btn.tag;
	selectedIndex = index;
	
	switch (index)
	{
		case 0:
		{
			selectedProductId = kRemoveAdsProductIdentifier;
			NSString *isPurchased = [SSKeychain passwordForService:@"isPurchased"
														   account:kRemoveAdsProductIdentifier];
			if (![isPurchased boolValue])
			{
				[self purchase:productsMArray[index][@"name"]];
			}
			else
			{
				[MyClass showAlertControllerWithMessage:NSLocalizedString(@"This item was bought",nil)];
			}
			break;
		}
		case 1:
		{
			selectedProductId = kCloudStorageProductIdentifier;
			NSString *isPurchased = [SSKeychain passwordForService:@"isPurchased"
														   account:kCloudStorageProductIdentifier];
			if (![isPurchased boolValue])
			{
				[self purchase:productsMArray[index][@"name"]];
			}
			else
			{
				[MyClass showAlertControllerWithMessage:NSLocalizedString(@"This item was bought",nil)];
			}
			break;
		}
		case 2:
		{
			selectedProductId = kLanguageKoreanProductIdentifier;
			NSString *isPurchased = [SSKeychain passwordForService:@"isPurchased"
														   account:kLanguageKoreanProductIdentifier];
			if (![isPurchased boolValue])
			{
				[self purchase:productsMArray[index][@"name"]];
			}
			else
			{
				[MyClass showAlertControllerWithMessage:NSLocalizedString(@"This item was bought",nil)];
			}
			break;
		}
	}
	
}
-(IBAction)doneBtnClicked:(id)sender{
    [self dismissViewControllerAnimated:true completion:nil];
}

@end
