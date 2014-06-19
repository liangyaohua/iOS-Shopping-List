//
//  ListViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "ProductListViewController.h"
#import "Product.h"
#import "ShoppingList.h"

@interface ProductListViewController ()

@end

@implementation ProductListViewController

- (ProductListViewController *)initWithSharedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        self.managedObjectContext = context;
        
        self.tableView.rowHeight = 50;
        
        [self loadProducts];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listsDidChange:) name:@"ShoppingListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ShoppingListDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
}

- (void)loadProducts
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:context];
    
    NSError *error;
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:NO];
    
    self.products = [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [self.products sortUsingDescriptors:@[sortDescriptor]];
}

- (void)updateProductList:(NSNotification *)notification
{
    if (notification.object != self) {
        [self loadProducts];
        [self.tableView reloadData];
    }
}

- (void)listsDidChange:(id)sender
{
    [self.tableView reloadData];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.title = @"Products";
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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:CellIdentifier];
        
        Product *p = [self.products objectAtIndex:[indexPath row]];
        
        cell.textLabel.text = p.name;
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@x $%@", p.stock, p.price];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
    }
    
    return cell;

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Product *p = [self.products objectAtIndex:[indexPath row]];
        [self.managedObjectContext deleteObject:p];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
        } else {
            [self.products removeObjectAtIndex:[indexPath row]];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductListDidChangeNotification" object:self];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
