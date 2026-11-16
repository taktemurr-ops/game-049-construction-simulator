# Construction Simulator

Game Studio 100 | Android + iOS | Unity C# | **prototype in progress**

## Current implemented source

ordered construction stages, spending/material inventory, work progress and completion rewards, keyboard prototype.

- Gameplay implementation: `Assets/Scripts/ConstructionSession.cs`
- Unit/EditMode test source: `Assets/Tests/EditMode/ConstructionSessionTests.cs`
- Unity MonoBehaviour prototype with minimal OnGUI or keyboard controls
- Gameplay and EditMode test assembly definitions included.
 
**Verification status:** source and test cases are committed, but compilation, test execution,
device builds and complete gameplay verification have NOT been performed.
For Unity, create/open a compatible Unity project, install Unity Test Framework, and attach the prototype MonoBehaviour to an active GameObject in a scene. A complete Unity project, scene assets and store-ready packages are not yet provided.

## Remaining development

- Game design research: supported competitor feature matrix and user experience improvements
- Full playable levels, UI/UX polish, audio, animations, save/resume and accessibility
- Multiple modes, progression, difficulty and content tooling
- Device testing, CI, privacy permissions and compliant ads/in-app purchases
- Android and iOS release builds and store verification

This is an original prototype, NOT a finished production game.
