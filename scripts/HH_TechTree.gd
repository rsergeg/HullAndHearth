class_name HH_TechTree
extends Resource

const METAL_COPPER := "copper"
const METAL_TIN := "tin"
const METAL_IRON := "iron"
const METAL_BRONZE := "bronze"

const TIER_WOOD := "wood"
const TIER_STONE := "stone"
const TIER_COPPER := "copper"
const TIER_BRONZE := "bronze"
const TIER_IRON := "iron"

const TOOL_TYPES := ["pickaxe", "axe", "shovel", "sword"]

const ALLOY_RECIPES := {
	METAL_BRONZE: {
		METAL_COPPER: 1,
		METAL_TIN: 1,
	},
}

const CRAFTING_RECIPES := {
	"bed": {
		"fiber": 10,
		"sticks": 8,
	},
	"bow": {
		"wood": 6,
		"string": 4,
	},
}


func get_tier_order() -> Array[String]:
	return [TIER_WOOD, TIER_STONE, TIER_COPPER, TIER_BRONZE, TIER_IRON]


func can_craft_bronze(input_items: Dictionary) -> bool:
	return _has_items(input_items, ALLOY_RECIPES[METAL_BRONZE])


func can_craft(item_id: String, input_items: Dictionary) -> bool:
	if not CRAFTING_RECIPES.has(item_id):
		return false
	return _has_items(input_items, CRAFTING_RECIPES[item_id])


func get_tool_recipe(tier: String, tool_type: String) -> Dictionary:
	if not TOOL_TYPES.has(tool_type):
		return {}

	var material := tier
	if tier == TIER_WOOD:
		return {
			"sticks": 3,
			"wood": 3,
		}

	if tier == TIER_STONE:
		material = "stone"

	return {
		"sticks": 2,
		material: 3,
	}


func _has_items(input_items: Dictionary, requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if input_items.get(item_id, 0) < requirements[item_id]:
			return false
	return true
