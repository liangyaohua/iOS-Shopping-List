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
#import "ShoppingTrip.h"
#import "ShoppingTripItem.h"
#import "TripViewController.h"

#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"

#import "HTAutocompleteTextField.h"
#import "ProductHTAutocompleteManager.h"

#define TAG_NEW_ITEM 1
#define TAG_EDIT_QUANTITY 2
#define TAG_EDIT_LIST_TITLE 3
#define TAG_CONFIRM_DELETE 4

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
        self.trip = nil;
        self.items = [[list.products allObjects] mutableCopy];
        
        self.title = list.name;
        self.titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.titleButton setTitle:list.name forState:UIControlStateNormal];
        [self.titleButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [self.titleButton addTarget:self action:@selector(startShoppingTrip:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = self.titleButton;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(editButtonResponder:)];
        
        self.hidesBottomBarWhenPushed = YES;
        self.tableView.delegate = self;
        self.tableView.rowHeight = 50;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:227.0 / 255.0 green:227.0 / 255.0 blue:227.0 / 255.0 alpha:1.0]];
        [self.tableView setBackgroundView:backgroundView];
        [self renderEmptyView];
        
        self.normalView = self.view;
    
        if (![self.items count]) {
            self.view = self.emptyView;
        } else {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
            [self.items sortUsingDescriptors:@[sortDescriptor]];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ShoppingListDidChangeNotification" object:nil];
        
        autocompleteManager = [[ProductHTAutocompleteManager alloc] initWithSharedContext:self.managedObjectContext];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ShoppingListDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
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
    emptyListLabel.text = @"This quotation is empty";
    emptyListLabel.textAlignment = NSTextAlignmentCenter;
    emptyListLabel.lineBreakMode = NSLineBreakByWordWrapping;
    emptyListLabel.numberOfLines = 0;
    emptyListLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    emptyListLabel.font = [UIFont systemFontOfSize:25];
    emptyListLabel.textColor = [UIColor darkGrayColor];
    emptyListLabel.frame = CGRectMake(paddingX,
                                      100,
                                      labelWidth,
                                      100);

    
    
    UILabel *infoLabel = [[UILabel alloc] init];
    infoLabel.text = @"Add products or import from an existing quotation.";
    infoLabel.frame = CGRectMake(paddingX, 190, labelWidth, 100);
    infoLabel.textAlignment = NSTextAlignmentCenter;
    infoLabel.numberOfLines = 0;
    infoLabel.autoresizingMask = emptyListLabel.autoresizingMask;
    infoLabel.lineBreakMode = NSLineBreakByWordWrapping;
    infoLabel.font = [UIFont systemFontOfSize:17];
    infoLabel.textColor = [UIColor lightGrayColor];
    
    UIButton *addItemsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    addItemsButton.frame = CGRectMake(0, 290, self.tableView.frame.size.width, 30);
    addItemsButton.autoresizingMask = emptyListLabel.autoresizingMask;
    [addItemsButton setTitle:@"Add products" forState:UIControlStateNormal];
    [addItemsButton addTarget:self action:@selector(editButtonResponder:) forControlEvents:UIControlEventTouchDown];
    
    UIButton *duplicateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    duplicateButton.frame = CGRectMake(0, 340, self.tableView.frame.size.width, 30);
    duplicateButton.autoresizingMask = emptyListLabel.autoresizingMask;
    [duplicateButton setTitle:@"Import existing quotation" forState:UIControlStateNormal];
    [duplicateButton addTarget:self action:@selector(selectListToDuplicate:) forControlEvents:UIControlEventTouchDown];

    [self.emptyView addSubview:emptyListLabel];
    [self.emptyView addSubview:infoLabel];
    [self.emptyView addSubview:addItemsButton];
    [self.emptyView addSubview:duplicateButton];
}

- (void)renderSwipeHelpView
{
    if (self.swipeHelpView == nil) {
        self.swipeHelpView = [[UIView alloc] init];
        UIView* helpView = self.swipeHelpView;
        helpView.autoresizesSubviews = YES;
        helpView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleBottomMargin;
        helpView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
        
        self.swipeHelpViewLabel = [[UILabel alloc] init];
        UILabel* helpText = self.swipeHelpViewLabel;
        helpText.text = @"swipe right to change the quantity, swipe left to delete";
        helpText.textAlignment = NSTextAlignmentCenter;
        helpText.numberOfLines = 0;
        helpText.lineBreakMode = NSLineBreakByWordWrapping;
        helpText.font = [UIFont systemFontOfSize:12];
        helpText.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        [helpView addSubview:helpText];
        
        [self.view.superview addSubview:helpView];
        

    }
    
    int paddingY = 0;
    int width = self.view.superview.frame.size.width;
    int height = 50;
    int y = CGRectGetMaxY(self.view.frame) - height - paddingY;
    
    self.swipeHelpView.frame = CGRectMake(0,
                                CGRectGetMaxY(self.view.frame),
                                width,
                                height);
    self.swipeHelpViewLabel.frame = CGRectMake(0,
                                0,
                                self.swipeHelpView.frame.size.width,
                                self.swipeHelpView.frame.size.height);
    
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.swipeHelpView.frame = CGRectMake(self.swipeHelpView.frame.origin.x,
                                                               y,
                                                               self.swipeHelpView.frame.size.width,
                                                               self.swipeHelpView.frame.size.height);
                     }
                     completion:^(BOOL finished){
                     }];
    
    [self performSelector: @selector(hideSwipeHelpView) withObject: nil afterDelay: 5.0];
}

- (void)hideSwipeHelpView
{
    [UIView animateWithDuration:0.5
                          delay:0.1
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.swipeHelpView.frame = CGRectMake(self.swipeHelpView.frame.origin.x,
                                                               CGRectGetMaxY(self.view.frame),
                                                               self.swipeHelpView.frame.size.width,
                                                               self.swipeHelpView.frame.size.height);
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)startShoppingTrip:(id)sender
{
    // See if shopping trip already exists
    /*NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShoppingTrip"
                                              inManagedObjectContext:self.managedObjectContext];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"list == %@", self.list];
    [fetchRequest setPredicate:pred];
    [fetchRequest setEntity:entity];
    
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    // If an object was found, use it in the new item. If not, create it
    if ([fetchedObjects count] > 0) {
        NSLog(@"Shopping Trip already found. Using it...");
        self.trip = [fetchedObjects objectAtIndex:0];
    } else {*/
        NSLog(@"Create shopping trip");
        
        self.trip = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingTrip" inManagedObjectContext:self.managedObjectContext];
        self.trip.list = self.list;
        self.trip.date = [NSDate date];
        
        for (ShoppingItem* item in self.list.products) {
            ShoppingTripItem* tripItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingTripItem" inManagedObjectContext:self.managedObjectContext];
            tripItem.product = item.product;
            tripItem.quantity = item.quantity;
            tripItem.purchasedQuantity = item.purchasedQuantity;
            tripItem.bought = item.bought;
            tripItem.date = item.date;
            tripItem.price = item.price;
            tripItem.trip = self.trip;
            tripItem.myPrice = item.price;
        }
        
    //}
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        TripViewController* tripViewController = [[TripViewController alloc] initWithTrip:self.trip andSharedContext:self.managedObjectContext];
        //tripViewController.hidesBottomBarWhenPushed = YES;
        
        /*[UIView transitionWithView:self.navigationController.view
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [self.navigationController pushViewController:tripViewController animated:NO];                        }
                        completion:nil];*/
        [self.navigationController pushViewController:tripViewController animated:NO];
    }

}

- (IBAction)didTapTitle:(id)sender
{
    alert = [[UIAlertView alloc] initWithTitle:@"Rename" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_EDIT_LIST_TITLE;
    UITextField *tf = [alert textFieldAtIndex:0];
    tf.tag = TAG_EDIT_LIST_TITLE;
    [tf setDelegate:self];
    [tf setReturnKeyType:UIReturnKeyDone];
    [tf setText:self.list.name];
    [alert show];
}

- (IBAction)selectListToDuplicate:(id)sender
{
    SelectListViewController *selectListViewController = [[SelectListViewController alloc] initWithLists:self.lists andCurrentList:self.list andSharedContext:self.managedObjectContext];
    
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
        [newItem setPurchasedQuantity:item.purchasedQuantity];
        [newItem setPrice:item.price];
        [newItem setBought:item.bought];
        [newItem setDate:item.date];
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:@"There was an error importing the quotation."
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"Quotation imported");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
    }

}

- (void)updateProductList:(NSNotification *)notification
{
    NSLog(@"Quotation received update");
    self.items = [[self.list.products allObjects] mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [self.items sortUsingDescriptors:@[sortDescriptor]];

    [self.tableView reloadData];
    [self.titleButton setTitle:self.list.name forState:UIControlStateNormal];
    
    if (![self.items count]) {
        self.view = self.emptyView;
    } else {
        self.view = self.normalView;
        
        //self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(editButtonResponder:)];
    }
}

- (void)deleteRowWithPrompt:(NSIndexPath *)indexPath
{
    editingIndexPath = indexPath;
    ShoppingItem* item = [self.items objectAtIndex:[indexPath row]];
    
    NSString* msg = [NSString stringWithFormat:@"Sure to remove %@ from the quotation?", item.product.name];
    
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
    ShoppingItem* item = [self.items objectAtIndex:[indexPath row]];
    [self.managedObjectContext deleteObject:item];
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
                cell.textLabel.text = @"Release to add product";
                break;
            case MOOPullIdle:
                cell.textLabel.text = @"Pull to add product";
                break;
                
        }
    };
    recognizer.triggerView = createView;
    [self.tableView addGestureRecognizer:recognizer];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.swipeHelpView.hidden = YES;
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
    
    ShoppingItem* newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
    [newItem setProduct:nil];
    [newItem setPurchasedQuantity:[NSNumber numberWithInt:1]];
    [newItem setInList:self.list];
    [newItem setDate:[NSDate date]];
    
    [self.items addObject:newItem];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [self.items sortUsingDescriptors:@[sortDescriptor]];

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
    HTAutocompleteTextField* tf = [[HTAutocompleteTextField alloc] initWithFrame:rect];
    tf.autocompleteDataSource = autocompleteManager;

    tf.placeholder = @"Product name";
    tf.delegate = self;
    tf.tag = TAG_NEW_ITEM;
    
    [newCell.contentView addSubview:tf];
    [tf becomeFirstResponder];
    
    [self.tableView removeGestureRecognizer:recognizer];
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
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:CellIdentifier];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        cell.delegate = self;
        
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }

    ShoppingItem *item = [self.items objectAtIndex:[indexPath row]];
    
    cell.firstTrigger = 0.2;
    
    UIView *crossView = [self viewWithImageName:@"cross"];
    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
    
    [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self deleteRowWithPrompt:indexPath];
    }];
    
    
    cell.textLabel.text = item.product.name;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    //if ([item.quantity intValue] > 1) {
    //TODO
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%dx", [item.purchasedQuantity intValue]];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
    //} else {
      //  cell.detailTextLabel.text = @"";
    //}
    
    
    UIView* changeQuantityView = [self viewWithImageName:@"db"];
    UIColor* changeQuantityColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
    
    [cell setSwipeGestureWithView:changeQuantityView color:changeQuantityColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self editQuantityForPath:indexPath];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self renderSwipeHelpView];
}

- (void)editQuantityForPath:(NSIndexPath *)indexPath
{
    ShoppingItem *item = [self.items objectAtIndex:[indexPath row]];
    editingIndexPath = indexPath;
    
    alert = [[UIAlertView alloc] initWithTitle:@"Edit quantity" message:[NSString stringWithFormat:@"Enter the quantity for '%@'", item.product.name] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_EDIT_QUANTITY;
    UITextField *tf = [alert textFieldAtIndex:0];
    tf.tag = TAG_EDIT_QUANTITY;
    [tf setDelegate:self];
    [tf setKeyboardType:UIKeyboardTypeDecimalPad];
    [tf setReturnKeyType:UIReturnKeyDone];
    [tf setPlaceholder:[item.quantity stringValue]];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == TAG_EDIT_QUANTITY) {
        ShoppingItem *editingItem = [self.items objectAtIndex:[editingIndexPath row]];
        float newQuantity = [[[alertView textFieldAtIndex:0] text] floatValue];
        if (buttonIndex > 0 && newQuantity > 0) {
            editingItem.purchasedQuantity = [NSNumber numberWithFloat:newQuantity];
            NSLog(@"Updated quantity for %@", editingItem.product.name);
        }
    } else if (alertView.tag == TAG_EDIT_LIST_TITLE) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            [self.list setName:newName];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
        }
    } else if (alertView.tag == TAG_CONFIRM_DELETE) {
        if (buttonIndex == 0) {
            MCSwipeTableViewCell* cell = (MCSwipeTableViewCell *)[self.tableView cellForRowAtIndexPath:editingIndexPath];
            
            [cell swipeToOriginWithCompletion:^{
                NSLog(@"Swiped back");
            }];
        } else {
            [self deleteRow:editingIndexPath];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
            editingIndexPath = nil;
            return;
        }
    }
    
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
        alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                           message:@"There was an error updating the quotation."
                                          delegate:self
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil];
        [alert show];
    } else {
        NSLog(@"Quotation updated");
        [self.tableView reloadData];
        editingIndexPath = nil;
    }

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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSError *error;
    NSString* txt = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (textField.tag == TAG_NEW_ITEM) {
        ShoppingItem* editingItem = [self.items objectAtIndex:[editingIndexPath row]];
        [textField removeFromSuperview];
        [textField resignFirstResponder];
        
        if ([txt length]) {
            // See if product already exists
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product"
                                                      inManagedObjectContext:self.managedObjectContext];
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", txt];
            [fetchRequest setPredicate:pred];
            [fetchRequest setEntity:entity];
            
            NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            
            // If an object was found, use it in the new item. If not, create it
            if ([fetchedObjects count] > 0) {
                NSLog(@"Product %@ found. Using it...", txt);
                Product *newProduct = [fetchedObjects objectAtIndex:0];
                [editingItem setProduct:newProduct];
                [editingItem setInList:self.list];
                [editingItem setPrice:newProduct.price];
                [editingItem setQuantity:newProduct.stock];
                [editingItem setPurchasedQuantity: [[NSNumber alloc] initWithDouble:1.0]];
                [editingItem setDate:[NSDate date]];
                [editingItem setBought:[[NSNumber alloc] initWithBool:YES]];                
            } else {
                NSLog(@"Product not found.");
                //Product* newProduct = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
                //[newProduct setName:txt];
                //[editingItem setProduct:newProduct];
                
                alert = [[UIAlertView alloc]
                                initWithTitle:@"Unknown product"
                                message:[NSString stringWithFormat:@"Couldn't find '%@', you can only add products that already exist",txt]
                                delegate:self
                                cancelButtonTitle:@"OK"
                                otherButtonTitles:nil, nil];
                [alert show];
                
                [self.managedObjectContext deleteObject:editingItem];
                [self.items removeObject:editingItem];
                [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [self.tableView reloadRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            if (![self.managedObjectContext save:&error]) {
                NSLog(@"Error saving context: %@", [error localizedDescription]);
                [self.managedObjectContext deleteObject:editingItem];
                [self.items removeObject:editingItem];
                [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationTop];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductListDidChangeNotification" object:self];
            }
            
        } else {
            [self.managedObjectContext deleteObject:editingItem];
            [self.items removeObject:editingItem];
            [self.tableView deleteRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationTop];
        }
        
        editingIndexPath = nil;
        [self.tableView addGestureRecognizer:recognizer];
        [self.tableView.pullGestureRecognizer resetPullState];
    } else if (textField.tag == TAG_EDIT_LIST_TITLE && [txt length]) {
        [textField resignFirstResponder];
        [alert dismissWithClickedButtonIndex:1 animated:YES];
    }
    
    return YES;
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

@end
