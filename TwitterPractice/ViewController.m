//
//  ViewController.m
//  TwitterPractice
//
//  Created by Matthew Voracek on 12/1/14.
//  Copyright (c) 2014 Matthew Voracek. All rights reserved.
//

#import "ViewController.h"
#import "STTwitter.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) STTwitterAPI *twitter;

@end

static NSString *TWITTER_CONSUMER_KEY = @"fx95oKhMHYgytSBmiAqQ";
static NSString *TWITTER_CONSUMER_SEC = @"0zfaijLMWMYTwVosdqFTL3k58JhRjZNxd2q0i9cltls";
static NSString *OAUTH_TOKEN = @"2305278770-GGw8dQQg3o5Vqfx9xHpUgJ0CDUe3BoNmUNeWZBg";
static NSString *OAUTH_SECRET = @"iEzxeJjEPnyODVcoDYt5MVvrg90Jx2TOetGdNeol6PeYp";

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self searchResultsFromValue:@"wwdc"];
}

- (void)searchResultsFromValue:(NSString *)value
{
    self.twitter = [STTwitterAPI twitterAPIWithOAuthConsumerKey:TWITTER_CONSUMER_KEY
                                                 consumerSecret:TWITTER_CONSUMER_SEC
                                                     oauthToken:OAUTH_TOKEN
                                               oauthTokenSecret:OAUTH_SECRET];
    
    [self.twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        
        [self.twitter getSearchTweetsWithQuery:value geocode:nil lang:nil locale:nil resultType:nil count:@"100" until:nil sinceID:nil maxID:nil includeEntities:nil callback:nil successBlock:^(NSDictionary *searchMetadata, NSArray *statuses) {
            NSLog(@"%@", statuses);
        } errorBlock:^(NSError *error) {
            NSLog(@"%@", error.debugDescription);
        }];
        
        
    } errorBlock:^(NSError *error) {
        NSLog(@"%@", error.debugDescription);
    }];
}

@end
