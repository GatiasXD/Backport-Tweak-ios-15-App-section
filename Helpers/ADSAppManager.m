#import "ADSAppManager.h"
#import "LSApplicationWorkspace.h"
#import "SpringBoardServices.h"

@implementation ADSAppManager

+ (NSArray<ADSAppInfo *> *)installedUserApps {
    NSMutableArray<ADSAppInfo *> *result = [NSMutableArray array];

    LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
    NSArray<LSApplicationProxy *> *proxies = nil;

    // allInstalledApplications no existe en todas las versiones; se hace
    // fallback a allApplications si el selector no responde.
    if ([workspace respondsToSelector:@selector(allInstalledApplications)]) {
        proxies = [workspace allInstalledApplications];
    } else {
        proxies = [workspace allApplications];
    }

    for (LSApplicationProxy *proxy in proxies) {
        if (!proxy.bundleIdentifier) continue;

        // Filtramos apps completamente ocultas de sistema (springboard internals),
        // pero dejamos pasar apps de sistema "normales" (Mail, Safari, etc.)
        if (proxy.isHidden) continue;

        ADSAppInfo *info = [ADSAppInfo new];
        info.bundleIdentifier = proxy.bundleIdentifier;
        info.displayName = proxy.localizedName ?: proxy.bundleIdentifier;
        info.version = proxy.bundleVersion ?: @"-";
        info.isSystemApp = [proxy respondsToSelector:@selector(isSystemApplication)] ? [proxy isSystemApplication] : NO;
        // El icono se resuelve de forma perezosa (lazy) al mostrarse en pantalla,
        // ya que SBSCopyIconImagePNGDataForDisplayIdentifier no es gratis.
        [result addObject:info];
    }

    // Orden alfabético, como en iOS 26
    [result sortUsingComparator:^NSComparisonResult(ADSAppInfo *a, ADSAppInfo *b) {
        return [a.displayName caseInsensitiveCompare:b.displayName];
    }];

    return result;
}

+ (UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier {
    if (!bundleIdentifier) return nil;

    CFDataRef pngData = SBSCopyIconImagePNGDataForDisplayIdentifier((__bridge CFStringRef)bundleIdentifier, 0);
    if (!pngData) return nil;

    NSData *data = (__bridge_transfer NSData *)pngData;
    UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
    return image;
}

@end
