#import <Foundation/Foundation.h>
#import "ADSTweakInfo.h"

@interface ADSTweakManager : NSObject
+ (NSArray<ADSTweakInfo *> *)installedTweaks;
@end
