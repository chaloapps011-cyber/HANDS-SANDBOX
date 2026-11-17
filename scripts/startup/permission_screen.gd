extends CanvasLayer
## First-launch Android permission explanation. Camera is requested only after explicit Continue.
## Microphone is informational only and is never requested.
signal completed

const TRACKING_SINGLETON := "HandsTracking"
const PREFS_PATH := "user://startup_permissions.cfg"
const REQUEST_WAIT_SECONDS := 3.0

var _camera_state: Label
var _audio_state: Label
var _continue_button: Button
var _plugin: Object
var _camera_request_pending := false
var _request_elapsed := 0.0
var _finished := false
var _camera_request_attempted := false
var _continue_without_camera := false

func _ready() -> void:
	layer = 100
	_build_screen()
	if Engine.has_singleton(TRACKING_SINGLETON):
		_plugin = Engine.get_singleton(TRACKING_SINGLETON)
	_update_states()
	# Skip the intro on later launches only when camera access is already granted.
	if _has_completed_intro() and _camera_is_granted():
		_finish()

func _process(delta: float) -> void:
	if not _camera_request_pending:
		return
	_request_elapsed += delta
	_update_states()
	if _camera_is_granted():
		_finish()
	elif _request_elapsed >= REQUEST_WAIT_SECONDS:
		# Android does not expose a reliable denied-vs-dialog-open status through this bridge.
		# Keep the user in control and offer an explicit continue-without-camera option.
		_camera_request_pending = false
		_continue_without_camera = true
		_continue_button.disabled = false
		_continue_button.text = "Continuar sem câmera"
		_camera_state.text = "Não concedida; o rastreamento ficará indisponível"

func _build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color(0.035, 0.055, 0.075, 0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.10, 0.14, 0.19, 1.0)
	panel_style.set_corner_radius_all(18)
	panel_style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	var title := Label.new()
	title.text = "Permissões do HANDS SANDBOX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	var camera_card := _make_permission_card("📷", "Vídeo (câmera)", "A câmera frontal é usada para o rastreamento real das mãos.")
	_camera_state = camera_card.get_node("State")
	content.add_child(camera_card)

	var audio_card := _make_permission_card("🎙", "Áudio (microfone)", "O microfone não é utilizado; nenhum acesso será solicitado.")
	_audio_state = audio_card.get_node("State")
	content.add_child(audio_card)

	_continue_button = Button.new()
	_continue_button.text = "Continuar"
	_continue_button.custom_minimum_size = Vector2(0, 58)
	_continue_button.add_theme_font_size_override("font_size", 22)
	_continue_button.pressed.connect(_on_continue_pressed)
	content.add_child(_continue_button)

func _make_permission_card(icon_text: String, permission_name: String, description: String) -> VBoxContainer:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := Label.new()
	icon.text = icon_text
	icon.custom_minimum_size = Vector2(48, 48)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 30)
	row.add_child(icon)
	var name_label := Label.new()
	name_label.text = permission_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 21)
	row.add_child(name_label)
	var description_label := Label.new()
	description_label.text = description
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(description_label)
	var state := Label.new()
	state.name = "State"
	state.text = "Verificando…"
	state.add_theme_color_override("font_color", Color(0.70, 0.82, 0.90))
	card.add_child(state)
	return card

func _on_continue_pressed() -> void:
	if _finished:
		return
	if _camera_is_granted() or _plugin == null or _continue_without_camera:
		_finish()
		return
	if _camera_request_pending or _camera_request_attempted:
		return
	_camera_request_attempted = true
	_plugin.request_camera_permission()
	_camera_request_pending = true
	_request_elapsed = 0.0
	_continue_button.disabled = true
	_continue_button.text = "Aguardando Android…"
	_camera_state.text = "Aguardando resposta do sistema Android"

func _camera_is_granted() -> bool:
	return _plugin != null and bool(_plugin.has_camera_permission())

func _update_states() -> void:
	if _camera_state != null:
		if _plugin == null:
			_camera_state.text = "Plugin Android indisponível" if OS.has_feature("android") else "Disponível somente no Android"
		else:
			_camera_state.text = "Concedida" if _camera_is_granted() else "Não concedida"
	if _audio_state != null:
		_audio_state.text = "Não solicitada (microfone não utilizado)"

func _has_completed_intro() -> bool:
	var config := ConfigFile.new()
	if config.load(PREFS_PATH) != OK:
		return false
	return bool(config.get_value("permissions", "intro_completed", false))

func _finish() -> void:
	if _finished:
		return
	_finished = true
	var config := ConfigFile.new()
	config.set_value("permissions", "intro_completed", true)
	config.save(PREFS_PATH)
	completed.emit()
	queue_free()
