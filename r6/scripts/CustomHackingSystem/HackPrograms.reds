module HackingExtensions.Programs

import HackingExtensions.*

//Base Program Action script. your custom Program Action should extend from this
public abstract class HackProgramAction extends IScriptable
{
	//Game Instance
	let gameInstance:GameInstance;

	//Settings from main CustomHackingSystem class. Useful when you want to get additional data
	let hackInstanceSettings:ref<CustomHackingProperties>;

	//Override this method to add a custom script behaviour to your Program Action
	protected func ExecuteProgramSuccess() -> Void
	{
		//LogChannel(n"DEBUG","Dummy Program Success");
	}

	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Dummy Program Failed");
	}

	//Returns Player Puppet
	protected final const func GetPlayer() -> ref<PlayerPuppet>
	{
		if(!GameInstance.IsValid(this.gameInstance))
		{
			LogChannel(n"DEBUG","[Custom Hacking System] GameInstance passed is Not Valid (HackProgramAction)");
		}
		return GetPlayer(this.gameInstance);
	}

	protected final const func GetPlayerPS() -> ref<PlayerPuppetPS>
	{
		if(!GameInstance.IsValid(this.gameInstance))
		{
			LogChannel(n"DEBUG","[Custom Hacking System] GameInstance passed is Not Valid (HackProgramAction)");
		}

		return GetPlayer(this.gameInstance).GetPS();
	}

	protected final const func GetPlayerID() -> EntityID
	{
		return this.GetPlayer().GetEntityID();
	}
}


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

//Game base programs

//DatamineV1 Program
public class NetworkLootBasicRewardProgramAction extends LootRewardProgramActions
{
	protected func ExecuteProgramSuccess() -> Void
	{
		//LogChannel(n"DEBUG","NetworkLootBasicReward Executed");
		let transactionSystem:ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);

		//Default Values gained from the Access Points, Shards removed
		this.ProcessNetworkLoot(1.00, 6.00, 3.00, 1.00, 0.00, transactionSystem);
	}

	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Loot Basic Failed");
	}

}

//DatamineV2 Program
public class NetworkLootAdvancedRewardProgramAction extends LootRewardProgramActions
{
	protected func ExecuteProgramSuccess() -> Void
	{
		//LogChannel(n"DEBUG","NetworkLootAdvancedReward Executed");
		let transactionSystem:ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);

		//Default Values gained from the Access Points, Shards removed
		this.ProcessNetworkLoot(2.00, 9.00, 5.00, 2.00, 1.00, transactionSystem);
	}
	
	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Loot Advanced Failed");
	}

}

//DatamineV3 Program
public class NetworkLootMasterRewardProgramAction extends LootRewardProgramActions
{
	protected func ExecuteProgramSuccess() -> Void
	{
		//LogChannel(n"DEBUG","NetworkLootMasterReward Executed");
		let transactionSystem:ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);

		//Default Values gained from the Access Points, Shards removed
		this.ProcessNetworkLoot(3.00, 12.00, 8.00, 3.00, 2.00, transactionSystem);
	}

	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Loot Master Failed");
	}

}

//Gain Access Program (Game "default" program)
public class GainAccessRewardProgramAction extends HackProgramAction
{
	protected func ExecuteProgramSuccess() -> Void
	{
		//LogChannel(n"DEBUG","Gain Access Program Executed");
	}

	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Gain Access Program Failed");
	}

}

////////////////////////////////////////////////////////////////////////

//Custom addons

public class NutRingProgramAction extends LootRewardProgramActions
{
	protected func ExecuteProgramSuccess() -> Void
	{
		let ts:ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.gameInstance);

		//5 "Moore Tech Berserk Mk.1", without game amount scaling & without game amount randomizer
		let loot:CustomLootReward = new CustomLootReward(t"Items.BerserkC1MK1",5u,false,false);

		//Gives the reward to the player & displays UI
		this.AddReward(ts, [loot]);
	}

	protected func ExecuteProgramFailure() -> Void
	{
		//LogChannel(n"DEBUG","Nuts Failed");
	}

}