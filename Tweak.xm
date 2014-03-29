#import <UIKit/UIKit.h>

@interface LFXLightingEffect : NSObject {
	BOOL _effectIsRunning; 
	NSArray* _lights; 
}
@property (nonatomic,retain) NSArray *lights;
@property (assign,nonatomic) BOOL effectIsRunning;
+(id)allLightingEffects;
+(id)activeLightingEffectForLight:(id)arg1;
+(id)sharedLightingEffect;
-(void)lightsWillChangeTo:(id)arg1;
-(void)lightWillBeRemoved:(id)arg1;
-(void)lightWillBeAdded:(id)arg1;
-(void)setEffectIsRunning:(BOOL)arg1;
-(void)effectDidStart;
-(void)effectDidStop;
-(void)removeLights:(id)arg1;
-(BOOL)containsLight:(id)arg1;
-(void)addLights:(id)arg1;
-(id)init;
-(id)title;
@end

@interface LFXHSBKColor : NSObject <NSCopying> {
	unsigned short _kelvin; 
	float _hue; 
	float _saturation; 
	float _brightness; 
}
@property (assign,nonatomic) float hue;
@property (assign,nonatomic) float saturation;
@property (assign,nonatomic) float brightness;
@property (assign,nonatomic) unsigned short kelvin;
+(id)colorWithHue:(float)arg1 saturation:(float)arg2 brightness:(float)arg3 kelvin:(unsigned short)arg4;
+(id)colorWithProtocolLightHSBK:(id)arg1;
+(id)averageOfColors:(id)arg1;
+(id)colorWithLegacyColor:(id)arg1;
-(id)legacyColor;
-(void)setKelvin:(unsigned short)arg1;
-(id)protocolLightHSBKValue;
-(void)setSaturation:(float)arg1;
-(void)setHue:(float)arg1;
-(id)init;
-(BOOL)isEqual:(id)arg1;
-(id)description;
-(id)copyWithZone:(NSZone*)arg1;
-(id)stringValue;
-(void)setBrightness:(float)arg1;
-(BOOL)isWhite;
-(id)UIColor;
@end

@interface LFXLight : NSObject {
	id _site; 
	id _path; 
	NSArray* _groups; 
}
@property (nonatomic,copy) id site;
@property (nonatomic,copy) id path;
@property (nonatomic,copy) NSArray* groups;
-(unsigned)fuzzyPowerState;
-(void)setColor:(id)arg1 overDuration:(double)arg2;
-(id)label;
-(void)setLabel:(id)arg1;
-(LFXHSBKColor *)color;
-(void)setColor:(LFXHSBKColor *)arg1;
-(unsigned)powerState;
-(void)setPowerState:(unsigned int)arg1;
@end

@interface LFFadeLightingEffect : LFXLightingEffect
@end

@interface LFRandomColourLightingEffect : LFXLightingEffect
@end

#define TIMER_INTERVAL 0.1

static NSTimer *fadeTimer = nil;
static CGFloat oldHue = 0.65f;

%subclass LFFadeLightingEffect : LFXLightingEffect

- (NSString *)title
{
	return @"Fade";
}

- (BOOL)effectIsRunning
{
	return [fadeTimer isValid];
}

- (void)setEffectIsRunning:(BOOL)running
{
	if (running)
	{
		fadeTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(fadeTimerFired) userInfo:nil repeats:YES];
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	}
	else
	{
		[fadeTimer invalidate];
		fadeTimer = nil;
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	}

	%orig;
}

%new
- (void)fadeTimerFired
{
	NSArray *lights = [self lights];

	CGFloat hue = oldHue + 0.001f;
	if (hue > 1.0f) hue = 0.0f;
	oldHue = hue;

	CGFloat saturation = 1.0f;
	CGFloat brightness = 0.6f;
	unsigned short kelvin = 3500;
	LFXHSBKColor *color = [objc_getClass("LFXHSBKColor") colorWithHue:hue saturation:saturation brightness:brightness kelvin:kelvin];

	[lights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
		LFXLight *light = (LFXLight *)obj;
		[light setColor:color overDuration:(TIMER_INTERVAL * 0.75f)];
	}];
}

%end

#define RANDOM_ON_PERIOD 1.5f
#define RANDOM_OFF_PERIOD 0.5f

#define RANDOM_RAMP_ON_PERIOD 0.2f
#define RANDOM_RAMP_OFF_PERIOD 0.3f

#define MIN_COLOUR_SHIFT 40.0f

static NSTimer *randomTimer = nil;
static NSUInteger randomBulbIndex = 0;
static CGFloat randomOldHue = 0.0f;

%subclass LFRandomColourLightingEffect : LFXLightingEffect

- (NSString *)title
{
	return @"Random Colour";
}

- (BOOL)effectIsRunning
{
	return [randomTimer isValid];
}

- (void)setEffectIsRunning:(BOOL)running
{
	if (running && ![randomTimer isValid])
	{
		randomTimer = [NSTimer scheduledTimerWithTimeInterval:(RANDOM_ON_PERIOD + RANDOM_OFF_PERIOD + RANDOM_RAMP_ON_PERIOD + RANDOM_RAMP_OFF_PERIOD) target:self selector:@selector(randomTimerFired) userInfo:nil repeats:YES];
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];

		NSArray *lights = [self lights];
		[lights enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
			LFXLight *light = (LFXLight *)obj;

			LFXHSBKColor *color = light.color;
			[light setPowerState:1];

			color.brightness = 0.0f;
			[light setColor:color];
		}];
	}
	else
	{
		[randomTimer invalidate];
		randomTimer = nil;
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	}

	%orig;
}

%new
- (void)randomTimerFired
{
	NSArray *lights = [self lights];

	CGFloat hue = randomOldHue;
	CGFloat diff = 0.0f;
    while (diff < MIN_COLOUR_SHIFT)
	{
        hue = (arc4random() % 360) / 360.0f;
        diff = abs((hue * 360.0f) - (randomOldHue * 360.0f));
	}
    randomOldHue = hue;
	

	CGFloat saturation = 1.0f;
	CGFloat brightness = 0.6f;
	unsigned short kelvin = 3500;
	LFXHSBKColor *color = [objc_getClass("LFXHSBKColor") colorWithHue:hue saturation:saturation brightness:brightness kelvin:kelvin];

	LFXLight *light = (LFXLight *)[lights objectAtIndex:randomBulbIndex];

	color.brightness = 0.0f;
	[light setColor:color];

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (RANDOM_OFF_PERIOD - RANDOM_RAMP_OFF_PERIOD) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		color.brightness = brightness;
		[light setColor:color overDuration:RANDOM_RAMP_ON_PERIOD];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, RANDOM_ON_PERIOD * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			color.brightness = 0.0f;
			[light setColor:color overDuration:RANDOM_RAMP_OFF_PERIOD];
		});
	});

	randomBulbIndex++;
	if (randomBulbIndex >= [lights count]) randomBulbIndex = 0;
}

%end

static LFFadeLightingEffect *fadeEffect = nil;
static LFRandomColourLightingEffect *randomEffect = nil;

%hook LFXLightingEffect

+ (id)allLightingEffects
{
	if (fadeEffect == nil) fadeEffect = [[objc_getClass("LFFadeLightingEffect") alloc] init];
	if (randomEffect == nil) randomEffect = [[objc_getClass("LFRandomColourLightingEffect") alloc] init];

	NSMutableArray *newArray = [NSMutableArray arrayWithArray:%orig];
	if (![newArray containsObject:fadeEffect]) [newArray addObject:fadeEffect];
	if (![newArray containsObject:randomEffect]) [newArray addObject:randomEffect];

	return newArray;
}

%end