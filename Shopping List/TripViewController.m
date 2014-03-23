//
//  TripViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/10/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

// TODO warning when trying to leave view

#import "TripViewController.h"
#import "ShoppingTripItem.h"
#import "ShoppingList.h"
#import "Product.h"

@interface TripViewController ()

@end

@implementation TripViewController

- (id)initWithTrip:(ShoppingTrip *)trip andSharedContext:(NSManagedObjectContext *)context;
{
    self = [self init];
    if (self) {
        self.trip = trip;
        self.managedObjectContext = context;
        
        [self loadItems:self];
        
        self.title = trip.list.name;
        
        self.tableView = [[UITableView alloc] initWithFrame:self.view.frame];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.rowHeight = 50;
        self.tableView.autoresizingMask = AUTORESIZE_ALL;
        [self.view addSubview:self.tableView];
        
        editingIndexPath = nil;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.tableView.frame];
        [backgroundView setBackgroundColor:[UIColor colorWithRed:227.0 / 255.0 green:227.0 / 255.0 blue:227.0 / 255.0 alpha:1.0]];
        [self.tableView setBackgroundView:backgroundView];
        
        blackView = [[UIView alloc] initWithFrame:self.view.frame];
        blackView.backgroundColor = [UIColor blackColor];
        blackView.alpha = 0.0f;
        blackView.autoresizingMask = AUTORESIZE_ALL;
        [self.view addSubview:blackView];
        [self.view bringSubviewToFront:blackView];
        
        [self renderTotalPriceView];
                
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ProductListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList:) name:@"ShoppingListDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadItems:) name:@"SettingsDidChangeNotification" object:nil];

    }
    
    return self;
}

- (void)loadItems:(id)sender
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    NSMutableArray* items;
    self.allItems = [self.trip.items allObjects];
    
    // If auto removal is enabled, filter the list of items first
    if ([ud boolForKey:@"ShoppingListUserDefaultsAutoRemoval"]) {
        items = [[NSMutableArray alloc] init];
        for (ShoppingTripItem* item in self.trip.items) {
            if (![item.bought boolValue])
                [items addObject:item];
        }
    } else {
        items = [self.allItems mutableCopy];
    }
    
    // Sort items
    NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    [items sortUsingDescriptors:@[sortDescriptor]];
    
    self.items = items;
    
    if (sender != self) {
        NSLog(@"Settings were updated, reloading trip");
        [self.tableView reloadData];
    }
}

- (void)renderTotalPriceView
{
    if (totalPriceView == nil) {
        totalPriceView = [[UIView alloc] init];
        int height = 50;
        int y = self.view.frame.size.height - height;
        NSLog(@"y = %d", y);
        totalPriceView.frame = CGRectMake(0,
                                          y,
                                          self.view.frame.size.width,
                                          height);
        totalPriceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        totalPriceView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.8f];
        
        
        totalLabel = [[UILabel alloc] init];
        totalLabel.text = @"Total:";
        totalLabel.font = [UIFont systemFontOfSize:13];
        totalLabel.textColor = [UIColor lightTextColor];
        totalLabel.frame = CGRectMake(5, 0, 50, height);
        [totalPriceView addSubview:totalLabel];
        
        totalPriceLabel = [[UILabel alloc] init];
        totalPriceLabel.font = [UIFont boldSystemFontOfSize:30];
        totalPriceLabel.textAlignment = NSTextAlignmentRight;
        totalPriceLabel.textColor = [UIColor whiteColor];
        totalPriceLabel.frame = CGRectMake(5, 0, self.view.frame.size.width - 10, height);
        [totalPriceView addSubview:totalPriceLabel];
        
        [self updateTotalPriceLabel];

        [self.view addSubview:totalPriceView];
        
        NSLog(@"TotalPriceView added to superview");
    }
}

- (void)updateTotalPriceLabel
{
    float total = 0.0f;
    
    for (ShoppingTripItem* item in self.allItems) {
        if ([item.bought boolValue] == YES)
            total += [item.purchasedQuantity floatValue] * [item.price floatValue];
    }
    
    totalPriceLabel.text = [NSString stringWithFormat:@"£%.2f", total];
    NSLog(@"Total price calculated as %.2f", total);
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
        modalView.autoresizingMask = AUTORESIZE_ALL;
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
        [self.view addSubview:modalView];

    }
    
    CGRect screenSize = self.view.frame;
    modalView.frame = CGRectMake(padding, padding*2, screenSize.size.width - 2*padding, screenSize.size.height - 2*4*padding);
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
                         blackView.alpha = 0.5f;
                     }
                     completion:^(BOOL finished){
                     }];

}

- (void)purchaseViewPurchaseButtonResponder:(id)sender
{
    ShoppingTripItem* item = [self.items objectAtIndex:[editingIndexPath row]];
    item.purchasedQuantity = [NSNumber numberWithInt:[purchasedQuantityTextfield.text intValue]];
    item.bought = (item.purchasedQuantity > 0) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO];
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
    
    [self dismissKeyboard];
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
    
    [self dismissKeyboard];
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
    return [self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1  reuseIdentifier:CellIdentifier];
        
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
        
        cell.contentView.backgroundColor = [UIColor whiteColor];
    }
    
    ShoppingTripItem *item = [self.items objectAtIndex:[indexPath row]];
    
    NSMutableAttributedString *attributeString;
    if (item.product != nil) {
        attributeString = [[NSMutableAttributedString alloc] initWithString:item.product.name];
    } else {
        attributeString = [[NSMutableAttributedString alloc] init];
    }
    
    if (![item.bought boolValue]) {
        cell.textLabel.alpha = 1.0;
        if ([item.quantity intValue] > 1)
            [cell.detailTextLabel setText:[NSString stringWithFormat:@"%dx", [item.quantity intValue]]];
    } else {
        cell.textLabel.alpha = 0.3;
        
        int quant = [item.purchasedQuantity intValue];
        float price = [item.price floatValue];
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d £%.2f", quant, quant*price]];
        
        [attributeString addAttribute:NSStrikethroughStyleAttributeName
                                value:@1
                                range:NSMakeRange(0, [attributeString length])];
    }
    
    cell.textLabel.attributedText = attributeString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    editingIndexPath = indexPath;
    
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
