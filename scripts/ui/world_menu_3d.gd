extends Node3D
## Functional world-space menu. Input is tested by a camera ray against 3D button colliders.
const PhysicalObject = preload("res://scripts/objects/physical_object.gd")

var world: Node3D
var camera: Camera3D
var current_page := "main"
var _button_root: Node3D
var _process_mode_before_pause := Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_button_root = Node3D.new()
	_button_root.name = "WorldMenuButtons"
	add_child(_button_root)
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera != null:
		reparent(camera)
		position = Vector3(0.62, 0.15, -1.15)
		rotation = Vector3.ZERO
	show_page("main")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_activate_at(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_activate_at(event.position)

func show_page(page: String) -> void:
	current_page = page
	for child in _button_root.get_children():
		child.queue_free()
	match page:
		"main":
			_add_button("Criar", "create", Vector3(0, 0.36, 0))
			_add_button("Inventário", "inventory", Vector3(0, 0.12, 0))
			_add_button("Ferramentas", "tools", Vector3(0, -0.12, 0))
			_add_button("Configurações", "settings", Vector3(0, -0.36, 0))
			_add_button("Propriedades", "properties", Vector3(0, -0.60, 0))
			_add_button("Pausar", "pause", Vector3(0, -0.84, 0))
		"create":
			_add_button("Cubo", "spawn_cube", Vector3(0, 0.28, 0))
			_add_button("Esfera", "spawn_sphere", Vector3(0, 0.04, 0))
			_add_button("Cilindro", "spawn_cylinder", Vector3(0, -0.20, 0))
			_add_button("Bloco placa", "spawn_baseplate", Vector3(0, -0.44, 0))
			_add_button("Voltar", "main", Vector3(0, -0.74, 0))
		"inventory":
			_add_inventory_labels()
			_add_button("Voltar", "main", Vector3(0, -0.84, 0))
		"tools":
			_add_button("Selecionar", "tool_select", Vector3(0, 0.20, 0))
			_add_button("Agarrar", "tool_grab", Vector3(0, -0.08, 0))
			_add_button("Agrupar", "tool_group", Vector3(0, -0.36, 0))
			_add_button("Voltar", "main", Vector3(0, -0.70, 0))
		"settings":
			_add_button("Gravidade alternar", "toggle_gravity", Vector3(0, 0.15, 0))
			_add_button("Voltar", "main", Vector3(0, -0.25, 0))
		"properties":
			_add_properties()
			_add_button("Voltar", "main", Vector3(0, -0.84, 0))
		"paused":
			_add_label("Jogo pausado", Vector3(0, 0.20, 0))
			_add_button("Retomar", "resume", Vector3(0, -0.12, 0))

func _add_button(label: String, action: String, at: Vector3) -> void:
	var area := Area3D.new()
	area.position = at
	area.set_meta("menu_action", action)
	area.collision_layer = 0
	area.collision_mask = 0
	area.input_ray_pickable = true
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.46, 0.18, 0.08)
	shape_node.shape = shape
	area.add_child(shape_node)
	var visual := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape.size
	visual.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.13, 0.22, 0.30, 0.94)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual.material_override = material
	area.add_child(visual)
	var text := Label3D.new()
	text.text = label
	text.font_size = 24
	text.position = Vector3(0, 0, 0.046)
	text.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	area.add_child(text)
	_button_root.add_child(area)

func _add_label(text_value: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.font_size = 24
	label.position = at
	_button_root.add_child(label)

func _add_inventory_labels() -> void:
	if world == null:
		return
	var index := 0
	for item in get_tree().get_nodes_in_group("sandbox_objects"):
		_add_label(str(item.get_meta("sandbox_object_id", item.name)), Vector3(0, 0.45 - index * 0.13, 0))
		index += 1
		if index >= 5:
			break
	if index == 0:
		_add_label("Inventário vazio", Vector3(0, 0.15, 0))

func _add_properties() -> void:
	var selected: RigidBody3D = world.selected_object if world != null else null
	if selected == null or not is_instance_valid(selected):
		_add_label("Nenhum objeto selecionado", Vector3(0, 0.18, 0))
		return
	_add_label("ID: " + str(selected.get_meta("sandbox_object_id", selected.name)), Vector3(0, 0.42, 0))
	_add_label("Massa: %.2f" % selected.mass, Vector3(0, 0.20, 0))
	_add_label("Posição: %.1f, %.1f, %.1f" % [selected.global_position.x, selected.global_position.y, selected.global_position.z], Vector3(0, -0.02, 0))

func _activate_at(screen_position: Vector2) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 5.0)
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	if not (collider is Area3D) or not collider.has_meta("menu_action"):
		return
	_accept_event(str(collider.get_meta("menu_action")))
	get_viewport().set_input_as_handled()

func _accept_event(action: String) -> void:
	match action:
		"main", "create", "inventory", "tools", "settings", "properties":
			show_page(action)
		"pause":
			get_tree().paused = true
			show_page("paused")
		"resume":
			get_tree().paused = false
			show_page("main")
		"toggle_gravity":
			if world != null:
				world.gravity_enabled = not world.gravity_enabled
				ProjectSettings.set_setting("physics/3d/default_gravity", 9.8 if world.gravity_enabled else 0.0)
			show_page("settings")
		"tool_select", "tool_grab", "tool_group":
			if world != null:
				world.active_tool = action.trim_prefix("tool_")
			show_page("tools")
		"spawn_cube": _spawn(PhysicalObject.ShapeType.CUBE)
		"spawn_sphere": _spawn(PhysicalObject.ShapeType.SPHERE)
		"spawn_cylinder": _spawn(PhysicalObject.ShapeType.CYLINDER)
		"spawn_baseplate": _spawn(PhysicalObject.ShapeType.BASEPLATE_BLOCK)

func _spawn(shape_type: int) -> void:
	if world == null or camera == null:
		return
	var at := camera.global_position + (-camera.global_transform.basis.z * 2.0)
	at.y = maxf(at.y, 0.8)
	world.spawn_physical_object(shape_type, at)
	show_page("create")
