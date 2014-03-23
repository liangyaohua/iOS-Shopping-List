//
//  PreferencesViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 3/19/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "PreferencesViewController.h"

@interface PreferencesViewController ()

@end

@interface Preference : NSObject
@property NSString* name;
@property NSString* description;
@property NSString* key;
@property BOOL value;
@end

@implementation Preference
@end

@implementation PreferencesViewController

- (id)init
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Preferences";
        
        ud = [NSUserDefaults standardUserDefaults];
        
        Preference* autoRemovalPref = [[Preference alloc] init];
        autoRemovalPref.name = @"Clear purchased items";
        autoRemovalPref.description = @"Removes items from the list automatically after marking as purchased.";
        autoRemovalPref.key = @"ShoppingListUserDefaultsAutoRemoval";
        autoRemovalPref.value = [ud boolForKey:autoRemovalPref.key];
        
        Preference* priceComparisonPref = [[Preference alloc] init];
        priceComparisonPref.name = @"Price comparison";
        priceComparisonPref.description = @"Allows to register the price of each item during purchase and compare it to previous shopping trips.";
        priceComparisonPref.key = @"ShoppingListUserDefaultsPriceComparison";
        priceComparisonPref.value = [ud boolForKey:priceComparisonPref.key];
        
        prefs = @[autoRemovalPref,
                  priceComparisonPref];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [prefs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Preference* p = [prefs objectAtIndex:indexPath.section];
    
    cell.textLabel.text = p.name;
    
    UISwitch* prefSwitch = [[UISwitch alloc] init];
    prefSwitch.on = p.value;
    [prefSwitch addTarget:self action:@selector(switchStateUpdated:) forControlEvents:UIControlEventValueChanged];

    cell.accessoryView = prefSwitch;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    Preference* p = [prefs objectAtIndex:section];
    
    return p.description;
}

- (void)switchStateUpdated:(id)sender
{
    for (int i=0; i<[prefs count]; i++) {
        UISwitch* sw = (UISwitch*) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]].accessoryView;
        Preference* pref = [prefs objectAtIndex:i];
        pref.value = sw.on;
        [ud setBool:pref.value forKey:pref.key];
//        NSLog(@"Pref %@ updated to %@", pref.key, pref.value ? @"YES" : @"NO");
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsDidChangeNotification" object:self];

}

@end
