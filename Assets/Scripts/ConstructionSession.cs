using System;
using System.Collections.Generic;
using UnityEngine;

namespace GameStudio.Construction
{
    public enum BuildStage { Foundation, Structure, Roof, Finished }

    /// <summary>Resources, cost and ordered stages for a small construction mission.</summary>
    public sealed class ConstructionSession
    {
        public int Cash { get; private set; } = 1000;
        public int Material { get; private set; } = 40;
        public BuildStage Stage { get; private set; } = BuildStage.Foundation;
        public float Progress { get; private set; }

        static readonly int[] Costs = { 100, 250, 200 };
        static readonly int[] Materials = { 5, 15, 10 };

        public bool Work(float seconds, float productivity = 1f)
        {
            if (Stage == BuildStage.Finished || seconds <= 0 || productivity <= 0 ||
                float.IsNaN(seconds) || float.IsInfinity(seconds) ||
                float.IsNaN(productivity) || float.IsInfinity(productivity)) return false;
            int index = (int)Stage;
            if (Progress == 0f)
            {
                if (Cash < Costs[index] || Material < Materials[index]) return false;
                Cash -= Costs[index];
                Material -= Materials[index];
            }
            Progress += seconds * productivity / 10f;
            if (Progress >= 1f)
            {
                Stage++;
                Progress = 0f;
                if (Stage == BuildStage.Finished) Cash += 1000;
            }
            return true;
        }

        public void Supply(int material, int cost)
        {
            if (material <= 0 || cost < 0 || cost > Cash ||
                material > int.MaxValue - Material) return;
            Cash -= cost;
            Material += material;
        }
    }

    public sealed class ConstructionPrototype : MonoBehaviour
    {
        public ConstructionSession Session = new ConstructionSession();
        private bool _touchWorking;
        void Update()
        {
            if (Input.GetKey(KeyCode.Space) || _touchWorking) Session.Work(Time.deltaTime);
        }
        void OnGUI()
        {
            GUILayout.Label("Construction: touch controls or Space to work");
            _touchWorking = GUILayout.RepeatButton("Hold to build", GUILayout.Height(65));
            if (GUILayout.Button("Buy 10 materials (100 coins)", GUILayout.Height(55)))
                Session.Supply(10, 100);
            GUILayout.Label("Stage: " + Session.Stage + " " + Session.Progress.ToString("P0"));
            GUILayout.Label("Cash: " + Session.Cash + " Materials: " + Session.Material);
        }
    }
}
