#import <Foundation/Foundation.h>
#import "ADSAppInfo.h"

@interface ADSAppManager : NSObject
+ (NSArray<ADSAppInfo *> *)installedUserApps; // apps "normales" (no ocultas/sistema puro)
+ (UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier;
@end
