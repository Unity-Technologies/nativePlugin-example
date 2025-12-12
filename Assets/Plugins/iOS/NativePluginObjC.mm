#import <Foundation/Foundation.h>

// =====================================================================
//         ObjC class plugin to demonstrate +load/+initialize/init
// =====================================================================
@interface ObjCPlugin : NSObject
+ (instancetype)sharedInstance;
+ (BOOL)isInitialized;
@end

@implementation ObjCPlugin
{
    int _workCounter;
}
static ObjCPlugin *g_sharedInstance = nil;

+ (void)load {    
    NSLog(@"[ObjCPlugin] +load (class load) called");    
}

+ (void)initialize {
    NSLog(@"[ObjCPlugin] +initialize (class init) called");
}

- (instancetype)init {
    self = [super init];
    NSLog(@"[ObjCPlugin] instance init called");    
    return self;
}

+ (instancetype)sharedInstance {
    if (!g_sharedInstance) {
        g_sharedInstance = [[ObjCPlugin alloc] init];
        NSLog(@"[ObjCPlugin] sharedInstance created");
    }
    return g_sharedInstance;
}

+ (void)deleteSharedInstance {
    if (g_sharedInstance) {
        NSLog(@"[ObjCPlugin] sharedInstance deleted");
        g_sharedInstance = nil;
    }
}

+ (BOOL)isInitialized { return g_sharedInstance != nil; }

- (int)doWork { return ++_workCounter; }

@end

// =====================================================================
//         C API exposed to C#/IL2CPP
// =====================================================================
extern "C" void NativePlugin_Init()
{
    NSLog(@"[ObjC] NativePlugin_Init called");
    if([ObjCPlugin isInitialized]) return;    
            
    [ObjCPlugin sharedInstance];
}

extern "C" void NativePlugin_Deinit()
{
    NSLog(@"[ObjC] NativePlugin_Deinit called");
    if (![ObjCPlugin isInitialized]) return;

    // Delete the plugin instance
    [ObjCPlugin deleteSharedInstance];
}

typedef void (*NativePluginCallback)(const char* msg);
static NativePluginCallback g_callback = NULL;

extern "C" void NativePlugin_SetCallback(NativePluginCallback cb)
{
    g_callback = cb;
    NSLog(@"[ObjC] NativePlugin_SetCallback registered");
}

// TODO Remove when UnitySendMessage will be exposed in Swift Public API 
#if UNITY_SWIFT_TRAMPOLINE
extern "C" void UnitySendMessage(const char* obj, const char* method, const char* msg);
#endif

extern "C" void NativePlugin_DoWork(const char* goName)
{
    NSLog(@"[ObjC] NativePlugin_DoWork");

    int load = [ObjCPlugin isInitialized] ? [[ObjCPlugin sharedInstance] doWork] : -1;
    
    // Trigger C# callback via UnitySendMessage
    if (goName) {
        NSString* sendMsg = [NSString stringWithFormat: @"Hello from NativePlugin_DoWork via SendMessage (load=%d)", load];
        UnitySendMessage(goName, "OnUnitySendMessage", [sendMsg UTF8String]);
    }

    // Trigger the delegate callback (optional)
    if (g_callback) {
        NSString* cbMsg = [NSString stringWithFormat: @"Hello from NativePlugin_DoWork via callback (load=%d)", load];
        g_callback([cbMsg UTF8String]);        
    }
}

// =====================================================================
//         Global object Example — constructor runs before main(), destructor after main()
// =====================================================================
struct NativePluginGlobalFoo {
    NativePluginGlobalFoo() {
        NSLog(@"[GlobalPlugin] NativePlugin constructor called");
    }

    ~NativePluginGlobalFoo() {
        NSLog(@"[GlobalPlugin] NativePlugin destructor called");
    }
};
NativePluginGlobalFoo g_foo;


// =====================================================================
//         __attribute__ constructor/destructor Example runs before main()
// =====================================================================
__attribute__((constructor))
static void NativePluginConstructAtr() {
    printf("[AtrPlugin] NativePlugin constructor called\n");
}

// after program exit/shared library unload
__attribute__((destructor))
static void NativePluginDestructAtr() {
    printf("[AtrPlugin] NativePlugin destructor called\n");
}

// =====================================================================
//         Unity App Controller Subclass Example  (IMPL_APP_CONTROLLER_SUBCLASS)
// =====================================================================
#if !UNITY_SWIFT_TRAMPOLINE
#import "UnityAppController.h"

// Declare subclass
@interface MyAppController : UnityAppController
@end

@implementation MyAppController

// Example override: called when app finishes launching
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    NSLog(@"[AppControllerPlugin] didFinishLaunchingWithOptions called!");

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}


// --------------------------------------------------------------
// Called when the OS signals the app is about to exit
// NOTE: This is NOT always called on iOS (e.g., when app is killed in the background). 
// --------------------------------------------------------------
- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"[AppControllerPlugin] applicationWillTerminate");

    // Call Unity's original termination logic
    [super applicationWillTerminate:application];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"[AppControllerPlugin] applicationWillResignActive");
    [super applicationWillResignActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"[AppControllerPlugin] applicationDidBecomeActive");
    [super applicationDidBecomeActive:application];
}

@end

// Register subclass with Unity
IMPL_APP_CONTROLLER_SUBCLASS(MyAppController);
#endif