//
//  SelectListViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/17/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "SelectListViewController.h"

@interface SelectListViewController ()

@end

@implementation SelectListViewController

- (id)initWithLists:(NSArray *)lists andCurrentList:(ShoppingList *)currentList andSharedContext:(NSManagedObjectContext *)context;
{
    self = [super init];
    
    if (self) {
        self.managedObjectContext = context;
        
        // List array includes all except currentList
        NSMutableArray* otherLists = [[NSMutableArray alloc] init];
        for (ShoppingList* list in lists) {
            if (list != currentList)
                [otherLists addObject:list];
        }
        self.lists = otherLists;
        
        self.title = @"Select list to import";
        self.tableView.rowHeight = 50;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close:)];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
                
    }
    return self;
}

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.lists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    
    ShoppingList *list = [self.lists objectAtIndex:[indexPath row]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    [cell.textLabel setText:[list name]];
    NSString *detailText = ([list.products count] == 1) ? @"1 Item" : [NSString stringWithFormat:@"%lu Items", (unsigned long)[list.products count]];
    detailText = [detailText stringByAppendingString:[NSString stringWithFormat:@" | %@", [dateFormatter stringFromDate:list.date]]];
    [cell.detailTextLabel setText:detailText];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ShoppingList *list = [self.lists objectAtIndex:[indexPath row]];
    [self.delegate importList:list];
    [self close:self];
}

@end
