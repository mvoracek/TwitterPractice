//
//  TweetReplyViewController.m
//  TwitterPractice
//
//  Created by Matthew Voracek on 12/8/14.
//  Copyright (c) 2014 Matthew Voracek. All rights reserved.
//

#import "TweetReplyViewController.h"

@interface TweetReplyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *replyTweetText;

@end

@implementation TweetReplyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.modalPresentationStyle = UIModalPresentationPopover;
    
    NSLog(@"%@", self.tweetDictionary);
    
    NSString *authorID = self.tweetDictionary[@"user"][@"screen_name"];
    NSString *tweetID = self.tweetDictionary[@"id_str"];
    NSString *tweetText = self.tweetDictionary[@"text"];
    
    NSString *reply = [NSString stringWithFormat:@"@%@ %@\n%@", authorID, tweetID, tweetText];
    self.replyTweetText.text = reply;
}

- (IBAction)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
