extends Area2D

@export var sword_scene: PackedScene:
	set(value):
		sword_scene = value
		if is_inside_tree():
			update_sprite_and_stats()

@export var pickup_range: float = 50.0

var is_hovered: bool = false

# UI References
@onready var sprite: Sprite2D = $Sprite2D
@onready var info_panel: PanelContainer = $CanvasLayer/InfoPanel
@onready var name_label: Label = $CanvasLayer/InfoPanel/VBoxContainer/NameLabel
@onready var damage_label: Label = $CanvasLayer/InfoPanel/VBoxContainer/DamageLabel
@onready var speed_label: Label = $CanvasLayer/InfoPanel/VBoxContainer/SpeedLabel

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	info_panel.visible = false
	update_sprite_and_stats()

func _process(_delta: float) -> void:
	# Keep the UI floating just above the dropped item position on screen
	if is_hovered and info_panel.visible:
		var screen_pos = get_viewport().get_canvas_transform() * get_global_mouse_position()
		info_panel.global_position = screen_pos + Vector2(10, -40) # Offset above item

func update_sprite_and_stats() -> void:
	if sword_scene == null or sprite == null:
		return

	var temp_sword = sword_scene.instantiate()
	
	# 1. Update Sprite Texture
	var temp_sprite = temp_sword.get_node_or_null("Sprite2D")
	if temp_sprite == null:
		temp_sprite = temp_sword.find_child("Sprite2D", true, false) as Sprite2D
		
	if temp_sprite and temp_sprite.texture:
		sprite.texture = temp_sprite.texture

	# 2. Read Stat Variables from Sword Script
	var w_name = temp_sword.get("weapon_name")
	var w_dmg = temp_sword.get("damage")
	var w_speed = temp_sword.get("attack_speed")

	# 3. Update UI Label Text
	name_label.text = str(w_name) if w_name != null else "Unknown Weapon"
	damage_label.text = "DMG: " + str(w_dmg if w_dmg != null else "N/A")
	speed_label.text = "SPD: " + str(w_speed if w_speed != null else "N/A")

	temp_sword.queue_free()

func _on_mouse_entered() -> void:
	is_hovered = true
	modulate = Color(1.3, 1.3, 1.3, 1.0)
	if info_panel:
		info_panel.visible = true

func _on_mouse_exited() -> void:
	is_hovered = false
	modulate = Color.WHITE
	if info_panel:
		info_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_hovered and event.is_action_pressed("reload"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var distance = global_position.distance_to(player.global_position)
			if distance <= pickup_range:
				if player.has_method("swap_sword"):
					player.swap_sword(sword_scene, global_position)
					queue_free()
