//
//  IntentHandler.m
//  SiriDiaryIntent
//
//  Created by Kuei on 2019/1/12.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "IntentHandler.h"

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

@interface IntentHandler () <INSendMessageIntentHandling, INSearchForMessagesIntentHandling, INSetMessageAttributeIntentHandling>

@end

@implementation IntentHandler

- (id)handlerForIntent:(INIntent *)intent {
    // This is the default implementation.  If you want different objects to handle different intents,
    // you can override this and return the handler you want for that particular intent.
	NSLog(@"handle intent: %@",intent);
	if ([intent isKindOfClass:[INRequestRideIntent class]]) {
		NSLog(@"INRequestRideIntent");
	}
	else if ([intent isKindOfClass:[INGetRideStatusIntent class]]) {
		NSLog(@"INGetRideStatusIntent");
	}
	
    return self;
}

#pragma mark - INSendMessageIntentHandling

- (void)resolveContentForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(INStringResolutionResult *resolutionResult))completion {
    NSString *text = intent.content;
	// 解析User在Siri念的文字
	NSLog(@"resolveContentForSendMessage: %@", text);
    if (text && ![text isEqualToString:@""]) {
		// 成功
        completion([INStringResolutionResult successWithResolvedString:text]);
    } 
	else {
		// 失敗
        completion([INStringResolutionResult needsValue]);
    }
}

- (void)confirmSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse *response))completion {
    // Verify user is authenticated and your app is ready to send a message.
    NSLog(@"confirm send intent: %@",intent.content);
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSendMessageIntent class])];
    INSendMessageIntentResponse *response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeReady userActivity:userActivity];
    completion(response);
}

- (void)handleSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse *response))completion {
    // Implement your application logic to send a message here.
    NSLog(@"handle send intent: %@",intent.content);
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSStringFromClass([INSendMessageIntent class])];
    INSendMessageIntentResponse *response = [[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeSuccess userActivity:userActivity];
    completion(response);
}

@end
