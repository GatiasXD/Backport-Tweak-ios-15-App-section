#import "ADSTweakDetailController.h"
#import "Preferences.h"

@interface ADSTweakDetailController ()
@property (nonatomic, strong) ADSTweakInfo *tweakInfo;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *rows;
@end

@implementation ADSTweakDetailController

- (instancetype)initWithTweakInfo:(ADSTweakInfo *)tweakInfo {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _tweakInfo = tweakInfo;
        self.title = tweakInfo.name;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *rows = [NSMutableArray arrayWithArray:@[
        @[@"Nombre", self.tweakInfo.name ?: @"-"],
        @[@"Bundle ID", self.tweakInfo.packageIdentifier ?: @"Desconocido (no gestionado por dpkg)"],
        @[@"Versión", self.tweakInfo.version ?: @"-"],
        @[@"Estado", self.tweakInfo.isActive ? @"Instalado / Activo" : @"Desactivado"],
        @[@"Ruta del dylib", self.tweakInfo.dylibPath ?: @"-"],
    ]];
    if (self.tweakInfo.tweakDescription.length > 0) {
        [rows addObject:@[@"Descripción", self.tweakInfo.tweakDescription]];
    }
    self.rows = rows;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tweakInfo.preferenceBundlePath ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.rows.count : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return @"Este tweak instala su propio panel de preferencias. Puede que algunos tweaks personalicen su clase raíz de forma no estándar; si no se abre, ábrelo desde su entrada normal en Ajustes.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];

    if (indexPath.section == 0) {
        NSArray<NSString *> *pair = self.rows[indexPath.row];
        cell.textLabel.text = pair[0];
        cell.detailTextLabel.text = pair[1];
        cell.detailTextLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else {
        cell.textLabel.text = @"Abrir ajustes del tweak";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = self.view.tintColor;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [self openTweakPreferences];
    }
}

// Convención estándar de Theos: un bundle de preferencias "Foo.bundle" trae
// habitualmente una clase "FooRootListController" como controlador raíz.
// No es garantía universal (cada autor puede nombrarla distinto), pero cubre
// la inmensa mayoría de los bundles generados con el template de Theos.
- (void)openTweakPreferences {
    NSString *bundlePath = self.tweakInfo.preferenceBundlePath;
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if (!bundle || ![bundle load]) {
        [self showCannotOpenAlert];
        return;
    }

    NSString *bundleName = [[bundlePath lastPathComponent] stringByDeletingPathExtension];
    Class rootClass = NSClassFromString([bundleName stringByAppendingString:@"RootListController"]);
    if (!rootClass) rootClass = bundle.principalClass;

    if (!rootClass || ![rootClass isSubclassOfClass:[UIViewController class]]) {
        [self showCannotOpenAlert];
        return;
    }

    UIViewController *controller = [rootClass new];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)showCannotOpenAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No se pudo abrir"
        message:@"No se ha podido determinar automáticamente el controlador de preferencias de este tweak."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
