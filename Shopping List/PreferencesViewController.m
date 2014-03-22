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
@property NSObject* value;
@end

@implementation Preference
@end

@implementation PreferencesViewController


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.title = @"Preferences";
        
        Preference* autoRemovalPref = [[Preference alloc] init];
        autoRemovalPref.name = @"Clear purchased items";
        autoRemovalPref.description = @"Removes items from the list automatically after marking as purchased.";
        
        Preference* priceComparisonPref = [[Preference alloc] init];
        priceComparisonPref.name = @"Price comparison";
        priceComparisonPref.description = @"Allows to register the price of each item during purchase and compare it to previous shopping trips.";
        
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
    
//    cell.textLabel.text = @"Cell";
    
    cell.accessoryView = [[UISwitch alloc] init];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    Preference* p = [prefs objectAtIndex:section];
    
    return p.description;
}

@end
