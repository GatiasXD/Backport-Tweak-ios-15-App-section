// Declaraciones privadas mínimas de MobileCoreServices / LaunchServices,
// ampliamente usadas por tweaks de jailbreak (AppList, springtomize, etc.)
// para enumerar apps instaladas sin depender de SpringBoard.

#import <Foundation/Foundation.h>

@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *bundleVersion;
@property (nonatomic, readonly) NSURL *bundleURL;
@property (nonatomic, readonly) BOOL isHidden;
@property (nonatomic, readonly) BOOL isDeletable;
- (BOOL)isSystemApplication;
@end

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)allApplications;
- (NSArray<LSApplicationProxy *> *)allInstalledApplications;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;
@end
