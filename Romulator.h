//#import <Preferences/PSListController.h>
//
//@interface DDBRootListController : PSListController
//
//@end
//#import "prefs.h"
#import <UIKit/UIKit.h>
#import <TVSettingsKit/TSKViewController.h>
#import <TVSettingsKit/TSKSettingGroup.h>
#import <TVSettingsKit/TSKVibrantImageView.h>
#import <TVSettingsKit/TSKPreviewViewController.h>


@interface SFAirDropReceiverViewController: UIViewController
- (void)startAdvertising;
- (void)stopAdvertising;
- (void)setOverriddenInstructionsText:(NSString *)arg1 ;
@end;

@interface ROMAirDropReceiverViewController :SFAirDropReceiverViewController



@end;

@interface NSDistributedNotificationCenter : NSNotificationCenter
+ (id)defaultCenter;
- (void)addObserver:(id)arg1 selector:(SEL)arg2 name:(id)arg3 object:(id)arg4;
- (void)postNotificationName:(id)arg1 object:(id)arg2 userInfo:(id)arg3;
@end

@interface Romulator: TSKViewController

@end
