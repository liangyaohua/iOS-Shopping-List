//
//  ListViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Reviewed by Yaohua Liang on 23/06/14.
//
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "ProductListViewController.h"
#import "Product.h"
#import "ShoppingList.h"
#import "Reachability.h"

@interface ProductListViewController ()
{
    Reachability *internetReachable;
}
@end

@implementation ProductListViewController

- (ProductListViewController *)initWithSharedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        self.managedObjectContext = context;
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateProductList)];
        self.tableView.rowHeight = 50;
        
        [self testInternetConnection];
        
        [self loadProducts];
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProductList) name:@"ProductListDidChangeNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listsDidChange:) name:@"ShoppingListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ShoppingListDidChangeNotification" object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
}

- (void)testInternetConnection
{
    internetReachable = [Reachability reachabilityWithHostname:@"services.odata.org"];
    
    // Internet is reachable
    internetReachable.reachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Service reachable");
        });
    };
    
    // Internet is not reachable
    internetReachable.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Couldn't connect to the service");
        });
    };
    
    [internetReachable startNotifier];
}

- (NSMutableArray*)simpleJsonParsing
{
    //-- Make URL request with server
    NSHTTPURLResponse *response = nil;
    NSString *jsonUrlString = [NSString stringWithFormat:@"http://services.odata.org/V4/Northwind/Northwind.svc/Products?$select=ProductID,ProductName,UnitPrice,UnitsInStock"];
    NSURL *url = [NSURL URLWithString:[jsonUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    //-- Get request and response though URL
    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:url];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    //-- JSON Parsing
    NSMutableArray *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:nil];
    //NSLog(@"Result = %@",result);
    
    NSMutableArray *value = [result valueForKey:@"value"];
    //NSLog(@"Value = %@",value);
    
    return value;
}

- (void)clearProducts
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext: context];
    NSError *error;
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:NO];
    NSArray *oldProducts = [context executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *product in oldProducts) {
        [self.managedObjectContext deleteObject:product];
        //[self.products removeObject:product];
    }
    [self.products removeAllObjects];
    
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error saving context: %@", [error localizedDescription]);
    } else {
        NSLog(@"Products cleared");
    }
}

- (BOOL)productExist:(NSString *) name
{
    NSError *error;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product"
                                              inManagedObjectContext:self.managedObjectContext];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", name];
    [fetchRequest setPredicate:pred];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if ([fetchedObjects count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void)loadProducts
{    
    if (internetReachable.isReachable) {
        //[self clearProducts];
        NSMutableArray *newProducts = [self simpleJsonParsing];
       
        NSError *error;
        
        for (int i = 0; i < [newProducts count]; i++) {
            if (![self productExist:[[newProducts objectAtIndex:i] valueForKey:@"ProductName"]]) {
                Product *item = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
                
                [item setName:[[newProducts objectAtIndex:i] valueForKey:@"ProductName"]];
                [item setPrice:[[newProducts objectAtIndex:i] valueForKey:@"UnitPrice"]];
                [item setStock:[[newProducts objectAtIndex:i] valueForKey:@"UnitsInStock"]];
                [self.products addObject:item];
            }
        }
        
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ProductListDidChangeNotification" object:self];
            NSLog(@"Product updated");
        }
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Products updated" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
    } else {
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext: context];
    
        NSError *error;
    
        [fetchRequest setEntity:entity];
        [fetchRequest setIncludesSubentities:NO];
    
        self.products = [[context executeFetchRequest:fetchRequest error:&error] mutableCopy];
    }
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [self.products sortUsingDescriptors:@[sortDescriptor]];
}

- (void)updateProductList
{
    //if (notification.object != self) {
        [self loadProducts];
        [self.tableView reloadData];
    //NSLog(@"Products updated");
    //}
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
