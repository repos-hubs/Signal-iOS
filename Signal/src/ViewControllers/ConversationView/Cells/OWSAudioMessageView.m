//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSAudioMessageView.h"
#import "ConversationViewItem.h"
#import "Signal-Swift.h"
#import "UIColor+OWS.h"
#import "ViewControllerUtils.h"
#import <SignalMessaging/OWSFormat.h>
#import <SignalMessaging/UIColor+OWS.h>
#import <SignalServiceKit/MIMETypeUtil.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSAudioMessageView ()

@property (nonatomic) TSAttachmentStream *attachmentStream;
@property (nonatomic) BOOL isIncoming;
@property (nonatomic, weak) ConversationViewItem *viewItem;

@property (nonatomic, nullable) UIButton *audioPlayPauseButton;
@property (nonatomic, nullable) UILabel *audioBottomLabel;
@property (nonatomic, nullable) AudioProgressView *audioProgressView;

@end

#pragma mark -

@implementation OWSAudioMessageView

- (instancetype)initWithAttachment:(TSAttachmentStream *)attachmentStream
                        isIncoming:(BOOL)isIncoming
                          viewItem:(ConversationViewItem *)viewItem
{
    self = [super init];

    if (self) {
        _attachmentStream = attachmentStream;
        _isIncoming = isIncoming;
        _viewItem = viewItem;
    }

    return self;
}

- (void)updateContents
{
    [self updateAudioProgressView];
    [self updateAudioBottomLabel];

    if (self.audioPlaybackState == AudioPlaybackState_Playing) {
        [self setAudioIconToPause];
    } else {
        [self setAudioIconToPlay];
    }
}

- (CGFloat)audioProgressSeconds
{
    return [self.viewItem audioProgressSeconds];
}

- (CGFloat)audioDurationSeconds
{
    OWSAssert(self.viewItem.audioDurationSeconds > 0.f);

    return self.viewItem.audioDurationSeconds;
}

- (AudioPlaybackState)audioPlaybackState
{
    return [self.viewItem audioPlaybackState];
}

- (BOOL)isAudioPlaying
{
    return self.audioPlaybackState == AudioPlaybackState_Playing;
}

- (void)updateAudioBottomLabel
{
    if (self.isAudioPlaying && self.audioProgressSeconds > 0 && self.audioDurationSeconds > 0) {
        self.audioBottomLabel.text =
            [NSString stringWithFormat:@"%@ / %@",
                      [OWSFormat formatDurationSeconds:(long)round(self.audioProgressSeconds)],
                      [OWSFormat formatDurationSeconds:(long)round(self.audioDurationSeconds)]];
    } else {
        self.audioBottomLabel.text =
            [NSString stringWithFormat:@"%@", [OWSFormat formatDurationSeconds:(long)round(self.audioDurationSeconds)]];
    }
}

- (void)setAudioIcon:(UIImage *)icon
{
    OWSAssert(icon.size.height == self.iconSize);

    icon = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_audioPlayPauseButton setImage:icon forState:UIControlStateNormal];
    [_audioPlayPauseButton setImage:icon forState:UIControlStateDisabled];
    _audioPlayPauseButton.imageView.tintColor = [UIColor ows_signalBlueColor];
    _audioPlayPauseButton.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.92f];
    _audioPlayPauseButton.layer.cornerRadius = self.iconSize * 0.5f;
}

- (void)setAudioIconToPlay
{
    [self setAudioIcon:[UIImage imageNamed:@"audio_play_black_40"]];
}

- (void)setAudioIconToPause
{
    [self setAudioIcon:[UIImage imageNamed:@"audio_pause_black_40"]];
}

- (void)updateAudioProgressView
{
    [self.audioProgressView
        setProgress:(self.audioDurationSeconds > 0 ? self.audioProgressSeconds / self.audioDurationSeconds : 0.f)];

    UIColor *progressColor = (self.isIncoming ? [UIColor ows_light02Color] : [UIColor ows_light60Color]);
    self.audioProgressView.horizontalBarColor = progressColor;
    self.audioProgressView.progressColor = progressColor;
}

#pragma mark -

- (CGFloat)hMargin
{
    return 0.f;
}

- (CGFloat)hSpacing
{
    return 8.f;
}

+ (CGFloat)vMargin
{
    return 0.f;
}

- (CGFloat)vMargin
{
    return [OWSAudioMessageView vMargin];
}

+ (CGFloat)bubbleHeight
{
    CGFloat iconHeight = self.iconSize;
    CGFloat labelsHeight = ([OWSAudioMessageView labelFont].lineHeight * 2 +
        [OWSAudioMessageView audioProgressViewHeight] + [OWSAudioMessageView labelVSpacing] * 2);
    CGFloat contentHeight = MAX(iconHeight, labelsHeight);
    return contentHeight + self.vMargin * 2;
}

- (CGFloat)bubbleHeight
{
    return [OWSAudioMessageView bubbleHeight];
}

+ (CGFloat)iconSize
{
    return 40.f;
}

- (CGFloat)iconSize
{
    return [OWSAudioMessageView iconSize];
}

- (BOOL)isVoiceMessage
{
    return self.attachmentStream.isVoiceMessage;
}

- (void)createContents
{
    self.axis = UILayoutConstraintAxisHorizontal;
    self.alignment = UIStackViewAlignmentCenter;
    self.spacing = self.hSpacing;

    _audioPlayPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.audioPlayPauseButton.enabled = NO;
    [self addArrangedSubview:self.audioPlayPauseButton];
    [self.audioPlayPauseButton setContentHuggingHigh];

    NSString *filename = self.attachmentStream.sourceFilename;
    if (!filename) {
        filename = [[self.attachmentStream filePath] lastPathComponent];
    }
    NSString *topText = [[filename stringByDeletingPathExtension] ows_stripped];
    if (topText.length < 1) {
        topText = [MIMETypeUtil fileExtensionForMIMEType:self.attachmentStream.contentType].uppercaseString;
    }
    if (topText.length < 1) {
        topText = NSLocalizedString(@"GENERIC_ATTACHMENT_LABEL", @"A label for generic attachments.");
    }
    if (self.isVoiceMessage) {
        topText = nil;
    }
    UILabel *topLabel = [UILabel new];
    topLabel.text = topText;
    topLabel.textColor = (self.isIncoming ? [UIColor ows_whiteColor] : [UIColor ows_light90Color]);
    topLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    topLabel.font = [OWSAudioMessageView labelFont];

    AudioProgressView *audioProgressView = [AudioProgressView new];
    self.audioProgressView = audioProgressView;
    [self updateAudioProgressView];
    [audioProgressView autoSetDimension:ALDimensionHeight toSize:[OWSAudioMessageView audioProgressViewHeight]];

    UILabel *bottomLabel = [UILabel new];
    self.audioBottomLabel = bottomLabel;
    [self updateAudioBottomLabel];
    bottomLabel.textColor = (self.isIncoming ? [UIColor colorWithWhite:1.f alpha:0.7f] : [UIColor ows_light60Color]);
    bottomLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    bottomLabel.font = [OWSAudioMessageView labelFont];

    UIStackView *labelsView = [UIStackView new];
    labelsView.axis = UILayoutConstraintAxisVertical;
    labelsView.spacing = [OWSAudioMessageView labelVSpacing];
    [labelsView addArrangedSubview:topLabel];
    [labelsView addArrangedSubview:audioProgressView];
    [labelsView addArrangedSubview:bottomLabel];

    // Ensure the "audio progress" and "play button" are v-center-aligned using a container.
    UIView *labelsContainerView = [UIView containerView];
    [self addArrangedSubview:labelsContainerView];
    [labelsContainerView addSubview:labelsView];
    [labelsView autoPinWidthToSuperview];
    [labelsView autoPinEdgeToSuperviewMargin:ALEdgeTop relation:NSLayoutRelationGreaterThanOrEqual];
    [labelsView autoPinEdgeToSuperviewMargin:ALEdgeBottom relation:NSLayoutRelationGreaterThanOrEqual];

    [audioProgressView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.audioPlayPauseButton];

    [self updateContents];
}

+ (CGFloat)audioProgressViewHeight
{
    return 12.f;
}

+ (UIFont *)labelFont
{
    return [UIFont ows_dynamicTypeCaption2Font];
}

+ (CGFloat)labelVSpacing
{
    return 2.f;
}

@end

NS_ASSUME_NONNULL_END
