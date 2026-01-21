#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

// --- إعدادات جولد برو ---
#define PrefPath @"/var/mobile/Library/Preferences/com.goldpro.settings.plist"
#define API_URL @"https://script.google.com/macros/s/AKfycbz_XXXXXXXXX/exec" 

// تعريف الكلاسات لكي لا يظهر خطأ (Forward Declaration Fix)
@interface SPCameraViewController : UIViewController
@end

// دالة جلب حالة الأزرار
static BOOL getPref(NSString *key) {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:PrefPath];
    return dict[key] ? [dict[key] boolValue] : NO;
}

// دالة حفظ حالة الأزرار
static void setPref(NSString *key, BOOL value) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:PrefPath] ?: [NSMutableDictionary dictionary];
    [dict setObject:@(value) forKey:key];
    [dict writeToFile:PrefPath atomically:YES];
}

// ==========================================
// 1. واجهة المنيو الذهبية
// ==========================================
@interface GoldMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *features;
@property (nonatomic, strong) NSArray *keys;
@end

@implementation GoldMenuController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"إعدادات جولد برو";
    self.features = @[@"وضع الشبح", @"إخفاء يكتب الآن", @"حفظ السنابات", @"سحب المحادثات", @"تزييف الستريك", @"توثيق الحساب", @"تغيير الموقع", @"فك حظر الجهاز"];
    self.keys = @[@"ghost_mode", @"hide_typing", @"save_feature", @"pull_chat", @"fake_streak", @"verify_mark", @"fake_gps", @"unban_device"];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.features.count; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    cell.textLabel.text = self.features[indexPath.row];
    UISwitch *sw = [[UISwitch alloc] init];
    [sw setOn:getPref(self.keys[indexPath.row])];
    sw.tag = indexPath.row;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = sw;
    return cell;
}
- (void)switchChanged:(UISwitch *)sender { setPref(self.keys[sender.tag], sender.isOn); }
@end

// ==========================================
// 2. ربط الميزات بالبرمجة
// ==========================================
%hook SCChatMessage
- (BOOL)isRead { return getPref(@"ghost_mode") ? NO : %orig; }
- (BOOL)isScreenshotted { return getPref(@"save_feature") ? NO : %orig; }
- (BOOL)isSaved { return getPref(@"pull_chat") ? YES : %orig; }
%end

%hook SCChatTypingParticipant
- (void)setIsTyping:(BOOL)typing { %orig(getPref(@"hide_typing") ? NO : typing); }
%end

%hook SCXStreakManager
- (int)streakCount { return getPref(@"fake_streak") ? 999 : %orig; }
%end

%hook SCLegacyUser
- (BOOL)isVerified { return getPref(@"verify_mark") ? YES : %orig; }
%end

%hook UIDevice
- (NSUUID *)identifierForVendor { return getPref(@"unban_device") ? [NSUUID UUID] : %orig; }
%end

// ==========================================
// 3. التحقق من الكود (السيرفر)
// ==========================================
%hook SPCameraViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    static BOOL isAuth = NO;
    if (!isAuth) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"⚜️ GOLD SNAP V10 ⚜️" 
                                    message:@"أدخل كود التفعيل" 
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *f) { f.placeholder = @"كود التفعيل"; }];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"تفعيل" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *code = alert.textFields.firstObject.text;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?code=%@", API_URL, code]];
            [[[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
                if (d && [[[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] lowercaseString] containsString:@"success"]) {
                    isAuth = YES;
                } else { exit(0); }
            }] resume];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"فتح المنيو" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(isAuth) {
                GoldMenuController *menu = [[GoldMenuController alloc] init];
                [self presentViewController:menu animated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}
%end
