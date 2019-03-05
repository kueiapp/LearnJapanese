//
//  InterfaceController.h
//  SiriDiaryWatch Extension
//
//  Created by Kuei on 2/14/19.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController

@property (weak) IBOutlet WKInterfaceTable *theTable;
@property (weak) IBOutlet WKInterfaceLabel *alertLabel;
@property (weak) IBOutlet WKInterfaceGroup *labelGroup;

@end
