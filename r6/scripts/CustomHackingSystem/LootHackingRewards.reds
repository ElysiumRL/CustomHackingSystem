module HackingExtensions.Programs

//Template module with functions used to simulate what datamine programs would do (but in our custom minigame instance)
//Implementation is in HackPrograms.reds

public struct CustomLootReward
{
	let lootTDBID:TweakDBID;
	let amount:Uint32;
	let useGameAmountMultiplier:Bool;
	let useGameAmountRandomizer:Bool;
}

public struct CustomQueryLootReward
{
	let lootQueryTDBID:TweakDBID;
	let amount:Uint32;
	let useGameAmountMultiplier:Bool;
	let useGameAmountRandomizer:Bool;
}

enum EMoneyRewardAmountMultiplier
{
	VeryLow = 0,
	Low = 1,
	High = 2,
}

public class LootRewardProgramActions extends HackProgramAction
{
	protected let m_rewardNotificationIcons: array<String>;
  	protected let m_rewardNotificationString: String;

	protected func Execute() -> Void {};

	//Loot function from Access Points (used for the DatamineV1-2-3 programs)
	private final func ProcessNetworkLoot(baseMoney: Float, baseUncommonMaterials: Float, baseRareMaterials: Float, baseEpicMaterials: Float, baseLegendaryMaterials: Float, TS: ref<TransactionSystem>) -> Void
	{
		this.ClearRewardNotification();
		
		this.GenerateMaterialDrops(baseUncommonMaterials, baseRareMaterials, baseEpicMaterials, baseLegendaryMaterials, TS);
		if baseMoney != 0.00
		{
		  	this.AddRewardMoney(baseMoney);
		}
		this.ShowRewardNotification();
  	}

	//Gives money as a reward for the player
	private final func AddRewardMoney(baseMoney: Float,opt amountModifier: EMoneyRewardAmountMultiplier,opt overrideMoneyMultiplier:Float) -> Void 
	{
		let moneyModifier:Float = overrideMoneyMultiplier;
		if(overrideMoneyMultiplier != 0.00)
		{
			moneyModifier = GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayer().GetEntityID()), gamedataStatType.MinigameMoneyMultiplier);
		}

		let rewardID: TweakDBID;

		switch EnumInt(amountModifier)
		{
			case 0:
				rewardID = t"QuestRewards.MinigameMoneyVeryLow";
			break;
			case 1:
				rewardID = t"QuestRewards.MinigameMoneyLow";
			break;
			case 2:
				rewardID = t"QuestRewards.MinigameMoneyHigh";
			break;
			default:
				rewardID = t"QuestRewards.MinigameMoneyVeryLow";
			break;
		}
		
		
		RPGManager.GiveReward(this.gameInstance, rewardID, Cast<StatsObjectID>(this.GetPlayer().GetEntityID()), baseMoney * moneyModifier);
	}

	//Game internal function processing material drop scaling
  	private final func GenerateMaterialDrops(baseUncommonMaterials: Float, baseRareMaterials: Float, baseEpicMaterials: Float, baseLegendaryMaterials: Float, TS: ref<TransactionSystem>) -> Void 
	{
		let dropChanceMaterial: Float;
		let materialsAmmountEpic: Int32;
		let materialsAmmountLeg: Int32;
		let materialsAmmountRare: Int32;
		let materialsMultiplier: Float = GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayer().GetEntityID()), gamedataStatType.MinigameMaterialsEarned);
		let materialsAmmountUnc: Int32 = RandRange(Cast<Int32>(baseUncommonMaterials) / 3, Cast<Int32>(baseUncommonMaterials) + 1);
		this.AddRewardByItemQuery(TS, t"Query.QuickHackUncommonMaterial", Cast<Uint32>(RoundMath(Cast<Float>(materialsAmmountUnc) * materialsMultiplier)));
		materialsAmmountRare = RandRange(Cast<Int32>(baseRareMaterials) / 3, Cast<Int32>(baseRareMaterials) + 1);
		this.AddRewardByItemQuery(TS, t"Query.QuickHackRareMaterial", Cast<Uint32>(RoundMath(Cast<Float>(materialsAmmountRare) * materialsMultiplier)));
		materialsAmmountEpic = RandRange(Cast<Int32>(baseEpicMaterials) / 2, Cast<Int32>(baseEpicMaterials) + 1);
		this.AddRewardByItemQuery(TS, t"Query.QuickHackEpicMaterial", Cast<Uint32>(RoundMath(Cast<Float>(materialsAmmountEpic) * materialsMultiplier)));

		dropChanceMaterial = RandF() * materialsMultiplier;
		if dropChanceMaterial > 0.33 - 0.05 * baseLegendaryMaterials 
		{
		  	materialsAmmountLeg = RandRange(Cast<Int32>(baseLegendaryMaterials) / 2, Cast<Int32>(baseLegendaryMaterials) + 1);
		  	this.AddRewardByItemQuery(TS, t"Query.QuickHackLegendaryMaterial", Cast<Uint32>(RoundMath(Cast<Float>(materialsAmmountLeg) * materialsMultiplier)));
		};
  	}
	//Game internal function processing loot drop & the "EXTRACTING DATA..." UI panel
	//Use AddReward() instead
  	private final func AddRewardByItemQuery(TS: ref<TransactionSystem>, itemQueryTDBID: TweakDBID, opt amount: Uint32) -> Void 
  	{
		let iconName: String;
		let iconsNameResolver: ref<IconsNameResolver>;
		let itemRecord: ref<Item_Record>;
		let itemRecordID: TweakDBID;
		let itemTypeRecordName: CName;
		if amount > 0u 
		{
	 		itemTypeRecordName = TweakDBInterface.GetItemQueryRecord(itemQueryTDBID).RecordType();
	 		itemRecordID = TDBID.Create(NameToString(itemTypeRecordName));
	 		itemRecord = TweakDBInterface.GetItemRecord(itemRecordID);
	 		iconsNameResolver = IconsNameResolver.GetIconsNameResolver();
	 		iconName = itemRecord.IconPath();

	 		if !IsStringValid(iconName) 
	 		{
				iconName = NameToString(iconsNameResolver.TranslateItemToIconName(itemRecordID, true));
	 		}

	 		if NotEquals(iconName, "None") && NotEquals(iconName, "") 
	 		{
				ArrayPush(this.m_rewardNotificationIcons, iconName);
	 		}

	 		this.m_rewardNotificationString += GetLocalizedTextByKey(itemRecord.DisplayName());
	 		if StrLen(this.m_rewardNotificationString) > 0 
			{
				this.m_rewardNotificationString += "\\n";
	 		}

	 		//18446744073709551615ul - Game default seed
	 		TS.GiveItemByItemQuery(this.GetPlayer(), itemQueryTDBID, amount, 18446744073709551615ul, "minigame");
		}
  	}
	//Game internal function processing loot drop & the "EXTRACTING DATA..." UI panel but modified to accept items instead of itemQueries
	//Use AddReward() instead
 	private final func AddRewardByItemTDBID(TS: ref<TransactionSystem>, itemTDBID: TweakDBID, opt amount: Uint32) -> Void 
  	{
		let iconName: String;
		let iconsNameResolver: ref<IconsNameResolver>;
		let itemRecord: ref<Item_Record>;
		if amount > 0u
		{
	 		itemRecord = TweakDBInterface.GetItemRecord(itemTDBID);
	 		iconsNameResolver = IconsNameResolver.GetIconsNameResolver();
	 		iconName = itemRecord.IconPath();

	 		if !IsStringValid(iconName) 
	 		{
				iconName = NameToString(iconsNameResolver.TranslateItemToIconName(itemTDBID, true));
	 		}

	 		if NotEquals(iconName, "None") && NotEquals(iconName, "") 
	 		{
				ArrayPush(this.m_rewardNotificationIcons, iconName);
	 		}

	 		this.m_rewardNotificationString += GetLocalizedTextByKey(itemRecord.DisplayName());
	 		if StrLen(this.m_rewardNotificationString) > 0 
			{
				this.m_rewardNotificationString += "\\n";
	 		}

			TS.GiveItemByTDBID(this.GetPlayer(), itemTDBID,Cast<Int32>(amount));
		}
  	}

	//Gives a reward to the player with the Datamine V1-V2-V3 success notification
	//This version is accepting LootReward (with item TweakDBID)
 	private final func AddReward(TS: ref<TransactionSystem>,lootReward:array<CustomLootReward>) -> Void 
  	{
		this.ClearRewardNotification();

		for loot in lootReward
		{
			let newAmount:Uint32 = loot.amount;

			if(loot.useGameAmountRandomizer)
			{
				newAmount = this.RandomizeLootAmount(newAmount);
			}
			if(loot.useGameAmountMultiplier)
			{
				newAmount = this.MultiplyLootAmount(newAmount);
			}

			this.AddRewardByItemTDBID(TS,loot.lootTDBID,newAmount);
		}

		this.ShowRewardNotification();
  	}

	//Gives a reward to the player with the Datamine V1-V2-V3 success notification
	//This version is accepting LootQueryReward (with itemQuery TweakDBID)
 	private final func AddReward(TS: ref<TransactionSystem>, queryLootReward:array<CustomQueryLootReward>) -> Void 
  	{
		this.ClearRewardNotification();

		for loot in queryLootReward
		{
			let newAmount:Uint32 = loot.amount;

			if(loot.useGameAmountRandomizer)
			{
				newAmount = this.RandomizeLootAmount(newAmount);
			}
			if(loot.useGameAmountMultiplier)
			{
				newAmount = this.MultiplyLootAmount(newAmount);
			}
		
			this.AddRewardByItemQuery(TS,loot.lootQueryTDBID,newAmount);
		}
		this.ShowRewardNotification();

  	}

	private final func MultiplyLootAmount(amount:Uint32) -> Uint32
	{
		let lootMultiplier: Float = GameInstance.GetStatsSystem(this.gameInstance).GetStatValue(Cast<StatsObjectID>(this.GetPlayer().GetEntityID()), gamedataStatType.MinigameMaterialsEarned);
		return Cast<Uint32>(RoundMath(Cast<Float>(amount) * lootMultiplier));
	}

	private final func RandomizeLootAmount(amount:Uint32) -> Uint32
	{
		return Cast<Uint32>(RandRange(Cast<Int32>(amount) / 3, Cast<Int32>(amount) + 1));
	}

	//Resets the UI reward notification data
  	private final func ClearRewardNotification() -> Void 
  	{
		this.m_rewardNotificationString = "";
		ArrayClear(this.m_rewardNotificationIcons);
		//LogChannel(n"DEBUG","Reward Notification Cleared");
  	}
	//Displays the UI reward notification
  	private final func ShowRewardNotification() -> Void 
  	{
		let notificationEvent: ref<HackingRewardNotificationEvent>;
		let uiSystem: ref<UISystem>;
		if StrLen(this.m_rewardNotificationString) > 0 
		{
		  	uiSystem = GameInstance.GetUISystem(this.gameInstance);
		  	notificationEvent = new HackingRewardNotificationEvent();
		  	notificationEvent.m_text = this.m_rewardNotificationString;
		  	notificationEvent.m_icons = this.m_rewardNotificationIcons;
		  	uiSystem.QueueEvent(notificationEvent);
			//LogChannel(n"DEBUG","Reward Notification Queued");
		}
  	}

}
