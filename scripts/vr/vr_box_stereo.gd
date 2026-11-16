extends Node
## Side-by-side stereoscopic compositor for passive phone viewers (VR Box).
## This is not an OpenXR headset integration and has no lens correction/head tracking.

signal vr_mode_changed(enabled: bool)
signal ipd_changed(meters: float)

const DEFAULT_IPD := 0.064
const MIN_IPD := 0.045
const MAX_IPD := 0.080
const IPD_STEP := 0.001

var source_camera: Camera3D
var vr_enabled := false
var ipd_meters := DEFAULT_IPD
var _left_viewport: SubViewport
var _right_viewport: SubViewport
var _left_camera: Camera3D
var _right_camera: Camera3D
var _compositor: CanvasLayer
var _left_image: TextureRect
var _right_image: TextureRect
var _viewport_size := Vector2i.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_stereo_targets()
	get_viewport().size_changed.connect(_resize_targets)
	_resize_targets()
	set_vr_enabled(false)

func _process(_delta: float) -> void:
	if not vr_enabled or source_camera == null or not is_instance_valid(source_camera):
		return
	var basis := source_camera.global_basis.orthonormalized()
	var center := source_camera.global_position
	var half_ipd := ipd_meters * 0.5
	_left_camera.global_transform = Transform3D(basis, center - basis.x * half_ipd)
	_right_camera.global_transform = Transform3D(basis, center + basis.x * half_ipd)
	_left_camera.fov = source_camera.fov
	_right_camera.fov = source_camera.fov
	_left_camera.near = source_camera.near
	_right_camera.near = source_camera.near
	_left_camera.far = source_camera.far
	_right_camera.far = source_camera.far

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_V:
				set_vr_enabled(not vr_enabled)
				get_viewport().set_input_as_handled()
			KEY_MINUS, KEY_KP_SUBTRACT:
				adjust_ipd(-IPD_STEP)
				get_viewport().set_input_as_handled()
			KEY_EQUAL, KEY_KP_ADD:
				adjust_ipd(IPD_STEP)
				get_viewport().set_input_as_handled()

func _build_stereo_targets() -> void:
	var root_viewport := get_viewport()
	_left_viewport = SubViewport.new()
	_left_viewport.name = "LeftEyeViewport"
	_left_viewport.disable_3d = false
	_left_viewport.world_3d = root_viewport.world_3d
	_left_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_left_viewport)
	_right_viewport = SubViewport.new()
	_right_viewport.name = "RightEyeViewport"
	_right_viewport.disable_3d = false
	_right_viewport.world_3d = root_viewport.world_3d
	_right_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_right_viewport)

	_left_camera = Camera3D.new()
	_left_camera.name = "LeftEyeCamera"
	_left_camera.current = true
	_left_viewport.add_child(_left_camera)
	_right_camera = Camera3D.new()
	_right_camera.name = "RightEyeCamera"
	_right_camera.current = true
	_right_viewport.add_child(_right_camera)

	_compositor = CanvasLayer.new()
	_compositor.name = "StereoCompositor"
	_compositor.layer = 20
	add_child(_compositor)
	_left_image = _make_eye_image("LeftEyeImage", _left_viewport)
	_right_image = _make_eye_image("RightEyeImage", _right_viewport)
	_compositor.add_child(_left_image)
	_compositor.add_child(_right_image)

func _make_eye_image(image_name: String, eye_viewport: SubViewport) -> TextureRect:
	var image := TextureRect.new()
	image.name = image_name
	image.texture = eye_viewport.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image

func _resize_targets() -> void:
	if _left_viewport == null:
		return
	var size := get_viewport().get_visible_rect().size
	var full_size := Vector2i(maxi(2, int(size.x)), maxi(2, int(size.y)))
	var eye_size := Vector2i(maxi(1, full_size.x / 2), full_size.y)
	if eye_size == _viewport_size:
		return
	_viewport_size = eye_size
	_left_viewport.size = eye_size
	_right_viewport.size = eye_size
	_left_image.anchor_left = 0.0
	_left_image.anchor_top = 0.0
	_left_image.anchor_right = 0.5
	_left_image.anchor_bottom = 1.0
	_right_image.anchor_left = 0.5
	_right_image.anchor_top = 0.0
	_right_image.anchor_right = 1.0
	_right_image.anchor_bottom = 1.0
	_left_image.offset_left = 0
	_left_image.offset_top = 0
	_left_image.offset_right = 0
	_left_image.offset_bottom = 0
	_right_image.offset_left = 0
	_right_image.offset_top = 0
	_right_image.offset_right = 0
	_right_image.offset_bottom = 0

func set_vr_enabled(enabled: bool) -> void:
	vr_enabled = enabled
	if _compositor != null:
		_compositor.visible = enabled
	if _left_viewport != null:
		_left_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
		_right_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if enabled else SubViewport.UPDATE_DISABLED
	if source_camera != null and is_instance_valid(source_camera):
		source_camera.current = not enabled
	vr_mode_changed.emit(enabled)

func toggle_vr() -> void:
	set_vr_enabled(not vr_enabled)

func adjust_ipd(delta_meters: float) -> void:
	ipd_meters = clampf(ipd_meters + delta_meters, MIN_IPD, MAX_IPD)
	ipd_changed.emit(ipd_meters)

func set_ipd(meters: float) -> void:
	ipd_meters = clampf(meters, MIN_IPD, MAX_IPD)
	ipd_changed.emit(ipd_meters)
