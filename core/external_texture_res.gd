tool
extends ImageTexture

class_name XTImage, "../icon_res.png"

export(String) var name = "" setget set_texture_by_name

func set_texture_by_name(_name: String):
	var ext = ExternalServer.find_resource(_name)
	
	if ext:
		name = _name
		create_from_image(ext)
		
		return
	
	create_from_image(preload("../icon.png").get_data())
	print("Not found")

func _on_external_list_updated():
	var founded_my_item = null
	
	for item in ExternalServer.ExternalDB.infos:
		if item.name == name:
			founded_my_item = item
			break
	
	if not founded_my_item:
		print("Resource not loaded yet")
		create_from_image(preload("../icon.png").get_data())

func _init():
	resource_local_to_scene = true
	if not ExternalSingleton.is_connected("EXTERNAL_LIST_UPDATED", self, "_on_external_list_updated"):
		ExternalSingleton.connect("EXTERNAL_LIST_UPDATED", self, "_on_external_list_updated")
