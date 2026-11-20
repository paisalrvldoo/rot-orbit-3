local Config = {}

Config.StartingMoney = 100
Config.LockDuration = 30
Config.LockCooldown = 60
Config.SpawnInterval = 3.5
Config.RailSpeed = 7
Config.Rarities = {
	Common = { Color = Color3.fromRGB(190, 209, 224), Weight = 48, Price = 40, Income = 2 },
	Uncommon = { Color = Color3.fromRGB(91, 255, 154), Weight = 26, Price = 110, Income = 6 },
	Rare = { Color = Color3.fromRGB(76, 166, 255), Weight = 14, Price = 350, Income = 20 },
	Epic = { Color = Color3.fromRGB(182, 100, 255), Weight = 7, Price = 1100, Income = 65 },
	Legendary = { Color = Color3.fromRGB(255, 201, 65), Weight = 3.5, Price = 4000, Income = 240 },
	Mythic = { Color = Color3.fromRGB(255, 80, 145), Weight = 1.2, Price = 15000, Income = 950 },
	Secret = { Color = Color3.fromRGB(99, 255, 243), Weight = 0.3, Price = 60000, Income = 4000 },
}
Config.TierOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
Config.Characters = {
	{ Name = "Tralalero Orbitino", Rarity = "Common" },
	{ Name = "Spaghettino Sputnik", Rarity = "Common" },
	{ Name = "Ballerina Bananaut", Rarity = "Uncommon" },
	{ Name = "Cappuccino Cometino", Rarity = "Uncommon" },
	{ Name = "Bombardiro Cosmico", Rarity = "Rare" },
	{ Name = "Chimpanzini Moonini", Rarity = "Rare" },
	{ Name = "Tung Tung Saturno", Rarity = "Epic" },
	{ Name = "Frigo Frigo Galactico", Rarity = "Epic" },
	{ Name = "Brr Brr Jupiterino", Rarity = "Legendary" },
	{ Name = "Lirili Larila Nebula", Rarity = "Legendary" },
	{ Name = "La Vacca Supernova", Rarity = "Mythic" },
	{ Name = "Bombombini Blackholini", Rarity = "Mythic" },
	{ Name = "Il Grande Rot Eclipse", Rarity = "Secret" },
	{ Name = "Saturnita Infinita", Rarity = "Secret" },
}
function Config.UpgradeCost(level)
	return math.floor(250 * 1.8 ^ level)
end
function Config.RebirthCost(rebirths)
	return math.floor(10000 * 2 ^ rebirths)
end
function Config.Multiplier(level, rebirths)
	return (1 + level * 0.25) * (1 + rebirths * 0.5)
end
return Config
