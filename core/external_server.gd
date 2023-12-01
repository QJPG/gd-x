extends Object

class_name ExternalServer, "../icon_res.png"

const EXTERNAL_XT_FILENAME = "res://resources.xt"

class ExternalInfo:
	var name: String
	var id: int
	var resource: Resource = null
	var uri: String
	var priority: bool
	
	func _init(_name: String, _uri: String, _priority: bool):
		randomize()
		
		self.name = _name
		self.uri = _uri
		self.id = randi()
		self.priority = _priority

class ExternalDB:
	const infos = []
	const inThreads = []

static func register_resource(uri: String, name: String, priority: bool = true) -> void:
	for item in ExternalDB.infos:
		if item.name == name:
			OS.alert("External identifier name duplicated!", "External Server")
			return
	
	var info = ExternalInfo.new(name, uri, priority)
	ExternalDB.infos.append(info)
	
	ExternalSingleton.emit_signal("EXTERNAL_LIST_UPDATED")

static func erase_resource(index: int) -> void:
	if index < ExternalDB.infos.size():
		ExternalDB.infos.remove(index)
	
	ExternalSingleton.emit_signal("EXTERNAL_LIST_UPDATED")

static func open_save_db(file: String) -> void:
	var xtfile = ConfigFile.new()
	xtfile.load(file)
	
	for index in range(xtfile.get_sections().size()):
		var name = xtfile.get_sections()[index] as String
		
		var values = xtfile.get_section_keys(name) as PoolStringArray
		var info = ExternalInfo.new("", "", false) as ExternalInfo #just interface clone
		
		for value_index in range(values.size()):
			var real_value = xtfile.get_value(name, values[value_index], null) as String
			var value = values[value_index]
			
			if value == "name":
				info.name = real_value
			elif value == "uri":
				info.uri = real_value
			elif value == "priority":
				info.priority = bool(real_value)
		
		register_resource(info.uri, info.name, info.priority)
	
	print("Loaded xtfile data")

static func save_db(file: String) -> void: #call before update
	var xtfile = ConfigFile.new()
	
	for item in ExternalDB.infos:
		xtfile.set_value(item.name, "name", item.name)
		#xtfile.set_value(item.name, "id", item.id)
		xtfile.set_value(item.name, "uri", item.uri)
		xtfile.set_value(item.name, "priority", item.priority)
	
	xtfile.save(file)
	print("Saved xtfile data")

static func update(http: HTTPRequest) -> void:
	for item in ExternalDB.infos:
		#var xtr = Thread.new()
		#xtr.start(ExternalSingleton, "_make_get", [http, item], Thread.PRIORITY_HIGH)
		#ExternalDB.inThreads.append(xtr)
		
		if http.request(item.uri, PoolStringArray([]), true, HTTPClient.METHOD_GET) != OK:
			print("Error on request")
			continue
	
		var res = yield(http, "request_completed")
		var result = res[0]
		var code = res[1]
		var headers = res[2]
		var body = res[3]
		
		for i in range(headers.size()):
			var splited_headers = headers[i].split(":")
			
			if splited_headers[0] == "Content-Type":
				var typeFormat = splited_headers[1].trim_prefix(" ")
				
				if typeFormat.to_lower().find("image") > -1:
					var image = Image.new()
					
					match typeFormat.to_lower():
						"image/png":
							image.load_png_from_buffer(body)
						
						"image/webp":
							image.load_webp_from_buffer(body)
						
						"image/jpg", "image/jpeg":
							image.load_jpg_from_buffer(body)
						
						"image/bmp":
							image.load_bmp_from_buffer(body)
					
					item.resource = image
				break
		
		print("Resource loaded @ %s:%s:%s" % [OS.get_datetime().hour, OS.get_datetime().minute, OS.get_datetime().second])
	
	#for xtr in ExternalDB.inThreads:
	#xtr.wait_to_finish()
	#ExternalDB.inThreads.erase(xtr)
	save_db(EXTERNAL_XT_FILENAME)

static func show_wait_popup() -> void:
	pass

static func find_resource(name: String) -> Resource:
	for item in ExternalDB.infos:
		if item.name == name:
			return item.resource
	
	print("Stored %s items but (%s) has not found" % [ExternalDB.infos.size(), name])
	
	return null
