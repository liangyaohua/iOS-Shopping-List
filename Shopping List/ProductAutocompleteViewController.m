//
//  ProductAutocompleteViewController.m
//  Shopping List
//
//  Created by Mario Cecchi on 3/5/14.
//  Copyright (c) 2014 Mario Cecchi. All rights reserved.
//

#import "ProductAutocompleteViewController.h"
#import "Product.h"


@interface ProductAutocompleteViewController ()

@end

@implementation ProductAutocompleteViewController

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the Autocomplete class"
                                 userInfo:nil];
    return nil;
}

- (id)initWithProductList:(NSArray *)itemsList
{
    self = [super init];
    if (self) {
        products = itemsList;
        matchedProducts = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)updateEntriesWithSubstring:(NSString *)newSubstring
{
    substring = newSubstring;
    
    NSLog(@"AutocompleteController received new substring %@", substring);
    
    [matchedProducts removeAllObjects];
    for (Product *p in products) {
        NSRange substringRange = [p.name rangeOfString:substring];
        if (substringRange.location == 0) {
            [matchedProducts addObject:p];
        }
    }
    
    NSLog(@"Autocomplete matched %lu products", [matchedProducts count]);
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [matchedProducts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell Identifier";
    
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Product *p = [matchedProducts objectAtIndex:[indexPath row]];
    [cell.textLabel setText:p.name];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end

@implementation ProductAutocompleteTableView
- (void)updateEntriesWithSubstring:(NSString *)newSubstring
{
//    [self.delegate updateEntriesWithSubstring:newSubstring];
    
    [NSTimer scheduledTimerWithTimeInterval:3.0 target:self.delegate
                                   selector:@selector(updateEntriesWithSubstring:) userInfo:newSubstring repeats:NO];
}

@end
