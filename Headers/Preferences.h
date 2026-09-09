// Declaraciones mínimas necesarias para hablar con Preferences.framework.
// No son headers oficiales de Apple: son las firmas públicas que usa
// prácticamente todo tweak de jailbreak que añade filas a Ajustes.
// Si Theos no las encuentra en tu SDK, puedes bajarlas de cualquier
// "headers" repo de jailbreak (ej. rpetrich/PreferenceLoader, iphonedevwiki).

#import <UIKit/UIKit.h>

@interface PSSpecifier : NSObject
+ (instancetype)preferenceSpecifierNamed:(NSString *)name
                                   target:(id)target
                                      set:(SEL)set
                                      get:(SEL)get
                                   detail:(Class)detail
                                     cell:(NSInteger)cell
                                     edit:(Class)edit;
@property (nonatomic, copy) NSString *identifier;
- (void)setProperty:(id)value forKey:(NSString *)key;
- (id)propertyForKey:(NSString *)key;
@end

// Valor de PSLinkListCell tal y como lo define Preferences.framework
#define PS_LINK_LIST_CELL 5

@interface PSListController : UITableViewController
@property (nonatomic, retain) NSMutableArray *_specifiers;
- (NSArray *)specifiers;
- (void)setSpecifiers:(NSArray *)specifiers;
- (void)reloadSpecifiers;
@property (nonatomic, retain) id rootController;
@end

@interface PSViewController : UIViewController
@property (nonatomic, retain) PSSpecifier *specifier;
- (id)navigationTitle;
@end

// Controlador raíz de Ajustes (com.apple.Preferences)
@interface SettingsRootController : PSListController
@end
