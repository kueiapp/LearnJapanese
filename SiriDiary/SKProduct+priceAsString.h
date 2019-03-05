//
//  SKProduct+priceAsString.h
//  itravel_prototype
//
//  Created by Kuei on 4/6/15.
//  Copyright (c) 2015 Kuei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SKProduct (priceAsString)
@property (nonatomic, readonly) NSString *priceAsString;
@end
