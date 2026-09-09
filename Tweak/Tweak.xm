#import "Preferences.h"
#import "ADSAppsRootController.h"

%hook SettingsRootController

- (NSArray *)specifiers {
    NSArray *original = %orig;

    // Evita duplicados si -specifiers se llama más de una vez (rotación, etc.)
    for (PSSpecifier *existing in original) {
        if ([existing.identifier isEqualToString:@"ADS_iOS26Apps"]) {
            return original;
        }
    }

    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Apps y Tweaks"
                                                              target:self
                                                                 set:NULL
                                                                 get:NULL
                                                              detail:[%c(ADSAppsRootController) class]
                                                                cell:PS_LINK_LIST_CELL
                                                                edit:Nil];
    specifier.identifier = @"ADS_iOS26Apps";
    [specifier setProperty:@"UIPreferencesGeneralCellClass" forKey:@"cellClass"];

    NSMutableArray *mutableSpecifiers = [original mutableCopy];

    // La insertamos justo después de "General" si existe, si no, al principio.
    NSUInteger insertIndex = 0;
    for (NSUInteger i = 0; i < mutableSpecifiers.count; i++) {
        PSSpecifier *s = mutableSpecifiers[i];
        if ([[s propertyForKey:@"label"] isEqual:@"General"]) {
            insertIndex = i + 1;
            break;
        }
    }
    [mutableSpecifiers insertObject:specifier atIndex:insertIndex];

    return mutableSpecifiers;
}

%end

%ctor {
    @autoreleasepool {
        // Nada que inicializar de forma global: todo ocurre de forma perezosa
        // cuando Settings pide los specifiers de su controlador raíz.
    }
}
