//
//  TripViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

// TODO warning when trying to leave view

#import "TripViewController.h"
#import "SelectListViewController.h"
#import "Product.h"
#import "ShoppingItem.h"
#import "ShoppingTripItem.h"

#import "MOOPullGestureRecognizer.h"
#import "MOOCreateView.h"

@interface TripViewController ()

@end

@implementation TripViewController

- (id)initWithTrip:(ShoppingTrip *)trip andSharedContext:(NSManagedObjectContext *)context;
{
    self = [self init];
    if (self) {
        self.trip = trip;
        self.managedObjectContext = context;
        
        NSMutableArray* sortedItems = [[trip.items allObjects] mutableCopy];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
        [sortedItems sortUsingDescriptors:@[sortDescriptor]];
        self.items = sortedItems;
        
        self.title = trip.list.name;
        
        self.tableView.delegate = self;
        self.tableView.rowHeight = 50;
        
        editingIndexPath = nil;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:227.0 / 255.0 green:227.0 / 255.0 blue:227.0 / 255.0 alpha:1.0]];
        [self.tableView setBackgroundView:backgroundView];
        
        blackView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
        blackView.backgroundColor = [UIColor blackColor];
        blackView.alpha = 0.0f;
        [self.view addSubview:blackView];
        [self.view bringSubviewToFront:blackView];
        
        [self renderTotalPriceView];
                
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ShoppingListDidChangeNotification" object:nil];
    }
    
    return self;
}

- (void)renderTotalPriceView
{
    if (totalPriceView == nil) {
        totalPriceView = [[UIView alloc] init];
        totalPriceView.frame = CGRectMake(0, 200, 200, 100);
        totalPriceView.backgroundColor = [UIColor whiteColor];
        
        totalLabel = [[UILabel alloc] init];
        totalLabel.text = @"Total:";
        totalLabel.font = [UIFont systemFontOfSize:13];
        totalLabel.textColor = [UIColor darkGrayColor];
        totalLabel.frame = CGRectMake(0, 0, 200, 20);
        [totalPriceView addSubview:totalLabel];
        
        totalPriceLabel = [[UILabel alloc] init];
        totalPriceLabel.font = [UIFont systemFontOfSize:20];
        totalPriceLabel.textColor = [UIColor blackColor];
        totalPriceLabel.frame = CGRectMake(0, 25, 200, 50);
        [totalPriceView addSubview:totalPriceLabel];
        
        [self updateTotalPriceLabel];

        [self.view.superview addSubview:totalPriceView];
        
        NSLog(@"TotalPriceView added to superview");
    }
}

- (void)updateTotalPriceLabel
{
    float total = 0.0f;
    
    for (ShoppingTripItem* item in self.items) {
        if ([item.bought boolValue] == YES)
            total += [item.purchasedQuantity floatValue] * [item.price floatValue];
    }
    
    totalPriceLabel.text = [NSString stringWithFormat:@"£%.2f", total];
    NSLog(@"Total price calculated as %.2f", total);
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

- (void)renderPurchaseViewForItem:(ShoppingTripItem *)item
{
    int padding = 20;
    
    if (modalView == nil) {
        modalView = [[UIView alloc] init];
        modalView.backgroundColor = [UIColor whiteColor];
        modalView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        modalView.layer.borderWidth = 1.0f;
        modalView.layer.cornerRadius = 5.0f;
        modalView.layer.shadowColor = [[UIColor blackColor] CGColor];
        modalView.layer.shadowOpacity = 0.8f;
        modalView.layer.shadowRadius = 10.0f;
        modalView.layer.shadowOffset = CGSizeMake(0, 0);
        modalView.autoresizesSubviews = YES;
        modalView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
        modalView.alpha = 0.0f;
        
        prodLabel = [[UILabel alloc] init];
        prodLabel.textAlignment = NSTextAlignmentCenter;
        prodLabel.font = [UIFont boldSystemFontOfSize:20];
        [modalView addSubview:prodLabel];
        
        prodLabel2 = [[UILabel alloc] init];
        prodLabel2.text = @"Quantity on list:";
        prodLabel2.font = [UIFont systemFontOfSize:15];
        [modalView addSubview:prodLabel2];
        
        quantityTextfield = [[UITextField alloc] init];
        quantityTextfield.textColor = self.view.superview.tintColor;
        quantityTextfield.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
        quantityTextfield.textAlignment = NSTextAlignmentCenter;
        quantityTextfield.layer.cornerRadius = 5.0f;
        quantityTextfield.enabled = NO;
        [modalView addSubview:quantityTextfield];

        
        prodLabel3 = [[UILabel alloc] init];
        prodLabel3.text = @"Purchased quantity:";
        prodLabel3.font = [UIFont systemFontOfSize:15];
        [modalView addSubview:prodLabel3];
        
        purchasedQuantityTextfield = [[UITextField alloc] init];
        purchasedQuantityTextfield.keyboardType = UIKeyboardTypeDecimalPad;
        purchasedQuantityTextfield.textColor = self.view.superview.tintColor;
        purchasedQuantityTextfield.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
        purchasedQuantityTextfield.textAlignment = NSTextAlignmentCenter;
        purchasedQuantityTextfield.layer.cornerRadius = 5.0f;
        [modalView addSubview:purchasedQuantityTextfield];
        
        prodLabel4 = [[UILabel alloc] init];
        prodLabel4.text = @"Price per unit:";
        prodLabel4.font = [UIFont systemFontOfSize:15];
        [modalView addSubview:prodLabel4];
        
        priceTextField = [[UITextField alloc] init];
        priceTextField.keyboardType = UIKeyboardTypeDecimalPad;
        priceTextField.textColor = self.view.superview.tintColor;
        priceTextField.backgroundColor = [UIColor colorWithWhite:0.98f alpha:1.0f];
        priceTextField.textAlignment = NSTextAlignmentCenter;
        priceTextField.layer.cornerRadius = 5.0f;
        [modalView addSubview:priceTextField];
        
        purchaseButton = [[UIButton alloc] init];
        purchaseButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        purchaseButton.backgroundColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
        purchaseButton.layer.cornerRadius = 5.0f;
        [purchaseButton addTarget:self action:@selector(purchaseViewPurchaseButtonResponder:) forControlEvents:UIControlEventTouchDown];
        [modalView addSubview:purchaseButton];
        
        cancelButton = [[UIButton alloc] init];
        [cancelButton setTitle: @"Cancel" forState:UIControlStateNormal];
        cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        cancelButton.backgroundColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
        cancelButton.layer.cornerRadius = 5.0f;
        [cancelButton addTarget:self action:@selector(purchaseViewCancelButtonResponder:) forControlEvents:UIControlEventTouchDown];

        [modalView addSubview:cancelButton];
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(dismissKeyboard)];
        
        [modalView addGestureRecognizer:tap];
        [self.view.superview addSubview:modalView];

    }
    
    CGRect screenSize = self.view.superview.frame;
    //    modalView.frame = CGRectMake(screenSize.size.width/2, screenSize.size.height/2, 1, 1);
    modalView.frame = CGRectMake(padding, padding*6, screenSize.size.width - 2*padding, screenSize.size.height - 2*6*padding);
    prodLabel.frame = CGRectMake(0, 5, screenSize.size.width - 2*padding, 50);
    prodLabel2.frame = CGRectMake(padding, 60, screenSize.size.width - 4*padding, 30);
    quantityTextfield.frame = CGRectMake(180, 60, 75, 30);
    prodLabel3.frame = CGRectMake(padding, 95, screenSize.size.width - 4*padding, 30);
    purchasedQuantityTextfield.frame = CGRectMake(180, 95, 75, 30);
    prodLabel4.frame = CGRectMake(padding, 130, screenSize.size.width - 4*padding, 30);
    priceTextField.frame = CGRectMake(180, 130, 75, 30);
    
    if ([[UIDevice currentDevice] orientation] == UIInterfaceOrientationPortrait) {
        purchaseButton.frame = CGRectMake(padding + 10, 200, screenSize.size.width - 4*padding - 2*10, 50);
        cancelButton.frame = CGRectMake(padding + 10, 255, screenSize.size.width - 4*padding - 2*10, 35);
    } else {
        purchaseButton.frame = CGRectMake(modalView.frame.size.width/2, 50, screenSize.size.width - 4*padding - 2*10, 50);
        cancelButton.frame = CGRectMake(modalView.frame.size.width/2, 105, screenSize.size.width - 4*padding - 2*10, 35);
    }
    
    prodLabel.text = item.product.name;
    quantityTextfield.text = [NSString stringWithFormat:@"%d", [item.quantity intValue]];
    purchasedQuantityTextfield.text = [NSString stringWithFormat:@"%d", [item.purchasedQuantity intValue]];
    priceTextField.text = [NSString stringWithFormat:@"%.2f", [item.price floatValue]];
    [purchaseButton setTitle: ((![item.bought boolValue]) ? @"Purchase" : @"Update") forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         modalView.alpha = 1.0f;
                         blackView.alpha = 0.8f;
                     }
                     completion:^(BOOL finished){
                     }];

}

- (void)purchaseViewPurchaseButtonResponder:(id)sender
{
    ShoppingTripItem* item = [self.items objectAtIndex:[editingIndexPath row]];
    item.purchasedQuantity = [NSNumber numberWithInt:[purchasedQuantityTextfield.text intValue]];
    item.bought = [NSNumber numberWithBool:YES];
    item.price = [NSNumber numberWithFloat:[priceTextField.text floatValue]];
    
    NSError* error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             modalView.alpha = 0.0f;
                             blackView.alpha = 0.0f;
                         }
                         completion:^(BOOL finished){
                         }];
        
        [self.tableView reloadRowsAtIndexPaths:@[editingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateTotalPriceLabel];
        editingIndexPath = nil;
        

    }
}

- (void)purchaseViewCancelButtonResponder:(id)sender
{
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         modalView.alpha = 0.0f;
                         blackView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)updateProductList:(NSNotification *)notification
{
    NSMutableArray* sortedItems = [[self.trip.items allObjects] mutableCopy];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [sortedItems sortUsingDescriptors:@[sortDescriptor]];
    self.items = sortedItems;
    
    [self.tableView reloadData];
    
    self.title = self.trip.list.name;
}

- (void)toggleRowPurchased:(NSIndexPath *)indexPath
{
    ShoppingItem* item = [self.items objectAtIndex:[indexPath row]];
    
    item.bought = [NSNumber numberWithBool:![item.bought boolValue]];
    
    
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

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.swipeHelpView.hidden = YES;
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
        
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        cell.delegate = self;
        
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    ShoppingTripItem *item = [self.items objectAtIndex:[indexPath row]];
    
    NSMutableAttributedString *attributeString;
    if (item.product != nil) {
        attributeString = [[NSMutableAttributedString alloc] initWithString:item.product.name];
    } else {
        attributeString = [[NSMutableAttributedString alloc] init];
    }
    
    UIView *purchaseView = nil;
    UIColor *purchaseColor = nil;
    cell.firstTrigger = 0.2;
    
    [cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    if (![item.bought boolValue]) {
        cell.textLabel.alpha = 1.0;
        purchaseView = [self viewWithImageName:@"addToCart"];
        purchaseColor = [UIColor colorWithRed:85.0 / 255.0 green:213.0 / 255.0 blue:80.0 / 255.0 alpha:1.0];
        
        if ([item.quantity intValue] > 1)
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%dx", [item.quantity intValue]]];
    } else {
        cell.textLabel.alpha = 0.3;
        purchaseView = [self viewWithImageName:@"removeFromCart"];
        purchaseColor = [UIColor colorWithRed:254.0 / 255.0 green:217.0 / 255.0 blue:56.0 / 255.0 alpha:1.0];
        
        int quant = [item.purchasedQuantity intValue];
        float price = [item.price floatValue];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d £%.2f", quant, quant*price]];
        
        [attributeString addAttribute:NSStrikethroughStyleAttributeName
                                value:@1
                                range:NSMakeRange(0, [attributeString length])];
    }
    
    cell.textLabel.attributedText = attributeString;
    
    [cell setSwipeGestureWithView:purchaseView color:purchaseColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self toggleRowPurchased:indexPath];
    }];
    
    return cell;
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    editingIndexPath = indexPath;
    
    // Animate table
//    [self.tableView reloadData];
//    [self.tableView beginUpdates];
//    [self.tableView endUpdates];
    
    ShoppingTripItem *item = [self.items objectAtIndex:[indexPath row]];
    [self renderPurchaseViewForItem:item];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        ShoppingItem *editingItem = [self.items objectAtIndex:[editingIndexPath row]];
        float newQuantity = [[[alertView textFieldAtIndex:0] text] floatValue];
        if (buttonIndex > 0 && newQuantity > 0) {
            editingItem.quantity = [NSNumber numberWithFloat:newQuantity];
        }
    } else if (alertView.tag == 2) {
        NSString *newName = [[alertView textFieldAtIndex:0] text];
        if (buttonIndex > 0 && [newName length] > 0) {
            [self.trip.list setName:newName];
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

- (void)dismissKeyboard {
    [purchasedQuantityTextfield resignFirstResponder];
    [priceTextField resignFirstResponder];
}

@end