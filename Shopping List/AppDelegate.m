//
//  AppDelegate.m
//  Shopping List
//
//  Created by Mario Cecchi on 2/6/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "AppDelegate.h"
#import "ProductListViewController.h"
#import "ShoppingListsViewController.h"
#import "Product.h"
#import "ShoppingList.h"
#import "ShoppingItem.h"

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self seedExampleData];
    
    ProductListViewController *productListViewController = [[ProductListViewController alloc] initWithSharedContext:self.managedObjectContext];
    UINavigationController *productListNavigationController = [[UINavigationController alloc] initWithRootViewController:productListViewController];
    productListNavigationController.tabBarItem.image = [UIImage imageNamed:@"product.png"];
    
    ShoppingListsViewController *shoppingListsViewController = [[ShoppingListsViewController alloc] initWithSharedContext:self.managedObjectContext];
    UINavigationController *shoppingListNavigationController = [[UINavigationController alloc] initWithRootViewController:shoppingListsViewController];
    shoppingListNavigationController.tabBarItem.image = [UIImage imageNamed:@"cart.png"];
    
    UITabBarController *tabBarController = [[UITabBarController alloc] init];
    [tabBarController setViewControllers:@[shoppingListNavigationController,productListNavigationController]];
    
    UIColor *orange = [UIColor colorWithRed:1.0 green:0.51 blue:0.0 alpha:1.0];
    
    shoppingListNavigationController.navigationBar.barTintColor =
    productListNavigationController.navigationBar.barTintColor = orange;    shoppingListNavigationController.navigationBar.tintColor =
    productListNavigationController.navigationBar.tintColor = [UIColor whiteColor];
    [shoppingListNavigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    [productListNavigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.tintColor = orange;
    
    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)seedExampleData
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if (![ud boolForKey:@"ShoppingListUserDefaultsExampleData"]) {
        NSLog(@"Application does not have data. Seeding with example data");
        
        NSMutableArray *products = [[NSMutableArray alloc] init];
        Product *coke = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
        [coke setName:@"Coke"];
        [products addObject:coke];
        Product *milk = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
        [milk setName:@"Milk"];
        [products addObject:milk];
        Product *eggs = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
        [eggs setName:@"Eggs"];
        [products addObject:eggs];
        Product *bread = [NSEntityDescription insertNewObjectForEntityForName:@"Product" inManagedObjectContext:self.managedObjectContext];
        [bread setName:@"Bread"];
        [products addObject:bread];
        
        ShoppingList *list = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingList" inManagedObjectContext:self.managedObjectContext];
        [list setName:@"Example list"];
        [list setDate:[NSDate date]];
        
        int i = 1;
        for (Product *p in products) {
            ShoppingItem *item = [NSEntityDescription insertNewObjectForEntityForName:@"ShoppingItem" inManagedObjectContext:self.managedObjectContext];
            [item setProduct:p];
            [item setInList:list];
            [item setQuantity:[NSNumber numberWithInt:i]];
            i++;
        }

        NSError *error;
        if (![self.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@", [error localizedDescription]);
        } else {
            [ud setBool:YES forKey:@"ShoppingListUserDefaultsExampleData"];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Shopping_List" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Shopping_List.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
