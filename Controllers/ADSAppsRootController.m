#import "ADSAppsRootController.h"
#import "ADSAppManager.h"
#import "ADSTweakManager.h"
#import "ADSAppDetailController.h"
#import "ADSTweakDetailController.h"

typedef NS_ENUM(NSInteger, ADSSection) {
    ADSSectionApps = 0,
    ADSSectionTweaks = 1,
    ADSSectionCount
};

static NSString * const kCellID = @"ADSCell";

@interface ADSAppsRootController ()
@property (nonatomic, strong) NSArray<ADSAppInfo *> *apps;
@property (nonatomic, strong) NSArray<ADSTweakInfo *> *tweaks;
@end

@implementation ADSAppsRootController

- (id)init {
    // -init de PSListController normalmente espera un "plist name"; pasamos nil
    // porque no usamos specifiers desde un archivo, generamos la tabla a mano.
    // El estilo de la tabla se fija en la creación (initWithStyle:), no se puede
    // cambiar después vía self.tableView.style (esa propiedad es de solo lectura).
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        self.title = @"Apps";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Apps";
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellID];

    [self reloadData];

    // Pull to refresh: por si el usuario instala/quita un tweak sin salir del panel
    UIRefreshControl *refresh = [UIRefreshControl new];
    [refresh addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refresh;
}

- (void)reloadData {
    self.apps = [ADSAppManager installedUserApps];
    self.tweaks = [ADSTweakManager installedTweaks];
    [self.tableView reloadData];
    [self.tableView.refreshControl endRefreshing];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ADSSectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == ADSSectionApps ? @"📱 Aplicaciones" : @"🔧 Tweaks";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == ADSSectionTweaks) {
        return [NSString stringWithFormat:@"%lu tweaks detectados en /var/jb/Library/MobileSubstrate/DynamicLibraries", (unsigned long)self.tweaks.count];
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == ADSSectionApps ? self.apps.count : self.tweaks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.layer.cornerRadius = 9; // esquinas redondeadas estilo iOS moderno
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;

    if (indexPath.section == ADSSectionApps) {
        ADSAppInfo *app = self.apps[indexPath.row];
        cell.textLabel.text = app.displayName;
        cell.detailTextLabel.text = app.version;
        cell.imageView.image = app.icon ?: [UIImage systemImageNamed:@"app.fill"];

        if (!app.icon) {
            // Resolución perezosa del icono en background para no bloquear el scroll.
            __weak UITableViewCell *weakCell = cell;
            NSString *bundleID = app.bundleIdentifier;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *icon = [ADSAppManager iconForBundleIdentifier:bundleID];
                if (!icon) return;
                app.icon = icon;
                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *cellNow = [tableView cellForRowAtIndexPath:indexPath];
                    if (cellNow == weakCell) {
                        cellNow.imageView.image = icon;
                        [cellNow setNeedsLayout];
                    }
                });
            });
        }
    } else {
        ADSTweakInfo *tweak = self.tweaks[indexPath.row];
        cell.textLabel.text = tweak.name;
        NSString *status = tweak.isActive ? @"Activo" : @"Desactivado";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", tweak.version, status];
        cell.imageView.image = tweak.icon ?: [UIImage systemImageNamed:@"wrench.and.screwdriver.fill"];
        cell.tintColor = tweak.isActive ? nil : [UIColor systemGrayColor];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == ADSSectionApps) {
        ADSAppInfo *app = self.apps[indexPath.row];
        ADSAppDetailController *detail = [[ADSAppDetailController alloc] initWithAppInfo:app];
        [self.navigationController pushViewController:detail animated:YES];
    } else {
        ADSTweakInfo *tweak = self.tweaks[indexPath.row];
        ADSTweakDetailController *detail = [[ADSTweakDetailController alloc] initWithTweakInfo:tweak];
        [self.navigationController pushViewController:detail animated:YES];
    }
}

@end
