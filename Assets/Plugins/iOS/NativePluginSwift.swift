import Foundation
import UIKit

// ===========================================================
//              Swift class equivalent of ObjCPlugin
// ===========================================================

final class SwiftPlugin {
    private static var sharedInstance: SwiftPlugin?

    static func shared() -> SwiftPlugin {
        if sharedInstance == nil {
            sharedInstance = SwiftPlugin()
            NSLog("[SwiftPlugin] sharedInstance created")
        }
        return sharedInstance!
    }

    static func deleteSharedInstance() {
        sharedInstance = nil
        NSLog("[SwiftPlugin] sharedInstance deleted")
    }

    static func isInitialized() -> Bool {
        return sharedInstance != nil
    }

    private init() {
        NSLog("[SwiftPlugin] init called")
    }

    deinit {
        NSLog("[SwiftPlugin] deinit called")
    }
    
    private var workCounter: Int = 0
    
    func doWork() -> Int {
        workCounter += 1
        return workCounter
    }
}

// ===========================================================
//              UnitySendMessage bridge (from Unity)
// ===========================================================
// TODO  Remove After Public API

@_silgen_name("UnitySendMessage")
func UnitySendMessage(
    _ obj: UnsafePointer<CChar>!,
    _ method: UnsafePointer<CChar>!,
    _ msg: UnsafePointer<CChar>!
)


// ===========================================================
//              C-compatible callback type & storage
// ===========================================================
public typealias NativePluginCallback = @convention(c) (UnsafePointer<CChar>?) -> Void
private var g_callback: NativePluginCallback? = nil


// ===========================================================
//              C API exposed to C#/IL2CPP (same as ObjC)
// ===========================================================

@_cdecl("NativePlugin_Init")
public func NativePlugin_Init() {
    NSLog("[Swift] NativePlugin_Init called")

    if SwiftPlugin.isInitialized() {
        // Already initialized — same as ObjC (no-op)
        return
    }

    _ = SwiftPlugin.shared()
}

@_cdecl("NativePlugin_Deinit")
public func NativePlugin_Deinit() {
    NSLog("[Swift] NativePlugin_Deinit called")

    if !SwiftPlugin.isInitialized() {
        // Not initialized — mimic ObjC behavior
        return
    }

    SwiftPlugin.deleteSharedInstance()
}

@_cdecl("NativePlugin_SetCallback")
public func NativePlugin_SetCallback(_ cb: NativePluginCallback?) {
    g_callback = cb

    NSLog("[Swift] NativePlugin_SetCallback registered")
}

@_cdecl("NativePlugin_DoWork")
public func NativePlugin_DoWork(_ goName: UnsafePointer<CChar>?) {
    NSLog("[Swift] NativePlugin_DoWork")

    let load: Int
    if SwiftPlugin.isInitialized() {
        load = SwiftPlugin.shared().doWork()
    } else {
        load = -1
    }

    // SendMessage → Unity -> C#
    let sendMessageText = "Hello from NativePlugin_DoWork via SendMessage (load=\(load))"

    if let goName = goName {
        sendMessageText.withCString { msgPtr in
            UnitySendMessage(goName, "OnUnitySendMessage", msgPtr)
        }
    }

    // C callback (optional)
    if let cb = g_callback {
        let cbText = "Hello from NativePlugin_DoWork via callback (load=\(load))"
        cbText.withCString { msgPtr in
            cb(msgPtr)
        }
    }
}
