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

#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"

#define TAG_NEW_LIST 1
#define TAG_RENAME_LIST 2
#define TAG_CONFIRM_DELETE 3

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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ShoppingListDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
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
    if (notification.object != self) {
        [self loadLists];
        [self.tableView reloadData];
    }
}

- (void)deleteRowWithPrompt:(NSIndexPath *)indexPath
{
    editingIndexPath = indexPath;
    ShoppingList* list = [self.lists objectAtIndex:[indexPath row]];
    
    NSString* msg = [NSString stringWithFormat:@"Are you sure your want to delete the list %@?", list.name];
    
    alert = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                       message:msg
                                      delegate:self
                             cancelButtonTitle:@"No"
                             otherButtonTitles:@"Yes", nil];
    alert.tag = TAG_CONFIRM_DELETE;
    [alert show];
}

- (void)deleteRow:(NSIndexPath *)indexPath
{
    ShoppingList *l = [self.lists objectAtIndex:[indexPath row]];
    [self.managedObjectContext deleteObject:l];
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        [self.lists removeObjectAtIndex:[indexPath row]];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == TAG_NEW_LIST) {
        NSString* txt = textField.text;
        ShoppingList* editingList = [self.lists objectAtIndex:[editingIndexPath row]];
        [textField removeFromSuperview];
        [textField resignFirstResponder];
        
        if ([txt length]) {
            editingList.name = txt;
            
            [self.tableView reloadRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            NSError* error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error saving context: %@", [error localizedDescription]);
                [self.managedObjectContext deleteObject:editingList];
                [self.lists removeObject:editingList];
                [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            }
            
        } else {
            [self.managedObjectContext deleteObject:editingList];
            [self.lists removeObject:editingList];
            [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        }
        
        editingIndexPath = nil;
        [self.tableView addGestureRecognizer:recognizer];
        [self.tableView.pullGestureRecognizer resetPullState];
    } else {
        [textField resignFirstResponder];
        [alert dismissWithClickedButtonIndex:1 animated:YES];
    }
    
    return YES;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
//    // New list
//    if (alertView.tag == TAG_NEW_LIST) {
//        NSString *name = [[alertView textFieldAtIndex:0] text];
//        if (buttonIndex > 0 && [name length] > 0) {
//            NSLog(@"Entered: %@", name);
//            
//            ShoppingList *list = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingList" inManagedObjectContext:self.managedObjectContext];
//            [list setName:name];
//            [list setDate:[NSDate date]];
//            
//            NSError *error;
//            if (![self.managedObjectContext save:&error]) {
//                NSLog(@"Error saving context: %@", [error localizedDescription]);
//            } else {
//                [self.lists addObject:list];
//                // Re-order array in order to add on top
//                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
//                [self.lists sortUsingDescriptors:@[sortDescriptor]];
//                
//                // Add row to table view
//                NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
//                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//                
//                ListViewController *listViewController = [[ListViewController alloc] initWithList:list andSharedContext:self.managedObjectContext andLists:self.lists];
//                
//                UIBarButtonItem *newBackButton =
//                [[UIBarButtonItem alloc] initWithTitle:@"Lists"
//                                                 style:UIBarButtonItemStyleBordered
//                                                target:nil
//                                                action:nil];
//                [[self navigationItem] setBackBarButtonItem:newBackButton];
//                [self.navigationController pushViewController:listViewController animated:YES];
//            }
//        }
//    }
//    else
    if (alertView.tag == TAG_RENAME_LIST) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            ShoppingList* editingList = [self.lists objectAtIndex:[editingIndexPath row]];
            [editingList setName:newName];
            NSError *error;
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error saving context: %@", [error localizedDescription]);
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
                [self.tableView reloadRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            editingIndexPath = nil;
        }
    } else if (alertView.tag == TAG_CONFIRM_DELETE) {
        if (buttonIndex > 0) {
            [self deleteRow:editingIndexPath];
        }
        editingIndexPath = nil;
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
    
    // Add pull gesture recognizer
    recognizer = [[MOOPullGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    
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
                cell.textLabel.text = @"Release to create list";
                break;
            case MOOPullIdle:
                cell.textLabel.text = @"Pull to create list";
                break;
                
        }
    };
    recognizer.triggerView = createView;
    [self.tableView addGestureRecognizer:recognizer];

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
    
    if (![list.name isEqualToString:@""]) {
        cell.textLabel.text = list.name;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        NSString *detailText = ([list.products count] == 1) ? @"1 Item" : [NSString stringWithFormat:@"%lu Items", (unsigned long)[list.products count]];
        NSString *timeText = [self timeIntervalToStringWithInterval:[list.date timeIntervalSinceNow]];
        cell.detailTextLabel.text = [detailText stringByAppendingString:[NSString stringWithFormat:@" | %@", timeText]];
        
        cell.detailTextLabel.textColor = [UIColor darkGrayColor];
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    
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
        [self deleteRow:indexPath];
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

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0: {
                    // delete
                    [self deleteRowWithPrompt:editingIndexPath];
                    break;
                }
                case 1:
                    // rename
                    
                    alert = [[UIAlertView alloc] initWithTitle:@"Rename list" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
                    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                    alert.tag = TAG_RENAME_LIST;
                    [[alert textFieldAtIndex:0] setDelegate:self];
                    [[alert textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
                    [[alert textFieldAtIndex:0] setSpellCheckingType:UITextSpellCheckingTypeYes];
                    [[alert textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeWords];
                    [[alert textFieldAtIndex:0] setText:[[self.lists objectAtIndex:[editingIndexPath row]] name]];
                    [[alert textFieldAtIndex:0] setTag:TAG_RENAME_LIST];
                    [alert show];

                    break;
                default:
                    // cancel, etc
                    editingIndexPath = nil;
                    break;
            }
            break;
        }
        default:
            break;
    }
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
    
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset.y -= CGRectGetMinY(pullGestureRecognizer.triggerView.frame);
    
    self.tableView.contentOffset = contentOffset;
    
    ShoppingList* newList = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingList" inManagedObjectContext:self.managedObjectContext];
    newList.name = @"";
    newList.date = [NSDate date];
    [self.lists addObject:newList];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [self.lists sortUsingDescriptors:@[sortDescriptor]];
    
    NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationTop];
    editingIndexPath = newIndexPath;
    
    UITableViewCell* newCell = [self.tableView cellForRowAtIndexPath:newIndexPath];
    
    NSArray* visibleCells = [self.tableView visibleCells];
    for (int i=1; i<[visibleCells count]; i++) {
        UITableViewCell* cell = [visibleCells objectAtIndex:i];
        cell.alpha = 0.25;
    }
    
	CGRect bounds = [newCell.contentView bounds];
	CGRect rect = CGRectInset(bounds, 20.0, 10.0);
    UITextField* tf = [[UITextField alloc] initWithFrame:rect];
    
    tf.placeholder = @"List name";
    tf.delegate = self;
    tf.tag = TAG_NEW_LIST;
    tf.font = [UIFont boldSystemFontOfSize:17];
    
    [newCell.contentView addSubview:tf];
    [tf becomeFirstResponder];
    
    [self.tableView removeGestureRecognizer:recognizer];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.pullGestureRecognizer)
        [scrollView.pullGestureRecognizer scrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView.pullGestureRecognizer)
        [scrollView.pullGestureRecognizer resetPullState];
}

- (NSString *)timeIntervalToStringWithInterval:(NSTimeInterval)interval
{
    NSString *retVal = @"At time of event";
    if (interval == 0) return retVal;
    
    int second = 1;
    int minute = second*60;
    int hour = minute*60;
    int day = hour*24;
    // interval can be before (negative) or after (positive)
    int num = abs(interval);
    
    NSString *beforeOrAfter = @"ago";
    NSString *unit = @"day";
    if (interval > 0) {
        beforeOrAfter = @"after";
    }
    
    if (num >= day) {
        num /= day;
        if (num > 1) unit = @"days";
    } else if (num >= hour) {
        num /= hour;
        unit = (num > 1) ? @"hours" : @"hour";
    } else if (num >= minute) {
        num /= minute;
        unit = (num > 1) ? @"minutes" : @"minute";
    } else if (num >= second) {
        num /= second;
        unit = (num > 1) ? @"seconds" : @"second";
        
    }
    
    return [NSString stringWithFormat:@"%d %@ %@", num, unit, beforeOrAfter];
}

@end
