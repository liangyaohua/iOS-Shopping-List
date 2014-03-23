//
//  HTAutocompleteManager.m
//  HotelTonight
//
//  Created by Jonathan Sibley on 12/6/12.
//  Copyright (c) 2012 Hotel Tonight. All rights reserved.
//

#import "ProductHTAutocompleteManager.h"
#import "Product.h"

@implementation ProductHTAutocompleteManager

- (id)initWithSharedContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        self.managedObjectContext = context;
        
        [self loadProducts:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadProducts:) name:@"ProductListDidChangeNotification" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ProductListDidChangeNotification" object:nil];
}

- (void)loadProducts:(id)sender
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Product" inManagedObjectContext:context];
    NSError *error;
    
    [fetchRequest setEntity:entity];
    [fetchRequest setIncludesSubentities:NO];
    
    self.products = [context executeFetchRequest:fetchRequest error:&error];
}

#pragma mark - HTAutocompleteTextFieldDelegate

- (NSString *)textField:(HTAutocompleteTextField *)textField
    completionForPrefix:(NSString *)prefix
             ignoreCase:(BOOL)ignoreCase
{
    NSString *stringToLookFor = [prefix lowercaseString];

    for (Product* p in self.products) {
        NSString* stringFromReference = p.name;
        NSString* stringToCompare;
        
        if (ignoreCase) {
            stringToCompare = [stringFromReference lowercaseString];
        }
        else {
            stringToCompare = stringFromReference;
        }
        
        if ([stringToCompare hasPrefix:stringToLookFor]) {
            return [stringFromReference stringByReplacingCharactersInRange:[stringToCompare rangeOfString:stringToLookFor] withString:@""];
        }
        
    }
    
    return @"";
}

@end
