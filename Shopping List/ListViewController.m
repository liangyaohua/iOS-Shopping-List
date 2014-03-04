//
//  ListViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "ListViewController.h"
#import "SelectListViewController.h"
#import "Product.h"
#import "ShoppingItem.h"

#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"

@interface ListViewController ()

@end

@implementation ListViewController

- (id)initWithList:(ShoppingList *)list andSharedContext:(NSManagedObjectContext *)context andLists:(NSArray *)lists
{
    self = [self init];
    if (self) {
        self.list = list;
        self.lists = lists;
        self.managedObjectContext = context;
        self.title = list.name;
        self.titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.titleButton setTitle:list.name forState:UIControlStateNormal];
        [self.titleButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [self.titleButton addTarget:self action:@selector(didTapTitle:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = self.titleButton;
        
        self.tableView.delegate = self;
        
        [self renderEmptyView];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonResponder:)];
        
        if (![self.list.products count]) {
            self.view = self.emptyView;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ShoppingListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)renderEmptyView
{
    self.emptyView = [[UIView alloc] initWithFrame:self.tableView.frame];
    self.emptyView.center = self.view.superview.center;
    self.emptyView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.emptyView.backgroundColor = [UIColor whiteColor];
    
    int paddingX = 50;
    int labelWidth = self.tableView.frame.size.width - 2*paddingX;
    
    UILabel *emptyListLabel = [[UILabel alloc] init];
    emptyListLabel.frame = CGRectMake(paddingX, 175, labelWidth, 100);
    emptyListLabel.text = @"This shopping list is empty";
    emptyListLabel.textAlignment = NSTextAlignmentCenter;
    emptyListLabel.lineBreakMode = NSLineBreakByWordWrapping;
    emptyListLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    emptyListLabel.numberOfLines = 0;
    emptyListLabel.font = [UIFont systemFontOfSize:25];
    emptyListLabel.textColor = [UIColor darkGrayColor];
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.frame = CGRectMake(paddingX, 260, labelWidth, 70);
    infoLabel.text = @"Add items to the list or import an existing list.";
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.font = [UIFont systemFontOfSize:17];
    infoLabel.textColor = [UIColor lightGrayColor];
    
    UIButton *addItemsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    addItemsButton.frame = CGRectMake(0, 340, self.tableView.frame.size.width, 30);
    [addItemsButton setTitle:@"Add items to list" forState:UIControlStateNormal];
    [addItemsButton addTarget:self action:@selector(editButtonResponder:) forControlEvents:UIControlEventTouchDown];
    
    UIButton *duplicateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    duplicateButton.frame = CGRectMake(0, 370, self.tableView.frame.size.width, 30);
    [duplicateButton setTitle:@"Import existing list" forState:UIControlStateNormal];
    [duplicateButton addTarget:self action:@selector(selectListToDuplicate:) forControlEvents:UIControlEventTouchDown];

    [self.emptyView addSubview:emptyListLabel];
    [self.emptyView addSubview:infoLabel];
    [self.emptyView addSubview:addItemsButton];
    [self.emptyView addSubview:duplicateButton];
}

- (IBAction)didTapTitle:(id)sender
{
    NSLog(@"Did tap on title");
    
    alert = [[UIAlertView alloc] initWithTitle:@"Rename list" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 2;
    UITextField *tf = [alert textFieldAtIndex:0];
    tf.tag = 2;
    [tf setDelegate:self];
    [tf setReturnKeyType:UIReturnKeyDone];
    [tf setText:self.list.name];
    [alert show];
}

- (IBAction)selectListToDuplicate:(id)sender
{
    SelectListViewController *selectListViewController = [[SelectListViewController alloc] initWithLists:self.lists andSharedContext:self.managedObjectContext];
    
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:selectListViewController];
    [selectListViewController setDelegate:self];
    [self presentViewController:nav2 animated:YES completion:nil];
}

- (void)importList:(ShoppingList *)list
{
    // Copy each item from the received shopping list
    for (ShoppingItem* item in list.products) {
        ShoppingItem *newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
        [newItem setProduct:item.product];
        [newItem setInList:self.list];
        [newItem setQuantity:item.quantity];
        [newItem setBought:NO];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:@"There was an error importing the list."
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"List imported");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
    }

}

- (void)updateProductList:(NSNotification *)notification
{
    [self.tableView reloadData];
    [self.titleButton setTitle:self.list.name forState:UIControlStateNormal];
    
    if (![self.list.products count]) {
        self.view = self.emptyView;
    } else {
        self.view = self.tableView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Add pull gesture recognizer
    MOOPullGestureRecognizer *recognizer = [[MOOPullGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    
    // Create cell
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.backgroundColor = self.tableView.backgroundColor; // UITableViewCell background color is transparent by default
    cell.imageView.image = [UIImage imageNamed:@"Arrow-Bucket.png"];
    
    // Create create view
    MOOCreateView *createView = [[MOOCreateView alloc] initWithCell:cell];
    createView.configurationBlock = ^(MOOCreateView *view, UITableViewCell *cell, MOOPullState state){
        if (![cell isKindOfClass:[UITableViewCell class]])
            return;
        
        switch (state) {
            case MOOPullActive:
            case MOOPullTriggered:
                cell.textLabel.text = NSLocalizedStringFromTable(@"Release to create item\u2026", @"MOOPullGesture", @"Release to create item");
                break;
            case MOOPullIdle:
                cell.textLabel.text = NSLocalizedStringFromTable(@"Pull to create item\u2026", @"MOOPullGesture", @"Pull to create item");
                break;
                
        }
    };
    recognizer.triggerView = createView;
    [self.tableView addGestureRecognizer:recognizer];
}

#pragma mark - MOOPullGestureRecognizer targets

- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;
{
    if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
        if ([gestureRecognizer conformsToProtocol:@protocol(MOOPullGestureRecognizer)])
            [self _pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)gestureRecognizer];
    }
}

- (void)_pulledToCreate:(UIGestureRecognizer<MOOPullGestureRecognizer> *)pullGestureRecognizer;
{
//    self.lists.numberOfRows++;
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);
    [self.tableView reloadData];
    self.tableView.contentOffset = contentOffset;
    NSLog(@"Added item");

//    NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
//    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    if (scrollView.pullGestureRecognizer)
        [scrollView.pullGestureRecognizer scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
{
    if (scrollView.pullGestureRecognizer)
        [scrollView.pullGestureRecognizer resetPullState];
}

- (IBAction)editButtonResponder:(id)sender
{
    SelectItemsViewController *selectItemsViewController = [[SelectItemsViewController alloc] initWithList:self.list andSharedContext:self.managedObjectContext];
    
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:selectItemsViewController];
//    [selectItemsViewController setDelegate:self];
    [self presentViewController:nav2 animated:YES completion:nil];
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
    return [self.list.products count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

    ShoppingItem *item = [[self.list.products allObjects] objectAtIndex:[indexPath row]] ;
    
    [cell.textLabel setText:item.product.name];
    if ([item.quantity intValue] > 1)
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%dx", [item.quantity intValue]]];
    if (![item.bought boolValue]) {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
        cell.textLabel.alpha = 1.0;
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        cell.textLabel.alpha = 0.3;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ShoppingItem *item = [[self.list.products allObjects] objectAtIndex:[indexPath row]];
    NSString* markPurchasedTitle = ([item.bought boolValue]) ? @"Unmark as purchased" : @"Mark as purchased";
    
    editingIndexPath = indexPath;
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:item.product.name
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:@"Remove from list"
                                  otherButtonTitles:@"Change amount", markPurchasedTitle, nil];
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (popup.tag) {
        case 1: {
            ShoppingItem *editingItem = [[self.list.products allObjects] objectAtIndex:[editingIndexPath row]];
            switch (buttonIndex) {
                case 0: {
                    // delete
                    [self.managedObjectContext deleteObject:editingItem];
                    
                    NSError *error;
                    if (![self.managedObjectContext save:&error]) {
                        NSLog(@"Error saving context: %@", [error localizedDescription]);
                    } else {
//                        [self.list.products removeObject:editingItem];
//                        [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];

                    }
                    
                    editingIndexPath = nil;
                    break;
                }
                case 1: {
                    // change amount
                    alert = [[UIAlertView alloc] initWithTitle:@"Edit amount" message:[NSString stringWithFormat:@"Enter the amount for '%@'", editingItem.product.name] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    alert.tag = 1;
                    UITextField *tf = [alert textFieldAtIndex:0];
                    tf.tag = 1;
                    [tf setDelegate:self];
                    [tf setKeyboardType:UIKeyboardTypeDecimalPad];
                    [tf setReturnKeyType:UIReturnKeyDone];
                    [tf setPlaceholder:[editingItem.quantity stringValue]];
                    [alert show];
                    
                    break;
                }
                case 2: {
                    // toggle purchased
                    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:editingIndexPath];
                    if ([editingItem.bought boolValue]) {
                        editingItem.bought = [NSNumber numberWithBool:NO];
                        [cell setAccessoryType:UITableViewCellAccessoryNone];
                        cell.textLabel.alpha = 1.0;
                    } else {
                        editingItem.bought = [NSNumber numberWithBool:YES];
                        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
                        cell.textLabel.alpha = 0.3;
                    }
                    
                    NSError *error;
                    if (![self.managedObjectContext save:&error]) {
                        NSLog(@"Error saving context: %@", [error localizedDescription]);
                        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                           message:@"There was an error updating the list."
                                                          delegate:self
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
                        [alert show];
                    } else {
                        NSLog(@"List updated");
                    }

                    break;
                }
                default:
                    // cancel, etc
                    //                    NSLog(@"Index %lu, button %@", buttonIndex, [popup buttonTitleAtIndex:buttonIndex]);
                    editingIndexPath = nil;
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        ShoppingItem *editingItem = [[self.list.products allObjects] objectAtIndex:[editingIndexPath row]];
        float newQuantity = [[[alertView textFieldAtIndex:0] text] floatValue];
        if (buttonIndex > 0 && newQuantity > 0) {
            editingItem.quantity = [NSNumber numberWithFloat:newQuantity];
        }
    } else if (alertView.tag == 2) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            [self.list setName:newName];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
        }
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:@"There was an error updating the list."
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"List updated");
        [self.tableView reloadData];
        editingIndexPath = nil;
    }

}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
