//
//  ShoppingListsViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "ShoppingListsViewController.h"
#import "SelectItemsViewController.h"
#import "ListViewController.h"
#import "ShoppingList.h"

@interface ShoppingListsViewController ()

@end

@implementation ShoppingListsViewController

- (ShoppingListsViewController *)initWithSharedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        [self setManagedObjectContext:context];
        [self loadLists];
        self.tableView.rowHeight = 80;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listsDidChange:) name:@"ShoppingListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listsDidChange:) name:@"ProductListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)loadLists
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShoppingList" inManagedObjectContext:context];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSError *error;
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:NO];
    [fetchRequest setSortDescriptors:@[sort]];
    
    self.lists = [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
}

- (void)listsDidChange:(NSNotification *)notification {
    [self loadLists];
    [self.tableView reloadData];
}

- (void)addNewList:(id)sender
{
    alert = [[UIAlertView alloc] initWithTitle:@"New list" message:@"Enter a name for this shopping list." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 1;
    [[alert textFieldAtIndex:0] setDelegate:self];
    [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
    [[alert textFieldAtIndex:0] setSpellCheckingType:UITextSpellCheckingTypeYes];
    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [[alert textFieldAtIndex:0] setTag:1];
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
    
    // New list
    if (alertView.tag == 1) {
        if (buttonIndex > 0 && [name length] > 0) {
            NSLog(@"Entered: %@", name);
            
            ShoppingList *list = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingList" inManagedObjectContext:self.managedObjectContext];
            [list setName:name];
            [list setDate:[NSDate date]];
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error saving context: %@", [error localizedDescription]);
            } else {
                [self.lists addObject:list];
                // Re-order array in order to add on top
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
                [self.lists sortUsingDescriptors:@[sortDescriptor]];
                
                // Add row to table view
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
                ListViewController *listViewController = [[ListViewController alloc] initWithList:list andSharedContext:self.managedObjectContext andLists:self.lists];
                
                UIBarButtonItem *newBackButton =
                [[UIBarButtonItem alloc] initWithTitle:@"Lists"
                                                 style:UIBarButtonItemStyleBordered
                                                target:nil
                                                action:nil];
                [[self navigationItem] setBackBarButtonItem:newBackButton];
                [self.navigationController pushViewController:listViewController animated:YES];
            }
        }
    }
    // Rename list
    else if (alertView.tag == 2) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            ShoppingList* editingList = [self.lists objectAtIndex:[editingIndexPath row]];
            [editingList setName:newName];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
            editingIndexPath = nil;
            
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error saving context: %@", [error localizedDescription]);
            }
        }
    }
}

- (void)displayProductSelectionViewOfList:(ShoppingList*)l
{    
    SelectItemsViewController *selectItemsViewController = [[SelectItemsViewController alloc] initWithList:l andSharedContext:self.managedObjectContext];
    
    UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:selectItemsViewController];
    [self presentViewController:nav2 animated:YES completion:nil];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.title = @"Shopping lists";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 0.5; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
    
    self.navigationItem.RightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewList:)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
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
    cell.detailTextLabel.textColor = [UIColor darkGrayColor];
//    NSLog(@"%@", [NSString stringWithFormat:@" | Created on %@", [dateFormatter stringFromDate:list.date]]);
    
//    [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ShoppingList *list = [self.lists objectAtIndex:[indexPath row]];
    
    ListViewController *listViewController = [[ListViewController alloc] initWithList:list andSharedContext:self.managedObjectContext andLists:self.lists];
    
    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Lists"
                                     style:UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];
    [self.navigationController pushViewController:listViewController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ShoppingList *l = [self.lists objectAtIndex:[indexPath row]];
        [self.managedObjectContext deleteObject:l];
        
        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
        } else {
            [self.lists removeObjectAtIndex:[indexPath row]];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath != nil) {
            editingIndexPath = indexPath;
            UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                          initWithTitle:nil
                                          delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Delete list"
                                          otherButtonTitles:@"Rename list", nil];
            actionSheet.tag = 1;
            [actionSheet showInView:self.view];
        }
    }
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            ShoppingList* editingList = [self.lists objectAtIndex:[editingIndexPath row]];
            switch (buttonIndex) {
                case 0: {
                    // delete
                    [self.managedObjectContext deleteObject:editingList];
                    
                    NSError *error;
                    if (![self.managedObjectContext save:&error]) {
                        NSLog(@"Error saving context: %@", [error localizedDescription]);
                    } else {
                        [self.lists removeObject:editingList];
                        [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                    
                    editingIndexPath = nil;
                    break;
                }
                case 1:
                    // rename
                    
                    alert = [[UIAlertView alloc] initWithTitle:@"Rename list" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    alert.tag = 2;
                    [[alert textFieldAtIndex:0] setDelegate:self];
                    [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
                    [[alert textFieldAtIndex:0] setSpellCheckingType:UITextSpellCheckingTypeYes];
                    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                    [[alert textFieldAtIndex:0] setText:[[self.lists objectAtIndex:[editingIndexPath row]] name]];
                    [alert show];

                    break;
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

@end
