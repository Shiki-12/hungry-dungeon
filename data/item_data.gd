class_name ItemData
extends Resource

enum Category {
	INGREDIENT,
	DISH,
	COOKWARE,
	PLATE,
	SNACK
}

@export var id: String = ""
@export var display_name: String = ""
@export var category: Category = Category.INGREDIENT
@export var can_throw: bool = true
@export var components: Array[String] = []
@export var is_burnt: bool = false
@export var rare_id: String = ""
