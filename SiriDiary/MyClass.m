//
//  MyClass.m
//  SiriDiary
//
//  Created by Kuei on 2019/1/8.
//  Copyright © 2019 Kuei. All rights reserved.
//

#import "MyClass.h"
#define kMainQueue dispatch_get_main_queue()


@interface MyClass(){
    // Private members
}

@end

@implementation MyClass

-(id)init{
    self = [super init];
    return self;
}

+(UIAlertController *)showAlertControllerWithMessage:(NSString *)msg{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"JP Diary" message:msg preferredStyle:UIAlertControllerStyleActionSheet];
    [ac addAction:[UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(kMainQueue, ^{
            [ac dismissViewControllerAnimated:true completion:nil];
        });                
    }]];
    
    return ac;
}

+(void)showIndicatorInView:(UIView *)view{
	UIView *blackV = [UIView new];
	blackV.tag = 8899;
	[blackV setFrame:CGRectMake(0, 0, 100, 100)];
	[blackV setCenter:view.center];
	[blackV setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
	blackV.layer.cornerRadius = 5.0;
   
	UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleWhiteLarge)];
   [indicator setCenter:CGPointMake(50, 50)];
	[indicator startAnimating];
	
	[blackV addSubview:indicator];
	[view addSubview:blackV];
	
}
+(void)removeIndicatorInView:(UIView *)view{
	for( UIView *v in view.subviews ){
		if( v.tag == 8899 ){
			[v removeFromSuperview];
		}
	}
}

#pragma mark -- access local files --
+(void) saveFiles:(NSArray *)_arr  At:(NSString *)_filePath{

   NSFileManager *fm = NSFileManager.defaultManager;
   // Local Document storage
   NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
   if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
   }
   // Local path
   path = [path stringByAppendingPathComponent:_filePath];
   @try{
      NSLog(@"save file to device");
      [_arr writeToFile:path atomically:true];
   }
   @catch(NSException *e){
      NSLog(@"save to file throw: %@", e.description);
   }
   
}

+(NSArray *) loadFilesFrom:(NSString *)_filePath{
   NSArray *returnArray;
   NSFileManager *fm = NSFileManager.defaultManager;
   // Local Document storage
   NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
   if( ![fm fileExistsAtPath:path] ){
      [fm createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
   }
   // Local path
   path = [path stringByAppendingPathComponent:_filePath];
   @try{
      NSArray *arr = [[NSArray alloc] initWithContentsOfFile:path];
      if( arr ){
         returnArray = arr;
      }
      else{
         returnArray = [NSArray new];
      }
   }
   @catch( NSException *e ){
      NSLog(@"load file err: %@", e.description);
   }
   
   return returnArray;
}

+(bool)isIphoneX{
   bool flag = false;
   if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
       switch ((int)[[UIScreen mainScreen] nativeBounds].size.height) {
           case 1136:
               printf("iPhone 5 or 5S or 5C");
                   break;
           case 1334:
               printf("iPhone 6/6S/7/8");
               break;

           case 1920:
               printf("iPhone 6+/6S+/7+/8+");
               break;
           case 2208:
               printf("iPhone 6+/6S+/7+/8+");
               break;
           case 2436:
               printf("iPhone X, XS");
               flag = true;
               break;
           case 2688:
               printf("iPhone XS Max");
               flag = true;
               break;
           case 1792:
               printf("iPhone XR");
               flag = true;
               break;
           default:
               printf("Unknown");
               break;
       }
   }
   return flag;
}


@end
