tool
extends EditorPlugin

var add_ext_info_dial = WindowDialog.new()
var vlist = ItemList.new()
var ln_name = LineEdit.new()
var ln_uri = LineEdit.new()
var btn_priority = CheckButton.new()
var http = HTTPRequest.new()

func create_ext_popup():
	add_ext_info_dial.popup_centered(Vector2(300, 128))

func add_to_ext_db():
	add_ext_info_dial.hide()
	
	if not ln_name.text.length() > 0 and not ln_uri.text.find("https://") > -1:
		print("Invalid arguments")
		return
	
	ExternalServer.register_resource(ln_uri.text, ln_name.text, btn_priority.pressed)
	
	print("Added new External Resource @ %s:%s:%s" % [OS.get_datetime().hour, OS.get_datetime().minute, OS.get_datetime().second])

func remove_ext_info():
	var selecteds = vlist.get_selected_items()
	
	if selecteds.size() > 0:
		var index = selecteds[0]
		
		ExternalServer.erase_resource(index)

func create_external_list_control():
	var panel = PanelContainer.new()
	var layout = VBoxContainer.new()
	var tools = HBoxContainer.new()
	var add_btn = Button.new()
	var remove_btn = Button.new()
	
	panel.add_child(layout)
	layout.add_child(tools)
	layout.add_child(vlist)
	
	tools.add_child(add_btn)
	tools.add_child(remove_btn)
	
	panel.name = "External Database"
	
	add_btn.text = "Add"
	add_btn.connect("button_up", self, "create_ext_popup")
	
	remove_btn.text = "Remove"
	remove_btn.connect("button_up", self, "remove_ext_info")
	
	return panel

func _ready():
	vlist.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vlist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vlist.icon_scale = 0.08
	
	add_ext_info_dial.window_title = "Add External"
	
	var container = MarginContainer.new()
	container.rect_size = add_ext_info_dial.rect_size
	container.anchor_right = 1
	container.anchor_bottom = 1
	container.set("custom_constants/margin_left", 25)
	container.set("custom_constants/margin_right", 25)
	container.set("custom_constants/margin_top", 25)
	container.set("custom_constants/margin_bottom", 25)
	add_ext_info_dial.add_child(container)
	
	container.add_child(VBoxContainer.new())
	
	var vlayout = VBoxContainer.new()	
	container.get_child(0).add_child(vlayout)
	
	vlayout.add_child(HBoxContainer.new())
	vlayout.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vlayout.get_child(0).add_child(Label.new())
	vlayout.get_child(0).add_child(ln_name)
	vlayout.get_child(0).get_child(0).text = "Name:"
	vlayout.get_child(0).get_child(1).rect_min_size.x = 200
	vlayout.get_child(0).get_child(1).placeholder_text = "Identifier resource name"
	
	vlayout.add_child(HBoxContainer.new())
	#vlayout.get_child(1).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vlayout.get_child(1).add_child(Label.new())
	vlayout.get_child(1).add_child(ln_uri)
	vlayout.get_child(1).get_child(0).text = "Https:"
	vlayout.get_child(1).get_child(1).rect_min_size.x = 200
	vlayout.get_child(1).get_child(1).placeholder_text = "https://.../content.<image/model>"
	
	container.get_child(0).add_child(HBoxContainer.new())
	container.get_child(0).get_child(1).add_child(Button.new())
	container.get_child(0).get_child(1).add_child(btn_priority)
	
	container.get_child(0).get_child(1).get_child(0).text = "Create"
	container.get_child(0).get_child(1).get_child(0).connect("button_up", self, "add_to_ext_db")
	
	container.get_child(0).get_child(1).get_child(1).text = "Priority"
	container.get_child(0).get_child(1).get_child(1).pressed = true
	container.get_child(0).get_child(1).get_child(1).hint_tooltip = "Download resource before game starts!"

func reload_dock():
	vlist.clear()
	
	for i in range(ExternalServer.ExternalDB.infos.size()):
		var info: ExternalServer.ExternalInfo = ExternalServer.ExternalDB.infos[i]
		
		vlist.add_item("%s %s > %s" % ["(*)" if info.priority else "#", info.name, info.uri], preload("icon_res.png"))

func _on_external_singleton_updated():
	ExternalServer.update(http)
	
	reload_dock()

func _enter_tree():
	ExternalServer.open_save_db(ExternalServer.EXTERNAL_XT_FILENAME)
	
	http.use_threads = true
	add_child(http)
	
	add_autoload_singleton("ExternalSingleton", "res://addons/gd-xt/core/singleton.gd")
	
	get_editor_interface().get_editor_viewport().add_child(add_ext_info_dial)
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, create_external_list_control())
	
	ExternalSingleton.connect("EXTERNAL_LIST_UPDATED", self, "_on_external_singleton_updated")
	
	print("Plugin Started! Created by QJPG @ Godot.XT")
	ExternalServer.update(http)
	reload_dock()

func _exit_tree():
	remove_autoload_singleton("ExternalSingleton")
	ExternalServer.save_db(ExternalServer.EXTERNAL_XT_FILENAME)
