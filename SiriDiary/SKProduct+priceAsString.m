//
//  SKProduct+priceAsString.m
//  itravel_prototype
//
//  Created by Kuei on 4/6/15.
//  Copyright (c) 2015 Kuei. All rights reserved.
//

#import "SKProduct+priceAsString.h"

@implementation SKProduct (priceAsString)

- (NSString *) priceAsString
{
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
	[formatter setLocale:[self priceLocale]];
	
	NSString *str = [formatter stringFromNumber:[self price]];

	return str;
}

@end
