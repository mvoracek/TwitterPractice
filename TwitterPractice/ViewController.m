//
//  ViewController.m
//  TwitterPractice
//
//  Created by Matthew Voracek on 12/1/14.
//  Copyright (c) 2014 Matthew Voracek. All rights reserved.
//

#import "ViewController.h"
#import "TweetReplyViewController.h"
#import "STTwitter.h"
#import "TableViewCell.h"
#import "TableViewCellWithImage.h"
#import <CoreLocation/CoreLocation.h>

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (nonatomic, strong) TableViewCell *prototypeCell;
@property  UIRefreshControl *refreshControl;
@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, strong) NSMutableArray *tweets;
@property (nonatomic, strong) NSString *searchValue;
@property (nonatomic, strong) NSString *maxID;
@property BOOL clearData;

@end

static NSString *TWITTER_CONSUMER_KEY = @"fx95oKhMHYgytSBmiAqQ";
static NSString *TWITTER_CONSUMER_SEC = @"0zfaijLMWMYTwVosdqFTL3k58JhRjZNxd2q0i9cltls";
static NSString *OAUTH_TOKEN = @"2305278770-GGw8dQQg3o5Vqfx9xHpUgJ0CDUe3BoNmUNeWZBg";
static NSString *OAUTH_SECRET = @"iEzxeJjEPnyODVcoDYt5MVvrg90Jx2TOetGdNeol6PeYp";

static NSString *Latitude = @"41.879778";
static NSString *Longitude = @"-87.62855";
static NSString *Range = @"5mi";

static NSString *const CellID = @"SearchResults";
static NSString *const CellIDForImage = @"SearchResultsWithImage";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tweets = [NSMutableArray array];
    self.searchValue = [[NSString alloc] init];
    self.maxID = [[NSString alloc] init];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshByControl) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (void)searchResultsFromValue:(NSString *)value
{
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWITTER_CONSUMER_KEY
                                                 consumerSecret:TWITTER_CONSUMER_SEC
                                                     oauthToken:OAUTH_TOKEN
                                               oauthTokenSecret:OAUTH_SECRET];
    
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        NSString *geo = [NSString stringWithFormat:@"%@,%@,%@", Latitude, Longitude, Range];
        
        [self.twitter getSearchTweetsWithQuery:value
                                       geocode:geo
                                          lang:nil
                                        locale:nil
                                    resultType:nil
                                         count:@"100"
                                         until:nil
                                       sinceID:nil
                                         maxID:self.maxID
                               includeEntities:@1
                                      callback:nil
                                  successBlock:^(NSDictionary *searchMetadata, NSArray *statuses) {
                                      NSLog(@"%@", statuses);
                                      NSLog(@"%@", searchMetadata);
                                      [self.tweets addObjectsFromArray:statuses];
                                      NSDictionary *lastTweet = [statuses lastObject];
                                      NSLog(@"%@", lastTweet);
                                      NSString *lastTweetID = lastTweet[@"id_str"];
                                      long lastTweetIDMinusOne = [lastTweetID longLongValue] - 1;
                                      self.maxID = [NSString stringWithFormat:@"%ld", lastTweetIDMinusOne];
                                      [self.tableView reloadData];
                                  }
                                    errorBlock:^(NSError *error) {
                                        NSLog(@"%@", error.debugDescription);
                                    }];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error.debugDescription);
    }];
}

- (void)refreshByControl
{
    [self refreshTable];
    [self.refreshControl endRefreshing];
}

- (void)refreshTable
{
    self.clearData = YES;
    [self.tableView reloadData];
    [self.tweets removeAllObjects];
    self.maxID = nil;
    self.clearData = NO;
    [self searchResultsFromValue:self.searchValue];
}


- (NSString *)formatTweetDateFromJSON:(NSString *)tweetDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    NSDate *userPostDate = [df dateFromString:tweetDate];
    
    NSDate *currentDate = [NSDate date];
    NSTimeInterval distanceBetweenDates = [currentDate timeIntervalSinceDate:userPostDate];
    
    NSTimeInterval theTimeInterval = distanceBetweenDates;
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
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

- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, UIImage *image))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (!error)
                               {
                                   UIImage *image = [[UIImage alloc] initWithData:data];
                                   completionBlock(YES,image);
                               } else{
                                   completionBlock(NO,nil);
                               }
                           }];
}

-(void)scrollViewDidScroll: (UIScrollView*)scrollView
{
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;
    
    if (scrollOffset + scrollViewHeight == scrollContentSizeHeight)
    {
        [self searchResultsFromValue:self.searchValue];
    }
}

- (IBAction)replyButtonPressed:(id)sender
{
    TableViewCell *clickedCell = (TableViewCell *)[[sender superview] superview];
    NSIndexPath *clickedButtonPath = [self.tableView indexPathForCell:clickedCell];
    
    NSDictionary *tweetDict = self.tweets[clickedButtonPath.row];
    
    TweetReplyViewController *viewController = [[TweetReplyViewController alloc] initWithNibName:nil bundle:nil];
    viewController.tweetDictionary = tweetDict;
    [self presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - Text Field

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [textField becomeFirstResponder];
    [textField setText:@""];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.searchValue = textField.text;
    [self refreshTable];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Table View

- (TableViewCell *)BasicCellAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellID forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (TableViewCellWithImage *)ImageCellAtIndexPath:(NSIndexPath *)indexPath
{
    TableViewCellWithImage *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIDForImage forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    [self configureImageCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(TableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    
    NSString *screenName = tweetDict[@"user"][@"screen_name"];
    NSString *tweetText = tweetDict[@"text"];
    NSString *formattedTweetText = [tweetText stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    NSString *tweetDate = [self formatTweetDateFromJSON:tweetDict[@"created_at"]];
    NSURL *profileImageURL = [NSURL URLWithString:tweetDict[@"user"][@"profile_image_url_https"]];
    
    cell.placeLabel.text = tweetDict[@"place"][@"full_name"];
    cell.timeLabel.text = tweetDate;
    cell.screenImage.text = screenName;
    cell.tweetText.text = formattedTweetText;
    cell.tweetText.numberOfLines = 0;
    [cell.tweetText sizeToFit];
    cell.tweetText.preferredMaxLayoutWidth = CGRectGetWidth(self.tableView.bounds);
    cell.userImage.image = nil;
    
    [self downloadImageWithURL:profileImageURL completionBlock:^(BOOL succeeded, UIImage *image) {
        if (succeeded) {
            cell.userImage.image = image;
            CALayer *userImageLayer = [cell.userImage layer];
            [userImageLayer setMasksToBounds:YES];
            [userImageLayer setCornerRadius:10.0];
        } else {
            //error handling
        }
    }];
}

- (void)configureImageCell:(TableViewCellWithImage *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.inlineImage.image = nil;
    
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    NSDictionary *mediaDict = tweetDict[@"entities"][@"media"][0];
    
    if (mediaDict) {
        if ([mediaDict[@"type"] isEqualToString:@"photo"]) {
            NSURL *url = [NSURL URLWithString:mediaDict[@"media_url_https"]];
            [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, UIImage *image) {
                if (succeeded) {
                    cell.inlineImage.image = image;
                } else {
                    //error handling
                }
            }];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *tweetDict = self.tweets[indexPath.row];
    NSDictionary *mediaDict = tweetDict[@"entities"][@"media"][0];
    
    if (mediaDict) {
        if ([mediaDict[@"type"] isEqualToString:@"photo"]) {
            return [self ImageCellAtIndexPath:indexPath];
        }
    }
    return [self BasicCellAtIndexPath:indexPath];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.clearData) {
        return 0;
    }
    return [self.tweets count];
}

@end
