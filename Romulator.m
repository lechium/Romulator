

#import "Romulator.h"
#import <TVSettingsKit/TSKTextInputSettingItem.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <spawn.h>
#include <sys/wait.h>

#include <string.h>
#include <math.h>
#include <sys/stat.h>
#include <sys/param.h>

@interface TVSPreferences : NSObject

+ (id)preferencesWithDomain:(id)arg1;
- (_Bool)setBool:(_Bool)arg1 forKey:(id)arg2;
- (_Bool)boolForKey:(id)arg1 defaultValue:(_Bool)arg2;
- (_Bool)boolForKey:(id)arg1;
- (_Bool)setDouble:(double)arg1 forKey:(id)arg2;
- (double)doubleForKey:(id)arg1 defaultValue:(double)arg2;
- (double)doubleForKey:(id)arg1;
- (_Bool)setFloat:(float)arg1 forKey:(id)arg2;
- (float)floatForKey:(id)arg1 defaultValue:(float)arg2;
- (float)floatForKey:(id)arg1;
- (_Bool)setInteger:(int)arg1 forKey:(id)arg2;
- (int)integerForKey:(id)arg1 defaultValue:(int)arg2;
- (int)integerForKey:(id)arg1;
- (id)stringForKey:(id)arg1;
- (_Bool)setObject:(id)arg1 forKey:(id)arg2;
- (id)objectForKey:(id)arg1;
- (_Bool)synchronize;
- (id)initWithDomain:(id)arg1;
@end

@protocol TSKSettingItemEditingControllerDelegate <NSObject>
- (void)editingController:(id)arg1 didCancelForSettingItem:(TSKSettingItem *)arg2;
- (void)editingController:(id)arg1 didProvideValue:(id)arg2 forSettingItem:(TSKSettingItem *)arg3;
@end

@interface TSKTextInputViewController : UIViewController

@property (assign,nonatomic) BOOL supportsPasswordSharing;
@property (nonatomic,retain) NSString * networkName;
@property (assign,nonatomic) BOOL secureTextEntry;
@property (nonatomic,copy) NSString * headerText;
@property (nonatomic,copy) NSString * messageText;
@property (nonatomic,copy) NSString * initialText;
@property (assign,nonatomic) long long capitalizationType;
@property (assign,nonatomic) long long keyboardType;
@property (nonatomic,retain) TSKSettingItem * editingItem;
@property (assign,nonatomic,weak) id<TSKSettingItemEditingControllerDelegate> editingDelegate;
@end

@implementation Romulator

+ (NSArray *)returnForProcess:(NSString *)call
{
    if (call==nil)
        return 0;
    char line[200];
    NSLog(@"running process: %@", call);
    FILE* fp = popen([call UTF8String], "r");
    NSMutableArray *lines = [[NSMutableArray alloc]init];
    if (fp)
    {
        while (fgets(line, sizeof line, fp))
        {
            NSString *s = [NSString stringWithCString:line encoding:NSUTF8StringEncoding];
            s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [lines addObject:s];
        }
    }
    pclose(fp);
    return lines;
}

- (void)processPath:(NSString *)path  {
    
    //NSString *path = [url path];
    NSString *fileName = path.lastPathComponent;
    NSError *error = nil;
    NSFileManager *man = [NSFileManager defaultManager];
    NSString *provenanceCache = [[Romulator returnForProcess:@"find /var/mobile -path \"*Caches/com.provenance-emu.provenance\" | xargs dirname"] componentsJoinedByString:@""];
    provenanceCache = [provenanceCache stringByAppendingPathComponent:@"Imports"];
    NSLog(@"Romulator: provenance cache: %@", provenanceCache);
    if ([man fileExistsAtPath:provenanceCache]){
        
       // if ([[[fileName pathExtension] lowercaseString] isEqualToString:@"nes"]){
            NSString *importsFile = [provenanceCache stringByAppendingPathComponent:fileName];
            NSLog(@"importing file: %@", importsFile);
        if ([man moveItemAtPath:path toPath:importsFile error:nil]){
            
            NSMutableDictionary *dict = [NSMutableDictionary new];
            dict[@"message"] = [NSString stringWithFormat:@"Imported '%@' successfully!",fileName];
            dict[@"title"] = @"Import Successful";
            dict[@"timeout"] = @2;
            
            NSString *imagePath = [[NSBundle bundleForClass:self.class] pathForResource:@"icon" ofType:@"jpg"];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
            if (imageData){
                dict[@"imageData"] = imageData;
            }
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.nito.bulletinh4x/displayBulletin" object:nil userInfo:dict];
            
        }
                   // }
        
    }
    
}

- (void)showAirDropSharingSheet {
    
    SFAirDropReceiverViewController *rec = [[SFAirDropReceiverViewController alloc] init];
    [self presentViewController:rec animated: YES completion: nil];
    
    UILabel *ourLabel = [rec valueForKey:@"_instructionsLabel"];
    UIFont *ogFont = [ourLabel font];
    [ourLabel setText:@"Drop any Provenance compatible rom files or archives to transfer them into the 'Imports' directory"];
    [ourLabel setFont:ogFont];
    
    [rec startAdvertising];
    
}

- (void)airDropReceived:(NSNotification *)n {
    
    NSDictionary *userInfo = [n userInfo];
    NSArray <NSString *>*items = userInfo[@"Items"];
    NSLog(@"Romulator: airdropped Items: %@", items);
    
    [items enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self processPath:obj];
        
    }];
    
}


- (id)loadSettingGroups {
    
  
    NSLog(@"Romulator: main bundle: %@", [NSBundle bundleForClass:self.class]);
   [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(airDropReceived:) name:@"com.nito.AirDropper/airDropFileReceived" object:nil];
    id facade = [[NSClassFromString(@"TVSettingsPreferenceFacade") alloc] initWithDomain:@"com.nito.romulator" notifyChanges:TRUE];
  
    NSMutableArray *_backingArray = [NSMutableArray new];
   TSKSettingItem *actionItem = [TSKSettingItem actionItemWithTitle:@"Start AirDrop Server" description:@"Turn on AirDrop to receive roms for importing into Provenance" representedObject:facade keyPath:@"" target:self action:@selector(showAirDropSharingSheet)];
    //[textEntryItem setLocalizedValue:@"TEST"];
    TSKSettingGroup *group = [TSKSettingGroup groupWithTitle:nil settingItems:@[actionItem]];
    [_backingArray addObject:group];
    [self setValue:_backingArray forKey:@"_settingGroups"];
    
    return _backingArray;
    
}

- (TVSPreferences *)ourPreferences {
    
    return [TVSPreferences preferencesWithDomain:@"com.nito.romulator"];
}


- (void)editingController:(id)arg1 didCancelForSettingItem:(TSKSettingItem *)arg2 {
    
    NSLog(@"Romulator: editingController %@ didCancelForSettingItem:%@", arg1, arg2);
    [super editingController:arg1 didCancelForSettingItem:arg2];
}
- (void)editingController:(id)arg1 didProvideValue:(id)arg2 forSettingItem:(TSKSettingItem *)arg3 {
    
    NSLog(@"Romulator: editingController %@ didProvideValue: %@ forSettingItem: %@", arg1, arg2, arg3);
 
    [super editingController:arg1 didProvideValue:arg2 forSettingItem:arg3];
 
    TVSPreferences *prefs = [TVSPreferences preferencesWithDomain:@"com.nito.dalesdeadbug"];
    
    NSLog(@"Romulator: prefs: %@", prefs);
    //[arg3 setLocalizedValue:arg2];
    [prefs setObject:arg2 forKey:arg3.keyPath];
    NSLog(@"Romulator: setObjetct: arg2 forKey: %@", arg3.keyPath);
    [prefs synchronize];
    NSLog(@"Romulator: after prefs sync");
    //[self.navigationController popViewControllerAnimated:YES];
    
    
}


-(id)previewForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TSKPreviewViewController *item = [super previewForItemAtIndexPath:indexPath];
    TSKSettingGroup *currentGroup = self.settingGroups[indexPath.section];
    TSKSettingItem *currentItem = currentGroup.settingItems[indexPath.row];
    NSString *imagePath = [[NSBundle bundleForClass:self.class] pathForResource:@"icon" ofType:@"jpg"];
    UIImage *icon = [UIImage imageWithContentsOfFile:imagePath];
    if (icon != nil) {
        TSKVibrantImageView *imageView = [[TSKVibrantImageView alloc] initWithImage:icon];
        [item setContentView:imageView];
    }

    return item;
    
}


@end
