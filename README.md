# Unity native plug-in example for iOS, tvOS, and visionOS

This repository demonstrates Objective-C and Swift native plugin implementations.
- showcasing different initialization ways available per language
- sharing a unified managed C# API

The goal of this project is to show how to structure, initialize, and integrate native code inside Unity’s iOS runtime.  
Works on all Apple platforms (iOS, tvOS, visionOS) on both Device and Simulator SDKs.  

# Content
<img width="1369" height="158" alt="image" src="https://github.com/user-attachments/assets/5c71f44d-8e7b-40d5-9c45-5b061381338c" />   

- NativePlugin.cs C# API to Native Plugin
- NativePluginObjC.mm (Objective-C language implementation of NativePlugin.cs API)
- NativePluginSwift.swift (Swift language implementation of NativePlugin.cs API)
- PluginTest.cs Uses C# API from NativePlugin.cs

# Two interchangeable native plugin implementations
- Objective-C Plugin
Demonstrates: +load, +initialize, singleton initialization, global constructors/destructors, UnitySendMessage callbacks, C-level API exposure, and deep integration with Unity AppController.

- Swift Plugin
Lightweight, explicit, and designed to showcase Swift-friendly integration with Unity.

Both implementations expose the exact same C API, so the managed C# side does not change. Demonstrates unity lifecycle hooks to trigger native plugin initialization.  

# How to use
You can switch between Swift or Objective-C(Default enabled) plugin versions using Unity’s Plugin Importer:  
<img width="229" height="250" alt="image" src="https://github.com/user-attachments/assets/8d620416-038d-4920-8c4d-24db88daaa70" />

Or enabled them both, generate Xcode project and disable/enable one of them from the Xcode in Inspector while file selected:
<img width="373" height="152" alt="image" src="https://github.com/user-attachments/assets/b781f3b4-0ca6-412a-9a77-093658befe36" />

Select different Xcode Project Type:  
<img width="523" height="88" alt="image" src="https://github.com/user-attachments/assets/3f0f2017-618c-4d33-8266-420823d58572" />


# Unified C# API
Regardless of which native implementation is enabled:
- Same C# function signatures 
- Same marshaling behavior 
- Same callback flow (C → C# delegate or UnitySendMessage → MonoBehaviour) 
- No code changes required in user scripts


# Supported for
- Unity 6000.5+
- Objective-C or Swift Project type
- Xcode Device & Simulator SDKs
- Unity as a Library setups

# Features Demonstrated

Native Objective-C
- +load and +initialize
- Singleton pattern with manual deletion
- Global constructors & destructors
- Attribute-based constructors/destructors
- Pure C API exposed to Unity
- UnitySendMessage (native → C#)
- C function pointer callback registration
- IMPL_APP_CONTROLLER_SUBCLASS

Native Swift Plugin
- Swift singleton
- _cdecl C API exposed to Unity
- Function-pointer callback registration

Managed C#:
- Marshaling strings to native code
- Registering callback function pointers
- Receiving UnitySendMessage calls from native side
- A unified API that works identically for ObjC and Swift
- RuntimeInitializeOnLoadMethod

# Plugin initialization sequence
| ObjC trampoline | < | > | Swift trampoline |
|----------|------|------|------------------|
| main() | Unity | Unity | main()-> SwiftUI.App.main |
| ⤷ load UnityRuntime.framework dynamically | Unity |  |  |
| · ⤷ [ObjCPlugin] +load (class load) called | NP.ObjC |  |  |
| · ⤷ [AttrPlugin] NativePlugin constructor called | NP.Attr |  |  |
| · ⤷ [GlobalPlugin] NativePlugin constructor called | NP.C++ |  |  |
| ⤷ UFW runUIApplication | OS | OS | ⤷ run UIApplication |
| · ⤷ UnityRuntime initialization | Unity |  |  |
| · ⤷ [AppControllerPlugin] didFinishLaunchingWithOptions called | NP.AppCtl |  |  |
| · · UnityRuntime initialized | Unity |  |  |
| · UnityPlayerLoop | Unity | Unity | · UnityPlayerLoop |
| · ⤷ C# RuntimeInitializeOnLoadMethod | C# | C# | · ⤷ C# RuntimeInitializeOnLoadMethod |
| · · ⤷ C# Create new GO and AddComponent PluginTest | C# | C# | · · ⤷ C# Create new GO and AddComponent PluginTest |
| · · · ⤷ C# PluginTest.Start() | C# | C# | · · · ⤷ C# PluginTest.Start() |
| · · · · ⤷ [ObjC] NativePlugin_Init called | NP.C | PC.C | · · · · ⤷ [Swift] NativePlugin_Init called |
| · · · · ⤷ [ObjCPlugin] +initialize (class init) called | NP.ObjC |  |  |
| · · · · ⤷ [ObjCPlugin] instance init called | NP.ObjC | CP.Swift | · · · · ⤷ [SwiftPlugin] instance init called |
| · · · · ⤷ [ObjCPlugin] sharedInstance created | NP.ObjC | NP.Swift | · · · · ⤷ [SwiftPlugin] sharedInstance created |
| · · · · ⤷ [ObjC] NativePlugin_SetCallback registered | NP.ObjC |  | · · · · ⤷ [SwiftPlugin] sharedInstance created |

# App/Plugin termination sequence
| ObjC trampoline | < | > | Swift trampoline |
|----------|------|------|------------------|
|  main() | Unity | Unity | main()-> SwiftUI.App.main |
|  ⤷ UFW runUIApplication |  OS | OS | ⤷ run UIApplication |
|  · ⤷ applicationWillTerminate() | OS | OS | ⤷ applicationWillTerminate() |
|  · ⤷ [AppControllerPlugin] applicationWillTerminate | NP.AppCtl |  |  |
|  · · ⤷ UnityCleanup | Unity | Unity | · ⤷ UnityCleanup |
|  · · · ⤷ Destroy Game Objects | Unity | Unity | ·  · ⤷ Destroy Game Objects |
|  · · · · ⤷ C# PluginTest.OnDestroy | C# | C# | ·  · ⤷ C# PluginTest.OnDestroy |
|  · · · · · [ObjC] NativePlugin_SetCallback registered | NP.C | NP.C | · · · [Swift] NativePlugin_SetCallback registered |
|  · · · · · [ObjC] NativePlugin_Deinit called | NP.C | NP.C | · · · [Swift] NativePlugin_Deinit called |
|  · · · · · [ObjCPlugin] sharedInstance deleted | NP.ObjC | NP.ObjC | · · · [SwiftPlugin] sharedInstance deleted |
