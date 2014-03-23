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

#define TAG_NEW_ITEM 1
#define TAG_EDIT_QUANTITY 2

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
        self.items = [[list.products allObjects] mutableCopy];
        
        self.title = list.name;
        self.titleButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.titleButton setTitle:list.name forState:UIControlStateNormal];
        [self.titleButton.titleLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [self.titleButton addTarget:self action:@selector(didTapTitle:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = self.titleButton;
        
        self.tableView.delegate = self;
        self.tableView.rowHeight = 50;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:227.0 / 255.0 green:227.0 / 255.0 blue:227.0 / 255.0 alpha:1.0]];
        [self.tableView setBackgroundView:backgroundView];
        [self renderEmptyView];
        
        if (![self.items count]) {
            self.view = self.emptyView;
        } else {
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
            [self.items sortUsingDescriptors:@[sortDescriptor]];
            // TODO correct barbuttonitem
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(startShoppingTrip:)];
//            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[self viewWithImageName:@"cart"]];
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
    emptyListLabel.text = @"This shopping list is empty";
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
    infoLabel.text = @"Add items to the list or import an existing list.";
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
    [addItemsButton setTitle:@"Add items to list" forState:UIControlStateNormal];
    [addItemsButton addTarget:self action:@selector(editButtonResponder:) forControlEvents:UIControlEventTouchDown];
    
    UIButton *duplicateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    duplicateButton.frame = CGRectMake(0, 340, self.tableView.frame.size.width, 30);
    duplicateButton.autoresizingMask = emptyListLabel.autoresizingMask;
    [duplicateButton setTitle:@"Import existing list" forState:UIControlStateNormal];
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
        helpView.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1.0f];
        helpView.layer.borderColor = [[UIColor colorWithWhite:0.9f alpha:1.0f] CGColor];
        helpView.layer.borderWidth = 1.0f;
        
        self.swipeHelpViewLabel = [[UILabel alloc] init];
        UILabel* helpText = self.swipeHelpViewLabel;
        helpText.text = @"Swipe right to (un)mark items as purchased";
        helpText.textAlignment = NSTextAlignmentCenter;
        helpText.numberOfLines = 0;
        helpText.lineBreakMode = NSLineBreakByWordWrapping;
        helpText.font = [UIFont systemFontOfSize:12];
        [helpView addSubview:helpText];
        
        [self.view.superview addSubview:helpView];
        

    }
    
    int paddingY = 35;
    int width = self.view.superview.frame.size.width;
    int height = 50;
    int y = CGRectGetMaxY(self.view.frame) - height - paddingY - 15;
    
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
//    NSLog(@"Showing help view");
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
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ShoppingTrip"
                                              inManagedObjectContext:self.managedObjectContext];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"list == %@", self.list];
    [fetchRequest setPredicate:pred];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    ShoppingTrip *trip = nil;
    // If a object was found, use it in the new item. If not, create it
    if ([fetchedObjects count] > 0) {
        NSLog(@"Shopping Trip already found. Using it...");
        trip = [fetchedObjects objectAtIndex:0];
    } else {
        NSLog(@"Shopping trip not found. Creating...");
        
        trip = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingTrip" inManagedObjectContext:self.managedObjectContext];
        trip.list = self.list;
        trip.date = [NSDate date];
        
        for (ShoppingItem* item in self.list.products) {
            ShoppingTripItem* tripItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingTripItem" inManagedObjectContext:self.managedObjectContext];
            tripItem.product = item.product;
            tripItem.quantity = item.quantity;
            tripItem.purchasedQuantity = item.quantity;
            tripItem.bought = NO;
            tripItem.date = item.date;
            tripItem.price = [NSNumber numberWithFloat:0.0f];
            tripItem.trip = trip;
        }
        
    }
    
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        TripViewController* tripViewController = [[TripViewController alloc] initWithTrip:trip andSharedContext:self.managedObjectContext];
        tripViewController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:tripViewController animated:YES];
    }

}

- (IBAction)didTapTitle:(id)sender
{
//    NSLog(@"Did tap on title");
    
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
    self.items = [[self.list.products allObjects] mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [self.items sortUsingDescriptors:@[sortDescriptor]];

    [self.tableView reloadData];
    [self.titleButton setTitle:self.list.name forState:UIControlStateNormal];
    
    if (![self.items count]) {
        self.view = self.emptyView;
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        self.view = self.tableView;
        
        // TODO correct barbuttonitem
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(startShoppingTrip:)];
    }
}

- (void)toggleRowPurchased:(NSIndexPath *)indexPath
{
//    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
    ShoppingItem* item = [self.items objectAtIndex:[indexPath row]];
    
    item.bought = [NSNumber numberWithBool:![item.bought boolValue]];
    
//    if ([item.bought boolValue]) {
//        item.bought = [NSNumber numberWithBool:NO];
//        [cell setAccessoryType:UITableViewCellAccessoryNone];
//        cell.textLabel.alpha = 1.0;
//    } else {
//        item.bought = [NSNumber numberWithBool:YES];
//        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
//        cell.textLabel.alpha = 0.3;
//    }
    
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
    }
}

- (void)deleteRowWithPrompt:(NSIndexPath *)indexPath
{
    editingIndexPath = indexPath;
    ShoppingItem* item = [self.items objectAtIndex:[indexPath row]];
    
    NSString* msg = [NSString stringWithFormat:@"Are you sure your want to remove %@ from the list?", item.product.name];
    
    alert = [[UIAlertView alloc] initWithTitle:@"Delete?"
                                                        message:msg
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
    alert.tag = 3;
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
                cell.textLabel.text = @"Release to add item";
                break;
            case MOOPullIdle:
                cell.textLabel.text = @"Pull to add item";
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
//    NSLog(@"New offset: %f", contentOffset.y);
    
    ShoppingItem* newItem = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
    [newItem setProduct:nil];
    [newItem setQuantity:[NSNumber numberWithInt:1]];
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
    UITextField* tf = [[UITextField alloc] initWithFrame:rect];
    
    tf.placeholder = @"Product name";
    tf.delegate = self;
    tf.tag = 5;
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
    
    NSMutableAttributedString *attributeString;
    if (item.product != nil) {
        attributeString = [[NSMutableAttributedString alloc] initWithString:item.product.name];
    } else {
        attributeString = [[NSMutableAttributedString alloc] init];
    }
    
//    UIView *purchaseView = nil;
//    UIColor *purchaseColor = nil;
    cell.firstTrigger = 0.2;
    
    UIView *crossView = [self viewWithImageName:@"cross"];
    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
    
    [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self deleteRowWithPrompt:indexPath];
    }];
    
    
    if ([item.quantity intValue] > 1)
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%dx", [item.quantity intValue]]];
    
//    
//    if (![item.bought boolValue]) {
////        [cell setAccessoryType:UITableViewCellAccessoryNone];
//        cell.textLabel.alpha = 1.0;
//        purchaseView = [self viewWithImageName:@"addToCart"];
//        purchaseColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
//    } else {
////        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
//        cell.textLabel.alpha = 0.3;
//        purchaseView = [self viewWithImageName:@"removeFromCart"];
//        purchaseColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
//    
//        
//        [attributeString addAttribute:NSStrikethroughStyleAttributeName
//                                value:@1
//                                range:NSMakeRange(0, [attributeString length])];
//    }
//    
    cell.textLabel.attributedText = attributeString;
    
    UIView* changeQuantityView = [self viewWithImageName:@"db"];
    UIColor* changeQuantityColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
    
    [cell setSwipeGestureWithView:changeQuantityView color:changeQuantityColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        // TODO
        NSLog(@"Swiped to change quantity");
        [self editQuantityForPath:indexPath];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    [self renderSwipeHelpView];
}

- (void)editQuantityForPath:(NSIndexPath *)indexPath
{
    ShoppingItem *item = [self.items objectAtIndex:[indexPath row]];
    editingIndexPath = indexPath;
    
    alert = [[UIAlertView alloc] initWithTitle:@"Edit amount" message:[NSString stringWithFormat:@"Enter the quantity for '%@'", item.product.name] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Update", nil];
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
        ShoppingItem *editingItem = [[self.list.products allObjects] objectAtIndex:[editingIndexPath row]];
        float newQuantity = [[[alertView textFieldAtIndex:0] text] floatValue];
        if (buttonIndex > 0 && newQuantity > 0) {
            editingItem.quantity = [NSNumber numberWithFloat:newQuantity];
            NSLog(@"Updated quantity for item %@", editingItem.product.name);
        }
    } else if (alertView.tag == 2) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            [self.list setName:newName];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ShoppingListDidChangeNotification" object:self];
        }
    } else if (alertView.tag == 3) {
        if (buttonIndex == 0) {
            MCSwipeTableViewCell* cell = (MCSwipeTableViewCell *)[self.tableView cellForRowAtIndexPath:editingIndexPath];
            
            [cell swipeToOriginWithCompletion:^{
                NSLog(@"Swiped back");
            }];
        } else {
            [self deleteRow:editingIndexPath];
            editingIndexPath = nil;
            return;
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



#pragma mark - UITextFieldDelegate methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.tag == 5) { // New item textfield
        //        NSLog(@"New item tf editing, new string: %@", string);
        //        [autocompleteTableView.delegate updateEntriesWithSubstring:string];
        //        [autocompleteTableView updateEntriesWithSubstring:string];
        //        [autocompleteTableView reloadData];
    }
    return YES;
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
    NSString* txt = textField.text;
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
        
        // If a object was found, use it in the new item. If not, create it
        if ([fetchedObjects count] > 0) {
            NSLog(@"Product %@ found. Using it...", txt);
            [editingItem setProduct:[fetchedObjects objectAtIndex:0]];
        } else {
            NSLog(@"Product not found. Creating %@...", txt);
            Product* newProduct = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
            [newProduct setName:txt];
            [editingItem setProduct:newProduct];
        }
        
        [self.tableView reloadRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        
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
    return YES;
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

@end
