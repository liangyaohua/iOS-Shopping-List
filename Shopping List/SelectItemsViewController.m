//
//  SelectItemsViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/9/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "SelectItemsViewController.h"
#import "ShoppingList.h"
#import "ShoppingItem.h"
#import "Product.h"

@interface SelectItemsViewController ()

@end

@implementation SelectItemsViewController

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self) {
        self.list = list;
        self.managedObjectContext = context;
        [self loadProducts];
        
        self.title = @"Select products";
        
        self.tableView = [[UITableView alloc] init];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.rowHeight = 50;
        self.view = self.tableView;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
        //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewProduct:)];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
}

- (void)loadProducts
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:context];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSError *error;
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:YES];
    [fetchRequest setSortDescriptors:@[sort]];
    
    self.products = [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
}

- (void)updateProductList:(NSNotification *)notification {
    [self loadProducts];
    [self.tableView reloadData];
}

- (int)quantityOfProductInList:(Product *)p
{
    for (ShoppingItem *i in self.list.products) {
        if (i.product == p) {
            return 1;
        }
    }
    return 0;
}

- (void)saveChanges
{
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"There was an error saving the list."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];

    }
    
}

- (void)addNewProduct:(id)sender
{
    alert = [[UIAlertView alloc] initWithTitle:@"New product" message:@"Enter a name for the product" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* tf = [alert textFieldAtIndex:0];

    [tf setDelegate:self];
    [tf setReturnKeyType:UIReturnKeyDone];
    [tf setSpellCheckingType:UITextSpellCheckingTypeYes];
    [tf setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [tf setInputAccessoryView:self.inputAccessoryView];
    [alert show];
}

- (BOOL)textFieldShouldReturn:(UITextField *)alertTextField
{
    [alertTextField resignFirstResponder];
    [alert dismissWithClickedButtonIndex:1 animated:YES];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *name = [[alertView textFieldAtIndex:0] text];
    
    if (buttonIndex > 0 && [name length] > 0) {
        Product *newProduct = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
        [newProduct setName:name];
        ShoppingItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
        [newItem setProduct:newProduct];
        [newItem setInList:self.list];
        [newItem setQuantity:[[NSNumber alloc] initWithDouble:1.0]];
        [newItem setBought:NO];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
            alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"There was an error saving the new product."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductListDidChangeNotification" object:self];
        }
    }
}

- (void)close:(id)sender
{
    [self saveChanges];
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
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

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
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Product *p = [self.products objectAtIndex:[indexPath row]];
    int quantity = [self quantityOfProductInList:p];
    [cell.textLabel setText:p.name];
    cell.textLabel.font = [UIFont systemFontOfSize:15];


    if (quantity) {
//        [cell.textLabel setText:[NSString stringWithFormat:@"%@ (%d)",p.name,quantity]];
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Product *p = [self.products objectAtIndex:[indexPath row]];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    if ([self quantityOfProductInList:p]) {
        
        for (ShoppingItem *i in self.list.products) {
            if (i.product == p) {
                [self.managedObjectContext deleteObject:i];
                [cell.textLabel setText:p.name];
                [cell setAccessoryType:UITableViewCellAccessoryNone];
                NSLog(@"Item deleted from list");
            }
        }
    } else {
        NSLog(@"Creating item");
        
        ShoppingItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
        [newItem setProduct:p];
        [newItem setInList:self.list];
        [newItem setQuantity:p.stock];
        [newItem setPurchasedQuantity: [[NSNumber alloc] initWithInt:1]];
        [newItem setPrice:p.price];
        [newItem setDate:[NSDate date]];
        [newItem setBought:[[NSNumber alloc] initWithBool:YES]];
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        NSLog(@"Item added to list");
        
    }
}

@end
