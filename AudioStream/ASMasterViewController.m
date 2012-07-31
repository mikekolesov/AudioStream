//
//  ASMasterViewController.m
//  AudioStream
//
//  Created by Michael Kolesov on 7/30/12.
//  Copyright (c) 2012 Michael Kolesov. All rights reserved.
//

#import "ASMasterViewController.h"

#import "ASDetailViewController.h"

@interface ASMasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation ASMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Master", @"Master");
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}
							
- (void)dealloc
{
    [_detailViewController release];
    [_objects release];
    [super dealloc];
}

- (void)viewDidLoad
{
    //NSURL *url = [NSURL URLWithString: @"http://91.190.117.131:8000/live"];
    //NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_ogg"];
    
    NSURL *url = [NSURL URLWithString: @"http://online.radiorecord.ru:8100/rr_aac"];
    
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL: url];
    
    //allow background http streaming
    [req setNetworkServiceType:NSURLNetworkServiceTypeVoIP];
    
    //[req addValue: @"1" forHTTPHeaderField: @"Icy-MetaData"];
    
    //[req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    //NSLog( @"request method: %@", [req HTTPMethod]);
    //NSLog( @"request: %@", [req allHTTPHeaderFields]);
    //NSLog( @"request body: %@", [req HTTPBody]);
    //[req setHTTPMethod: @"GET"];
    
    conn = [[NSURLConnection alloc] initWithRequest: req delegate: self];
    if (!conn)
    {
        NSLog( @"Connection failed" );
    }
    else
    {
        NSLog( @"Connection OK" );
    }

    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)] autorelease];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }


    NSDate *object = [_objects objectAtIndex:indexPath.row];
    cell.textLabel.text = [object description];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *object = [_objects objectAtIndex:indexPath.row];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    if (!self.detailViewController) {
	        self.detailViewController = [[[ASDetailViewController alloc] initWithNibName:@"ASDetailViewController_iPhone" bundle:nil] autorelease];
	    }
	    self.detailViewController.detailItem = object;
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        self.detailViewController.detailItem = object;
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog( @"Error: %@", [error localizedDescription] );
    [conn release];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog( @"Response");
    
    NSHTTPURLResponse *http_resp = ( NSHTTPURLResponse *) response;
    NSLog( @"%@", [http_resp allHeaderFields]);
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog( @"Data, %d", [data length] );
    
    /*NSString *html = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
     NSLog( @"%@", html );
     [html release];*/
    
    AudioPartParser([data bytes], [data length]);
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog( @"Finished" );
    [conn release];
}



@end
