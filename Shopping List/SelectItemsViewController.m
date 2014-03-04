//
//  SelectItemsViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/9/14.
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
        
        self.title = [NSString stringWithFormat:@"Select items on '%@'", list.name];
        
        self.tableView = [[UITableView alloc] init];
        [self.tableView setDelegate:self];
        [self.tableView setDataSource:self];
        self.view = self.tableView;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewProduct:)];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        
    }
    return self;
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
            return [i.quantity intValue];
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
//        [self.delegate didUpdateList];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];

    }
    
}

- (void)addNewProduct:(id)sender
{
    alert = [[UIAlertView alloc] initWithTitle:@"New product" message:@"Enter a name for the product" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
//    [self createInputAccessoryView];
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
    [[alert textFieldAtIndex:0] setSpellCheckingType:UITextSpellCheckingTypeYes];
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [[alert textFieldAtIndex:0] setInputAccessoryView:self.inputAccessoryView];
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
//
//- (void)createInputAccessoryView
//{
//    if (!self.inputAccessoryView) {
//        CGRect accessFrame = CGRectMake(10.0, 0.0, 768.0, 40.0);
//        self.inputAccessoryView = [[UIView alloc] initWithFrame:accessFrame];
//        self.inputAccessoryView.backgroundColor = [UIColor whiteColor];
//        self.inputAccessoryView.alpha = 0.5;
//        UIButton *compButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//        compButton.frame = CGRectMake(10.0, 0.0, 100.0, 40.0);
//        [compButton setTitle: @"Add amount" forState:UIControlStateNormal];
//        [compButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
////        [compButton addTarget:self action:@selector(completeCurrentWord:)
////             forControlEvents:UIControlEventTouchUpInside];
//        [self.inputAccessoryView addSubview:compButton];
//    }
//}

- (IBAction)close:(id)sender
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
        [newItem setQuantity:[[NSNumber alloc] initWithDouble:1.0]];
        [newItem setBought:NO];
        
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        NSLog(@"Item added to list");
        
    }
}

@end
