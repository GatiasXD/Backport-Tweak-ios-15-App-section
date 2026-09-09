#import <UIKit/UIKit.h>

@interface ADSAppInfo : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, strong) UIImage *icon; // puede ser nil, se resuelve on-demand
@property (nonatomic, assign) BOOL isSystemApp;
@end
