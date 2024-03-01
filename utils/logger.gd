# class_name Logger extends Node

# static var is_enabled: bool = false

# static var _log_label: RichTextLabel
# static var control: Control = Control.new()
# var _default_rect_min_size: Vector2 = Vector2(1135, 300)

# func _init(_parent: Node):
# 	name = "Logger"
# 	_parent.get_window().add_child.call_deferred(self)
# 	control.size = _default_rect_min_size

# 	control.set_anchors_preset(Control.PRESET_TOP_WIDE)
# 	add_child(control)

# 	_log_label = RichTextLabel.new()
# 	_log_label.bbcode_enabled = true
# 	_log_label.scroll_following = true
# 	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD

# 	# _log_label.mouse_filter = Control.MOUSE_FILTER_PASS
# 	_log_label.set_anchors_preset(Control.PRESET_FULL_RECT)

# 	var panel: Panel = Panel.new()
# 	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

# 	control.add_child(panel)
# 	control.add_child(_log_label)
# 	is_enabled = true

# static func log_label(text: String) -> void:
# 	_log_label.append_text(text)
# 	_log_label.newline()

# static func hide(visible: bool):
# 	control.visible = visible

# static func clear() -> void:
# 	_log_label.clear()
