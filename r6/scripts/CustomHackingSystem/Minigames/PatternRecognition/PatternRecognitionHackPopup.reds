module CustomHackingSystem.Hacks.PatternRecognition
import HackingExtensions.CustomMinigame.*
import Codeware.UI.*

public class PatternRecognitionHackPopup extends CustomMinigameHackPopup
{
	protected let minigameRef:ref<PatternRecognitionHack>;


	public func UseCursor() -> Bool
	{
		return true;
	}

	protected cb func OnCreate() -> Void
	{
		super.OnCreate();
		this.minigameRef.popupParent = this;
		this.minigameRef.Reparent(this.baseWidget);
	}

	protected cb func OnInitialize() -> Void
	{
		super.OnInitialize();
	}

	public static func Show(requester: ref<inkGameController>,minigameSettings: ref<PatternRecognitionHackSettings>) -> Void
	{
		let popup: ref<PatternRecognitionHackPopup> = new PatternRecognitionHackPopup();
		popup.minigameRef = PatternRecognitionHack.Create();
		popup.minigameRef.settings = minigameSettings;
		popup.Open(requester);
	}
}
