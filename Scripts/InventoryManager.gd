class_name Inventory_Manager extends Node

var items: Array[InventoryItem] = []

func add_item(item_name: String, amount: int = 1):
	AudioManager.pick_up_sound()
	for item in items:
		if item.item_name == item_name:
			item.item_quantity += amount
			return
			
	var new_item = InventoryItem.new()
	new_item.item_name = item_name
	new_item.item_quantity = amount
	items.append(new_item)
	
func remove_item(item_name: String, amount: int = 1):
	AudioManager.drop_sound()
	for item in items:
		if item.item_name == item_name:
			item.item_quantity -= amount
			
			if item.item_quantity <= 0:
				items.erase(item)
			return
			
func has_item(item_name: String):
	for item in items:
		if item.item_name == item_name and item.item_quantity > 0:
			return true
	return false
	
func get_item_count(item_name: String):
	for item in items:
		if item.item_name == item_name:
			return item.item_quantity
	return 0
	
func print_inventory():
	if items.is_empty():
		print("Inventory is empty")
		return
	for item in items:
		if item == null:
			continue
		print("%s x%d" % [item.item_name, item.item_quantity])
