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

////////////////////////////////////////////////////////////////////////

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