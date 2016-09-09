//
//  ViewController.m
//  zhengze
//
//  Created by Mony on 16/9/6.
//  Copyright © 2016年 Mony. All rights reserved.
//

#import "ViewController.h"

#define kLanguageKey @"kLanguageKey"
#define kAuthorKey @"kAuthorKey"

@interface ViewController()<NSTextViewDelegate>

@property (weak) IBOutlet NSTextField *authorTextField;
@property (weak) IBOutlet NSPopUpButton *languageSelectBtn;
- (IBAction)btnClick:(NSButton *)sender;
@property (unsafe_unretained) IBOutlet NSTextView *myTextView;
@property (weak) IBOutlet NSTextField *statusLabel;

@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;
@property (nonatomic,copy) NSString *body;
@property (nonatomic,copy) NSString *temp;
@property (nonatomic,strong) NSArray *resultArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.myTextView.delegate = self;
    self.resultTextView.delegate = self;
    
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    [self.languageSelectBtn removeAllItems];
    [self.languageSelectBtn addItemWithTitle:@"OC"];
    [self.languageSelectBtn addItemWithTitle:@"Java"];
    
    NSString *authorName = [userDefault stringForKey:kAuthorKey];
    [self.authorTextField insertText:@""];
    [self.authorTextField insertText:authorName];
    
    self.authorTextField.stringValue=authorName?:@"";
    
    NSInteger lastLanguageIndex=[userDefault integerForKey:kLanguageKey];
    [self.languageSelectBtn selectItemAtIndex:lastLanguageIndex];

}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

}

- (IBAction)btnClick:(NSButton *)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:[self.languageSelectBtn indexOfSelectedItem] forKey:kLanguageKey];
    [[NSUserDefaults standardUserDefaults] setObject:self.authorTextField.stringValue forKey:kAuthorKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.body = [NSString stringWithContentsOfURL:[NSURL URLWithString:self.myTextView.string?:@""] encoding:(NSUTF8StringEncoding) error:nil];
    if (self.body) {
        [self buildStatusLabel:@"加载网页成功"];
//        self.statusLabel.stringValue = [NSString stringWithFormat:@"%@--%@-%@",@"状态: ",@"加载网页成功",[self currentTime]];
        [self regularFirstStep];
    }
}

- (void)regularFirstStep {
    NSString *regularStr = @"<div class=\"summary doc-property\">([\\s\\S]*?)</div>";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:self.body options:0 range:NSMakeRange(0, [self.body length])];
    if (result) {
        [self buildStatusLabel:@"网页校验成功"];
        NSRange resulteRange = [result rangeAtIndex:0];
        NSString *resultStr = [self.body substringWithRange:resulteRange];
        self.temp = resultStr;
        [self regularSecondStep];
    }
}

- (void)regularSecondStep {
    NSString *regularStr = @"id=([\\s\\S]*?)</tr>";
    NSArray *matchArray = [NSArray array];
    NSMutableArray *resultArr = [NSMutableArray array];
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    matchArray = [regex matchesInString:self.temp options:(NSMatchingReportProgress) range:NSMakeRange(0, self.temp.length)];
    NSUInteger lastIdx = 0;
    for (NSTextCheckingResult *result in matchArray) {
        NSRange currentRange = result.range;
        if (currentRange.location > lastIdx) {
            NSString *tempStr = [self.temp substringWithRange:currentRange];
            [resultArr addObject:tempStr];
        }
        lastIdx = currentRange.location + currentRange.length;
    }
    
    if (matchArray.count > 0) {
        [self regularThirdStep:resultArr];
    }
    else {
        [self.resultTextView insertText:@"" replacementRange:NSMakeRange(0, self.resultTextView.string.length)];
        [self.resultTextView insertText:[NSString stringWithFormat:@"没有有效数据!--%@",[self currentTime]] replacementRange:NSMakeRange(0, 0)];
//        self.statusLabel.stringValue = [NSString stringWithFormat:@"%@--%@-%@",@"状态: ",@"没有有效数据",[self currentTime]];
        [self buildStatusLabel:@"没有有效数据"];
    }
}

- (void)regularThirdStep:(NSArray *)arr {
    NSString *regularStr = @"<td>([\\s\\S]*?)</td>";
    NSMutableArray *resultArr = [NSMutableArray array];
    NSError *error = NULL;
    __block NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    [arr enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *tempMatchArr = [NSArray array];
        NSMutableArray *tempResultArr = [NSMutableArray array];
        tempMatchArr = [regex matchesInString:obj options:(NSMatchingReportProgress) range:NSMakeRange(0, obj.length)];
        NSUInteger lastIdx = 0;
        for (NSTextCheckingResult *result in tempMatchArr) {
            NSRange currentRange = result.range;
            if (currentRange.location > lastIdx) {
                NSString *tempStr = [obj substringWithRange:currentRange];
                [tempResultArr addObject:tempStr];
            }
            lastIdx = currentRange.location + currentRange.length;
        }
        [resultArr addObject:tempResultArr];
    }];
    
    [self regularFourthStep:resultArr];
}

- (void)regularFourthStep:(NSArray *)arr {
    NSString *regularStr = @"\">([\\s\\S]*?)<";
    NSMutableArray *resultArr = [NSMutableArray array];
    NSError *error = NULL;
    __block NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    for (NSArray *arry in arr) {
        NSMutableArray *tempResultArr = [NSMutableArray array];
        [arry enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj rangeOfString:@"href"].location != NSNotFound) {
                NSTextCheckingResult *result = [regex firstMatchInString:obj options:0 range:NSMakeRange(0, [obj length])];
                NSRange resulteRange = [result rangeAtIndex:0];
                NSString *resultStr = [obj substringWithRange:NSMakeRange(resulteRange.location + 2, resulteRange.length - 3)];
                [tempResultArr addObject:resultStr];
            }
            else {
                NSRange singleRange = NSMakeRange(4, obj.length - 9);
                [tempResultArr addObject:[obj substringWithRange:singleRange]];
            }
        }];
        [resultArr addObject:tempResultArr];
    }
    
    self.resultArr = resultArr;
    [self printResult];
    
}

- (void)printResult {
    NSInteger languageType=[self.languageSelectBtn indexOfSelectedItem];
    __block NSMutableString *newMutableText=[NSMutableString string];
    [newMutableText appendString:[NSString stringWithFormat:@"// %@\n",self.myTextView.string]];
    [self.resultArr enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 注释
        if (languageType == 0) {
            [newMutableText appendString:@"\n"];
            [newMutableText appendString:@"/*!\n"];
            [newMutableText appendFormat:@" *  @author %@ %@\n",self.authorTextField.stringValue?:@"xianting",[self currentTime]];
            [newMutableText appendString:@" *\n"];
            [newMutableText appendFormat:@" *  @brief %@\n",obj[2]?:@""];
            [newMutableText appendString:@" */\n"];
        }
        else {
            [newMutableText appendString:@"\n"];
            [newMutableText appendString:@"/**\n"];
            [newMutableText appendFormat:@" * %@\n",obj[2]?:@""];
            [newMutableText appendString:@" */\n"];
        }
        NSString *text=obj[0];
        NSString *type=obj[1];
        text=[text stringByReplacingOccurrencesOfString:@" " withString:@""];
        text=[text stringByReplacingOccurrencesOfString:@"$" withString:@""];
        text=[text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *tejavaType=[self getJavaTpye:type];
        NSString *newText=[NSString stringWithFormat:@"public %@ %@;\n",tejavaType,text];
        if (languageType == 0) {
            newText = [NSString stringWithFormat:@"@property (nonatomic, copy) NSString *%@;\n",text];
        }
        [newMutableText appendString:newText];
    }];
    
    [self.resultTextView insertText:@"" replacementRange:NSMakeRange(0, self.resultTextView.string.length)];
    [self.resultTextView insertText:newMutableText replacementRange:NSMakeRange(0, 0)];
//    self.statusLabel.stringValue = [NSString stringWithFormat:@"%@--%@-%@",@"状态: ",@"属性生成成功",[self currentTime]];
    [self buildStatusLabel:@"属性生成成功"];
}

-(NSString *)currentTime{
    //16-09-01 14:09:14
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}

-(NSString *)getJavaTpye:(NSString *)key{
    NSDictionary *dic=@{ @"int":@"int",
                         @"Integer":@"int",
                         };
    NSString *value=dic[key];
    return value?:@"String";
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(insertNewline:)){
        if ([textView isEqualTo:self.myTextView]) {
            NSString *textViewStr = [self.myTextView.string?:@"" copy];
            [self.myTextView insertText:@"" replacementRange:NSMakeRange(0, self.myTextView.string.length)];
            [self.myTextView insertText:textViewStr replacementRange:NSMakeRange(0, 0)];
            [self btnClick:nil];
            return YES;
        }
        else if ([textView isEqualTo:self.resultTextView] && self.resultTextView.string.length > 0) {
            NSPasteboard *pastboard = [NSPasteboard generalPasteboard];
            [pastboard clearContents];
            BOOL isSuccess = [pastboard writeObjects:@[self.resultTextView.string]];
            [self buildStatusLabel:isSuccess?@"属性复制成功":@"属性复制失败"];
//            self.statusLabel.stringValue = [NSString stringWithFormat:@"%@--%@-%@",@"状态: ",isSuccess?@"属性复制成功":@"属性复制失败",[self currentTime]];
            return YES;
        }
    }
    return NO;
}

- (void)buildStatusLabel:(NSString *)msg {
    self.statusLabel.stringValue = [NSString stringWithFormat:@"%@--%@-%@",@"状态: ",msg,[self currentTime]];
}

@end
