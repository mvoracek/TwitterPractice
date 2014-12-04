//
//  ViewController.m
//  TwitterPractice
//
//  Created by Matthew Voracek on 12/1/14.
//  Copyright (c) 2014 Matthew Voracek. All rights reserved.
//

#import "ViewController.h"
#import "STTwitter.h"
#import "TableViewCell.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, strong) NSMutableArray *tweets;
@property BOOL clearData;

@end

static NSString *TWITTER_CONSUMER_KEY = @"fx95oKhMHYgytSBmiAqQ";
static NSString *TWITTER_CONSUMER_SEC = @"0zfaijLMWMYTwVosdqFTL3k58JhRjZNxd2q0i9cltls";
static NSString *OAUTH_TOKEN = @"2305278770-GGw8dQQg3o5Vqfx9xHpUgJ0CDUe3BoNmUNeWZBg";
static NSString *OAUTH_SECRET = @"iEzxeJjEPnyODVcoDYt5MVvrg90Jx2TOetGdNeol6PeYp";

static NSString *Latitude = @"41.8369";
static NSString *Longitude = @"-87.6847";
static NSString *Range = @"5mi";

static NSString *const CellID = @"SearchResults";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tweets = [NSMutableArray array];
}

- (void)searchResultsFromValue:(NSString *)value
{
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWITTER_CONSUMER_KEY
                                                 consumerSecret:TWITTER_CONSUMER_SEC
                                                     oauthToken:OAUTH_TOKEN
                                               oauthTokenSecret:OAUTH_SECRET];
    
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        NSString *geo = [NSString stringWithFormat:@"%@,%@,%@", Latitude, Longitude, Range];
        
        [self.twitter getSearchTweetsWithQuery:value geocode:geo lang:nil locale:nil resultType:nil count:@"100" until:nil sinceID:nil maxID:nil includeEntities:nil callback:nil successBlock:^(NSDictionary *searchMetadata, NSArray *statuses) {
            NSLog(@"%@", statuses);
            [self.tweets addObjectsFromArray:statuses];
            [self refreshTableView];
            
        } errorBlock:^(NSError *error) {
            NSLog(@"%@", error.debugDescription);
        }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error.debugDescription);
    }];
}

- (void)refreshTableView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (NSString *)formatTweetDateFromJSON:(NSString *)tweetDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    NSDate *userPostDate = [df dateFromString:tweetDate];
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval distanceBetweenDates = [currentDate timeIntervalSinceDate:userPostDate];
    
    NSTimeInterval theTimeInterval = distanceBetweenDates;
    
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Create the NSDates
    NSDate *date1 = [[NSDate alloc] init];
    NSDate *date2 = [[NSDate alloc] initWithTimeInterval:theTimeInterval sinceDate:date1];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitSecond;
    
    NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:date1  toDate:date2  options:0];
    
    NSString *returnDate;
    if ([conversionInfo month] > 0) {
        returnDate = [NSString stringWithFormat:@"%ldmth",(long)[conversionInfo month]];
    } else if ([conversionInfo day] > 0) {
        returnDate = [NSString stringWithFormat:@"%ldd",(long)[conversionInfo day]];
    } else if ([conversionInfo hour] > 0) {
        returnDate = [NSString stringWithFormat:@"%ldh",(long)[conversionInfo hour]];
    } else if ([conversionInfo minute] > 0) {
        returnDate = [NSString stringWithFormat:@"%ldm",(long)[conversionInfo minute]];
    } else {
        returnDate = [NSString stringWithFormat:@"%lds",(long)[conversionInfo second]];
    }
    return returnDate;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [textField becomeFirstResponder];
    [textField setText:@""];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.clearData = YES;
    [self.tableView reloadData];
    [self.tweets removeAllObjects];
    self.clearData = NO;
    NSString *searchValue = textField.text;
    [self searchResultsFromValue:searchValue];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Table View

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID forIndexPath:indexPath];
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    
    //placeholder image
    //cell.userImage.image = [UIImage imageNamed:@"default"];
    
    NSString *screenName = tweetDict[@"user"][@"screen_name"];
    NSString *tweetDate = [self formatTweetDateFromJSON:tweetDict[@"created_at"]];
    
    cell.placeLabel.text = tweetDict[@"place"][@"full_name"];
    cell.timeLabel.text = tweetDate;
    cell.screenImage.text = screenName;
    cell.tweetText.text = tweetDict[@"text"];
    cell.tweetText.numberOfLines = 0;
    [cell.tweetText sizeToFit];
    
    [self.twitter profileImageFor:screenName successBlock:^(id image) {
        cell.userImage.image = image;
    } errorBlock:^(NSError *error) {
        //error handling
    }];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.clearData) {
        return 0;
    }
    return [self.tweets count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 160.0;
}

@end
