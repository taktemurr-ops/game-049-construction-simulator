using UnityEngine;

namespace GameStudio.Construction
{
    public static class PrototypeBootstrap
    {
        // Auto-starts the input/OnGUI prototype in an empty Unity scene.
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Launch()
        {
            if (Object.FindObjectOfType<ConstructionPrototype>() != null) return;
            var host = new GameObject("Game Studio 100 - Construction Prototype");
            Object.DontDestroyOnLoad(host);
            host.AddComponent<ConstructionPrototype>();
        }
    }
}
