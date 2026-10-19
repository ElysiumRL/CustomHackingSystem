module Elysium.Utilities.Message

public class MessageUtilities
{
    public static func DisplaySideNotificationMessage(message: String)
    {
        let simpleScreenMessage: SimpleScreenMessage;

        simpleScreenMessage.isShown = true;
        simpleScreenMessage.duration = 5.00;
        simpleScreenMessage.message = message;
        simpleScreenMessage.isInstant = true;

        GameInstance.GetBlackboardSystem(GetGameInstance())
            .Get(GetAllBlackboardDefs().UI_Notifications)
            .SetVariant(GetAllBlackboardDefs().UI_Notifications.WarningMessage, ToVariant(simpleScreenMessage), true);
    }
}