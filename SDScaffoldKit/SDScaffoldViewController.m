//
//  SDScaffoldViewController.m
//  SDScaffoldKit
//
//  Created by Steve Derico on 12/18/12.
//  Copyright (c) 2012 Bixby Apps. All rights reserved.
//
#import "SDScaffoldShowViewController.h"
#import "SDScaffoldAddViewController.h"
#import "SDScaffoldViewController.h"

@interface SDScaffoldViewController () <NSFetchedResultsControllerDelegate>{
    NSString *_sortPropertyName;
}
@property (nonatomic,strong) NSFetchedResultsController *fetchedResultsController;
- (void)showAddViewController;
@end

@implementation SDScaffoldViewController
@synthesize entityName = _entityName;
@synthesize isEditable = _isEditable;
@synthesize isDeletable = _isDeletable;
@synthesize isViewable = _isViewable;
@synthesize isCreatable = _isCreatable;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;

- (id)initWithEntityName:(NSString*)entityName sortBy:(NSString*)sortPropertyName context:(NSManagedObjectContext*)managedObjectContext andStyle:(UITableViewStyle)style{
    self = [super initWithStyle:style];
    if (self) {
        //Setup Properties
        self.isDeletable = YES;
        self.isEditable = YES;
        self.isViewable = YES;
        self.isCreatable = YES;
        self.entityName = entityName;
        self.managedObjectContext = managedObjectContext;
        self.title = [NSString stringWithFormat:@"%@s",self.entityName];
        
        
        //Setup Instance Variables
        _sortPropertyName = sortPropertyName;

        [self refreshData];
    }
    return self;
}

- (id)initWithEntityName:(NSString*)entityName sortBy:(NSString*)propertyName context:(NSManagedObjectContext*)managedObjectContext {
    
    //Call Designated Initializer with Grouped Style
    self = [self initWithEntityName:entityName sortBy:propertyName context:managedObjectContext andStyle:UITableViewStyleGrouped];
    
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    //Add add button
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddViewController)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    //If Creatable Property is off, remove button
    if (self.isCreatable == NO) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    //Pulls Data out of DB and refreshed TableView
    [self refreshData];
    
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [[[_fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //Create Cell Identifer
    static NSString *CellIdentifier = @"Cell";
    
    //Try to Deqeue Cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    //If no dequeued cells, then create one with cell Identifer
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
    
    //Configure the Cell
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath{
    
    //Locate Object for given row
    NSManagedObject *managedObject = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    //Set the cell's textLabel text to the value of the property used for sorting.
    cell.textLabel.text = [[managedObject valueForKey:_sortPropertyName] description];
    
    //Check if the viewable property is turned off, if so disallow selection from index
    if (self.isViewable == NO) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return;
    }else{
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //If it viewable is disabled then just deselect the cell when it is tapped
    if (self.isViewable == NO) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    //Created a showViewController and set it's properties from the index's properties
    SDScaffoldShowViewController *showVC = [[SDScaffoldShowViewController alloc] initWithEntity:[_fetchedResultsController objectAtIndexPath:indexPath] context:self.managedObjectContext];
    
    //Passing Property Values to next ViewController
    showVC.isDeletable = self.isDeletable;
    showVC.isEditable = self.isEditable;
    showVC.entityName = self.entityName;
    
    //Push new ShowViewController
    [self.navigationController pushViewController:showVC animated:YES];

}


#pragma SDScaffoldViewController

- (void)showAddViewController{
    
    //Create new addViewController
    SDScaffoldAddViewController *addVC = [[SDScaffoldAddViewController alloc]initWithEntityName:self.entityName context:self.managedObjectContext];
    
    //Push new addViewController
    [self.navigationController pushViewController:addVC animated:YES];
}

- (void)refreshData{
    
    //Create Fetch Request with Entity Provided
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.entityName];
    
    //Add Sort-By Property
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:_sortPropertyName ascending:YES]];
    
    //Create FetchResults Controller with FetchRequest
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    //Assign Delegate
    _fetchedResultsController.delegate = self;
    
    //Execute Fetch
    [_fetchedResultsController performFetch:nil];
    
    //Refresh Data
    [self.tableView reloadData];
    
}

@end