#import "ADSTweakManager.h"

// Rutas base de un jailbreak Dopamine / Rootless (procursus).
// Todo vive bajo /var/jb en vez de "/".
static NSString * const kRootlessBase          = @"/var/jb";
static NSString * const kDylibsDir             = @"/var/jb/Library/MobileSubstrate/DynamicLibraries";
static NSString * const kDpkgStatusPath        = @"/var/jb/var/lib/dpkg/status";
static NSString * const kDpkgInfoDir           = @"/var/jb/var/lib/dpkg/info";
static NSString * const kPrefBundlesMarker     = @"Library/PreferenceBundles/";

@implementation ADSTweakManager

#pragma mark - dpkg status parsing

// Parsea /var/jb/var/lib/dpkg/status en un array de diccionarios (un dict por paquete).
+ (NSArray<NSDictionary<NSString *, NSString *> *> *)parseDpkgStatus {
    NSString *content = [NSString stringWithContentsOfFile:kDpkgStatusPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    if (!content) return @[];

    NSMutableArray *packages = [NSMutableArray array];
    NSArray<NSString *> *stanzas = [content componentsSeparatedByString:@"\n\n"];

    for (NSString *stanza in stanzas) {
        if (stanza.length == 0) continue;

        NSMutableDictionary<NSString *, NSString *> *dict = [NSMutableDictionary dictionary];
        NSString *lastKey = nil;
        NSArray<NSString *> *lines = [stanza componentsSeparatedByString:@"\n"];

        for (NSString *rawLine in lines) {
            if (rawLine.length == 0) continue;

            // Líneas continuación (empiezan con espacio) pertenecen a la clave anterior
            if ([rawLine hasPrefix:@" "] && lastKey) {
                NSString *prev = dict[lastKey] ?: @"";
                dict[lastKey] = [prev stringByAppendingFormat:@"\n%@", rawLine];
                continue;
            }

            NSRange colon = [rawLine rangeOfString:@": "];
            if (colon.location == NSNotFound) continue;

            NSString *key = [rawLine substringToIndex:colon.location];
            NSString *value = [rawLine substringFromIndex:colon.location + 2];
            dict[key] = value;
            lastKey = key;
        }

        if (dict[@"Package"]) {
            [packages addObject:dict];
        }
    }

    return packages;
}

// Devuelve YES si el .list del paquete contiene una ruta que termina en `suffix`.
// Compara contra las rutas TAL CUAL las guarda dpkg (relativas a /var/jb, sin el prefijo).
+ (BOOL)packageListAtPath:(NSString *)listPath containsSuffix:(NSString *)suffix
                 fullPath:(NSString * __autoreleasing *)outFullPath {
    NSString *content = [NSString stringWithContentsOfFile:listPath
                                                    encoding:NSUTF8StringEncoding
                                                       error:nil];
    if (!content) return NO;

    NSArray<NSString *> *lines = [content componentsSeparatedByString:@"\n"];
    for (NSString *line in lines) {
        if ([line hasSuffix:suffix] || [line rangeOfString:suffix].location != NSNotFound) {
            if (outFullPath) {
                NSString *cleaned = line;
                if (![cleaned hasPrefix:kRootlessBase]) {
                    cleaned = [kRootlessBase stringByAppendingPathComponent:cleaned];
                }
                *outFullPath = cleaned;
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark - Descubrimiento principal

+ (NSArray<ADSTweakInfo *> *)installedTweaks {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSMutableArray<ADSTweakInfo *> *tweaks = [NSMutableArray array];

    // 1) Fuente de la verdad: los .plist de Filter que MobileSubstrate/libhooker leen.
    NSArray<NSString *> *entries = [fm contentsOfDirectoryAtPath:kDylibsDir error:nil];
    if (!entries) entries = @[];

    // 2) Metadatos "más fiables": paquetes dpkg instalados + sus listas de archivos.
    NSArray<NSDictionary<NSString *, NSString *> *> *packages = [self parseDpkgStatus];

    for (NSString *fileName in entries) {
        if (![fileName.pathExtension isEqualToString:@"plist"]) continue;

        NSString *plistPath = [kDylibsDir stringByAppendingPathComponent:fileName];
        NSString *baseName = [fileName stringByDeletingPathExtension]; // "Tweak" de "Tweak.plist"

        NSString *dylibPath = [kDylibsDir stringByAppendingPathComponent:
                                 [baseName stringByAppendingPathExtension:@"dylib"]];
        BOOL disabled = [fm fileExistsAtPath:[dylibPath stringByAppendingPathExtension:@"disabled"]];

        ADSTweakInfo *info = [ADSTweakInfo new];
        info.name = baseName;                 // fallback: nombre del archivo
        info.version = @"-";
        info.tweakDescription = nil;
        info.dylibPath = dylibPath;
        info.filterPlistPath = plistPath;
        info.isActive = !disabled && [fm fileExistsAtPath:dylibPath];

        // 3) Cruce con dpkg: buscamos qué paquete instaló este .plist concreto.
        NSString *relativeSuffix = [NSString stringWithFormat:@"MobileSubstrate/DynamicLibraries/%@", fileName];

        for (NSDictionary<NSString *, NSString *> *pkg in packages) {
            NSString *pkgId = pkg[@"Package"];
            if (!pkgId) continue;

            NSString *listPath = [kDpkgInfoDir stringByAppendingPathComponent:
                                   [pkgId stringByAppendingPathExtension:@"list"]];
            if (![fm fileExistsAtPath:listPath]) continue;

            if ([self packageListAtPath:listPath containsSuffix:relativeSuffix fullPath:NULL]) {
                info.packageIdentifier = pkgId;
                info.version = pkg[@"Version"] ?: info.version;
                info.name = pkg[@"Name"] ?: pkg[@"Package"] ?: info.name;

                NSString *desc = pkg[@"Description"];
                if (desc) {
                    // La primera línea es el resumen corto; el resto, detalle.
                    NSArray<NSString *> *descLines = [desc componentsSeparatedByString:@"\n"];
                    info.tweakDescription = descLines.firstObject;
                }

                // 4) ¿Este mismo paquete instala también un panel de Preferencias?
                NSString *prefBundlePath = nil;
                if ([self packageListAtPath:listPath containsSuffix:kPrefBundlesMarker fullPath:&prefBundlePath]) {
                    // Nos quedamos solo con la carpeta ".bundle", no con archivos sueltos dentro.
                    NSRange bundleRange = [prefBundlePath rangeOfString:@".bundle"];
                    if (bundleRange.location != NSNotFound) {
                        info.preferenceBundlePath = [prefBundlePath substringToIndex:
                                                      bundleRange.location + bundleRange.length];
                    }
                }
                break;
            }
        }

        [tweaks addObject:info];
    }

    [tweaks sortUsingComparator:^NSComparisonResult(ADSTweakInfo *a, ADSTweakInfo *b) {
        return [a.name caseInsensitiveCompare:b.name];
    }];

    return tweaks;
}

@end
