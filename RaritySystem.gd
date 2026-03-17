extends Node
class_name RarityClass


enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC
}

var rarity_values = {
	Rarity.COMMON: 48.0,
	Rarity.UNCOMMON: 26.0,
	Rarity.RARE: 18.0,
	Rarity.EPIC: 6.0,
	Rarity.LEGENDARY: 2.0,
	Rarity.MYTHIC: 0.8,
}

var fairness_boost = {
	Rarity.COMMON: {"value": 0.0, "increase": 0.0, "rarity_max": 48.0},
	Rarity.UNCOMMON: {"value": 0.0, "increase": 1, "rarity_max": 42.0},
	Rarity.RARE: {"value": 0.0, "increase": 0.7, "rarity_max": 30.0},
	Rarity.EPIC: {"value": 0.0, "increase": 0.5, "rarity_max": 10.0},
	Rarity.LEGENDARY: {"value": 0.0, "increase": 0.3, "rarity_max": 6.0},
	Rarity.MYTHIC: {"value": 0.0, "increase": 0.1, "rarity_max": 4.0},
}


func get_random_item_by_rarity(items: Array, enum_mode: bool = true, update_fairness_boost: bool = true):
	var rarity = 0.0
	var items_rarity_values: Dictionary
	var total_weight = 0
	
	for item in items:
		if enum_mode:
			rarity = rarity_values[item.rarity] + fairness_boost[item.rarity].value
		else:
			if item.probability_value <= 0.0000:
				rarity = 0.0
			else:
				rarity = item.probability_value + fairness_boost[item.rarity].value
		
		items_rarity_values[item] = rarity
		total_weight += rarity
	
	var roll = randf() * total_weight
	if total_weight <= 0.0: return null
	var cumulative = 0.0
	var picked_item
	for item in items:
		cumulative += items_rarity_values[item]
		if roll <= cumulative:
			picked_item = item
			break
	
	if update_fairness_boost:
		for i in fairness_boost.size():
			var boost = fairness_boost[i]
			if i <= picked_item.rarity:
				boost.value = 0.0
			elif (rarity_values[i] + boost.value) < boost.rarity_max:
				boost.value += boost.increase
			else:
				boost.value = boost.rarity_max - rarity_values[i]
	
	return picked_item
