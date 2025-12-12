using System;
using System.Runtime.InteropServices;
using UnityEngine;
using AOT;

public interface IGetCallFromNativePlugin
{
    string ObjectName { get; }
    void OnUnitySendMessage(string message);
    void OnCallBackMessage(string message);
}

public static class NativePlugin
{
    [UnmanagedFunctionPointer(CallingConvention.Cdecl)]
    public delegate void NativePluginCallback(string msg);
    static NativePluginCallback _callback;
    
    const string DLL = "__Internal";
    [DllImport(DLL)] static extern void NativePlugin_Init();
    [DllImport(DLL)] static extern void NativePlugin_Deinit();
    [DllImport(DLL)] static extern void NativePlugin_SetCallback(IntPtr cb);
    [DllImport(DLL)] static extern void NativePlugin_DoWork(string gameObjectName);
    
    public static void Init()
    {
#if (UNITY_IOS || UNITY_TVOS || UNITY_VISIONOS) && !UNITY_EDITOR
        _callback = OnCallbackFromNative;
        IntPtr cb = Marshal.GetFunctionPointerForDelegate(_callback);

        NativePlugin_Init();
        NativePlugin_SetCallback(cb);
#endif
    }

    public static void Deinit()
    {
#if (UNITY_IOS || UNITY_TVOS || UNITY_VISIONOS) && !UNITY_EDITOR
        _workReceiver = null;
        NativePlugin_SetCallback(IntPtr.Zero);
        NativePlugin_Deinit();
#endif
    }

    static IGetCallFromNativePlugin _workReceiver = null;
    public static void DoWork(IGetCallFromNativePlugin receiver)
    {
#if (UNITY_IOS || UNITY_TVOS || UNITY_VISIONOS) && !UNITY_EDITOR
        _workReceiver = receiver;
        NativePlugin_DoWork(receiver.ObjectName);
#endif
    }

    [MonoPInvokeCallback(typeof(NativePlugin.NativePluginCallback))]
    private static void OnCallbackFromNative(string msg)
    {
        Debug.Log("Got native callback: " + msg);
        _workReceiver?.OnCallBackMessage(msg);
        _workReceiver = null;
    }
}