#import <UIKit/UIKit.h>

@interface ADSTweakInfo : NSObject
@property (nonatomic, copy) NSString *name;              // nombre "bonito" (paquete dpkg o filename)
@property (nonatomic, copy) NSString *packageIdentifier;  // ID dpkg, ej. com.autor.tweak
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *tweakDescription;
@property (nonatomic, copy) NSString *dylibPath;          // ruta al .dylib real
@property (nonatomic, copy) NSString *filterPlistPath;    // ruta al .plist de Filter
@property (nonatomic, assign) BOOL isActive;              // el .plist no tiene ".disabled" hermano
@property (nonatomic, copy) NSString *preferenceBundlePath; // nil si no tiene panel de ajustes
@property (nonatomic, strong) UIImage *icon;              // opcional, si el tweak trae uno propio
@end
