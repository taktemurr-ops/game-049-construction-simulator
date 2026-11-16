using NUnit.Framework;
using GameStudio.Construction;

public class ConstructionSessionTests
{
    [Test] public void WorkConsumesMaterialsOnlyOncePerStage()
    {
        var s = new ConstructionSession();
        s.Work(1f); Assert.AreEqual(35, s.Material);
        s.Work(1f); Assert.AreEqual(35, s.Material);
    }
    [Test] public void CompletingStageAdvances()
    {
        var s = new ConstructionSession();
        s.Work(10f);
        Assert.AreEqual(BuildStage.Structure, s.Stage);
    }
    [Test] public void InvalidWorkIsRejected()
    {
        var s = new ConstructionSession();
        Assert.IsFalse(s.Work(-1f));
    }
}
