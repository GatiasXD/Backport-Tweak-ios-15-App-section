#import "ADSAppDetailController.h"
#import "ADSAppManager.h"
#import "LSApplicationWorkspace.h"

@interface ADSAppDetailController ()
@property (nonatomic, strong) ADSAppInfo *appInfo;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *rows; // [ [titulo, valor], ... ] por sección
@end

@implementation ADSAppDetailController

- (instancetype)initWithAppInfo:(ADSAppInfo *)appInfo {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _appInfo = appInfo;
        self.title = appInfo.displayName;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.rows = @[
        @[@"Nombre", self.appInfo.displayName ?: @"-"],
        @[@"Bundle ID", self.appInfo.bundleIdentifier ?: @"-"],
        @[@"Versión", self.appInfo.version ?: @"-"],
        @[@"Tipo", self.appInfo.isSystemApp ? @"App de sistema" : @"App de usuario"],
    ];

    if (!self.appInfo.icon) {
        self.appInfo.icon = [ADSAppManager iconForBundleIdentifier:self.appInfo.bundleIdentifier];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? self.rows.count : 1; // sección 1 = acción "Abrir app"
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];

    if (indexPath.section == 0) {
        NSArray<NSString *> *pair = self.rows[indexPath.row];
        cell.textLabel.text = pair[0];
        cell.detailTextLabel.text = pair[1];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if (indexPath.row == 0) {
            cell.imageView.image = self.appInfo.icon;
            cell.imageView.layer.cornerRadius = 9;
            cell.imageView.layer.masksToBounds = YES;
        }
    } else {
        cell.textLabel.text = @"Abrir aplicación";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = self.view.tintColor;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        [[LSApplicationWorkspace defaultWorkspace] openApplicationWithBundleID:self.appInfo.bundleIdentifier];
    }
}

@end
