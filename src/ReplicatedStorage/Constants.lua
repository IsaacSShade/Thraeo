local Constants = {}

Constants.STARTING_GOLD_AMOUNT = 200
Constants.BASE_FOUNDATION_NAME = "CastleBase"
Constants.ARCHER_BUILDING_NAME = "ArcherTower"
Constants.WIZARD_BUILDING_NAME = "WizardTower"

Constants.ARCHER_NAME = "Archer"
Constants.WIZARD_NAME = "Wizard"

Constants.BUILDING_COSTS = {
	[Constants.ARCHER_BUILDING_NAME] = 100,
	[Constants.WIZARD_BUILDING_NAME] = 200
}

Constants.KILL_REWARDS = {
	[Constants.ARCHER_NAME] = 10,
	[Constants.WIZARD_NAME] = 15,
	[Constants.ARCHER_BUILDING_NAME] = 100,
	[Constants.WIZARD_BUILDING_NAME] = 150
}

Constants.BUILDING_HEALTH = {
	[Constants.ARCHER_BUILDING_NAME] = 400,
	[Constants.WIZARD_BUILDING_NAME] = 300
}

return Constants
