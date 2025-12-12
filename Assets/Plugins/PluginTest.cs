using UnityEngine;

public class PluginTest : MonoBehaviour, IGetCallFromNativePlugin
{
    public string ObjectName => gameObject.name;

    string lastUnitySendMessage = "—";
    string lastCallbackMessage = "—";

    void Start()
    {
        NativePlugin.Init();
    }

    void OnDestroy()
    {
        NativePlugin.Deinit();
    }

    void OnGUI()
    {
        const float w = 340f;
        const float h = 80f;
        var textStyle = new GUIStyle(GUI.skin.label) { fontSize = 25, richText = true, normal = { textColor = Color.white } };
        var titleStyle = new GUIStyle(GUI.skin.label) { fontSize = 30, richText = true, fontStyle = FontStyle.Bold, normal = { textColor = Color.white } };
        var buttonStyle = new GUIStyle(GUI.skin.button) { fontSize = 30, alignment = TextAnchor.MiddleCenter, normal = { textColor = Color.white } };        

        GUILayout.BeginArea(new Rect(40, 200, 600, 700));

        GUILayout.Label("<b>Native Plugin Demo</b>", titleStyle);

        GUILayout.Space(15);

        GUILayout.Label("<b>UnitySendMessage:</b> " + lastUnitySendMessage, textStyle);
        GUILayout.Label("<b>Callback:</b> " + lastCallbackMessage, textStyle);

        GUILayout.Space(25);

        if (GUILayout.Button("Do Work", buttonStyle,GUILayout.Width(w), GUILayout.Height(h)))
            NativePlugin.DoWork(this);

        GUILayout.Space(10);

        if (GUILayout.Button("Plugin Init", buttonStyle, GUILayout.Width(w), GUILayout.Height(h)))
            NativePlugin.Init();

        GUILayout.Space(10);

        if (GUILayout.Button("Plugin Deinit", buttonStyle, GUILayout.Width(w), GUILayout.Height(h)))
        {
            lastUnitySendMessage = lastCallbackMessage = "-";
            NativePlugin.Deinit();
        }

        GUILayout.EndArea();
    }

    // ======================================
    // Interface Callbacks
    // ======================================

    public void OnUnitySendMessage(string message)
    {
        lastUnitySendMessage = message;
        Debug.Log("[UnitySendMessage] " + message);
    }
    
   
    public void OnCallBackMessage(string message)
    {
        lastCallbackMessage = message;
        Debug.Log("[CallbackMessage] " + message);
    }
    
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void CreateTestGO()
    {
        if (FindAnyObjectByType<PluginTest>() == null)
        {
            var go = new GameObject("NativePluginDemo");
            go.AddComponent<PluginTest>();
            Debug.Log("[Bootstrap] Created GameObject 'NativePluginDemo' with PluginTest.");
        }
    }      
}