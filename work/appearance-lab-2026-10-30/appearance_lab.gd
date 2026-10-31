extends Node2D
## Isolated visual lab. No equipment resources, bonuses, saves or lore changes.
const SHADER := preload("res://work/appearance-lab-2026-10-30/appearance_material.gdshader")
const PRESETS := [Vector3.ZERO,Vector3(1,0,0),Vector3(0,1,0),Vector3(0,0,1),Vector3(1,1,0),Vector3(0,1,1),Vector3(1,0,1),Vector3.ONE,Vector3.ZERO]
const COLORS := [Color("f0332b"),Color("408fff"),Color("ffca33")]
var player
var visual
var fabric: ShaderMaterial
var controls: CanvasLayer
var mode := 0
var identity := 0
var math_mode := 1
var mask_style := 0
var motif := 0
var softer_porcelain := false
var armor := false
var weapon := false
var armor_proxies: Array[Node3D] = []
var weapon_proxy: Node3D
var camera: Camera2D
func _ready() -> void:
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2(-20000,-10000),Vector2(20000,-10000),Vector2(20000,10000),Vector2(-20000,10000)])
	background.color = Color("315966")
	background.z_index = -100
	add_child(background)
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30000,100)
	collision.shape = shape
	floor_body.position.y = 200
	floor_body.add_child(collision)
	add_child(floor_body)
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(-15000,150),Vector2(15000,150),Vector2(15000,250),Vector2(-15000,250)])
	ground.color = Color("253f42")
	add_child(ground)
	player = load("res://Src/Characters/Player/player.tscn").instantiate()
	add_child(player)
	visual = player.live_3d_visual
	var mesh: MeshInstance3D = visual._model_root.find_child("Threadborne_Character",true,false)
	var original: StandardMaterial3D = mesh.get_active_material(0)
	# Store authored rest height/depth in UV2. VERTEX in a skinned shader may
	# already include the posed skeleton; motifs must not move across the cloth.
	var study_mesh := ArrayMesh.new()
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var coordinates := PackedVector2Array()
		for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]: coordinates.append(Vector2(vertex.z,vertex.y))
		arrays[Mesh.ARRAY_TEX_UV2] = coordinates
		study_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.mesh = study_mesh
	fabric = ShaderMaterial.new()
	fabric.shader = SHADER
	fabric.set_shader_parameter("base_texture",original.albedo_texture)
	fabric.set_shader_parameter("use_normal",original.normal_enabled and original.normal_texture != null)
	if original.normal_texture: fabric.set_shader_parameter("normal_texture",original.normal_texture)
	mesh.set_surface_override_material(0,fabric)
	_build_proxies()
	camera = Camera2D.new()
	camera.position = Vector2(0,-240)
	camera.zoom = Vector2(0.83,0.83)
	player.add_child(camera)
	camera.make_current()
	_build_controls()
	apply()
func _build_proxies() -> void:
	for bone: String in ["upper_arm.L","upper_arm.R"]:
		var mount := BoneAttachment3D.new()
		mount.bone_name = bone
		visual._skeleton.add_child(mount)
		var plate := MeshInstance3D.new()
		var form := SphereMesh.new()
		form.radius = .14
		form.height = .22
		form.radial_segments = 12
		form.rings = 6
		plate.mesh = form
		var metal := StandardMaterial3D.new()
		metal.albedo_color = Color("777969")
		metal.metallic = .35
		metal.roughness = .65
		plate.material_override = metal
		mount.add_child(plate)
		armor_proxies.append(mount)
	weapon_proxy = Node3D.new()
	visual._sword_mesh.get_parent().add_child(weapon_proxy)
	var staff := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = .025
	shaft.bottom_radius = .025
	shaft.height = 1.25
	staff.mesh = shaft
	staff.position = Vector3(0,-.14,.3145)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("977443")
	wood.roughness = .75
	staff.material_override = wood
	weapon_proxy.add_child(staff)
func identity_color(weights: Vector3, artist := true) -> Color:
	var sum := weights.x+weights.y+weights.z
	if sum < .001: return Color("e8e3d0")
	var rgb := (Vector3(COLORS[0].r,COLORS[0].g,COLORS[0].b)*weights.x+Vector3(COLORS[1].r,COLORS[1].g,COLORS[1].b)*weights.y+Vector3(COLORS[2].r,COLORS[2].g,COLORS[2].b)*weights.z)/sum
	var result := Color(rgb.x,rgb.y,rgb.z)
	if artist:
		# Explicit R/Y/B pair hues, then the documented all-absorbed dark extreme.
		var pairs := Vector3(weights.x*weights.y,weights.y*weights.z,weights.x*weights.z)
		var total := pairs.x+pairs.y+pairs.z
		if total > .001:
			var hues := [Color("986db6"),Color("53a778"),Color("df7740")]
			var mixed := (Vector3(hues[0].r,hues[0].g,hues[0].b)*pairs.x+Vector3(hues[1].r,hues[1].g,hues[1].b)*pairs.y+Vector3(hues[2].r,hues[2].g,hues[2].b)*pairs.z)/total
			result = result.lerp(Color(mixed.x,mixed.y,mixed.z),.8)
		result = result.lerp(Color("171d24"),pow(minf(weights.x,minf(weights.y,weights.z)),2.0))
	return result
func apply() -> void:
	if not fabric: return
	fabric.set_shader_parameter("mode",mode)
	fabric.set_shader_parameter("motif",motif)
	fabric.set_shader_parameter("mask_style",mask_style)
	fabric.set_shader_parameter("softer_porcelain",softer_porcelain)
	fabric.set_shader_parameter("identity_color",identity_color(PRESETS[identity],math_mode==1))
	fabric.set_shader_parameter("identity_strength",0.0 if identity==0 else .75)
	for proxy in armor_proxies: proxy.visible = armor
	weapon_proxy.visible = weapon
	visual._sword_mesh.visible = not weapon
func _choice(row: HBoxContainer, title: String, choices: Array, selected: int, changed: Callable) -> void:
	var label := Label.new()
	label.text = title
	row.add_child(label)
	var option := OptionButton.new()
	for choice in choices: option.add_item(choice)
	option.select(selected)
	option.item_selected.connect(changed)
	row.add_child(option)
func _build_controls() -> void:
	controls = CanvasLayer.new()
	controls.layer = 20
	add_child(controls)
	var panel := PanelContainer.new()
	panel.position = Vector2(16,45)
	controls.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var note := Label.new()
	note.text = "APPEARANCE STUDY — normal movement / jump / attack controls; camera 0.83\nTemporary surface motifs and gear proxies; production equipment is unchanged."
	box.add_child(note)
	var row := HBoxContainer.new()
	box.add_child(row)
	_choice(row,"Look",["Plain","Pattern","Mask","Both"],mode,func(i): mode=i; apply())
	_choice(row,"Identity",["Current neutral","Red","Blue","Yellow","Red + Blue","Blue + Yellow","Red + Yellow","All three","Spared / pale"],identity,func(i): identity=i; apply())
	_choice(row,"Mix",["Weighted RGB","Authored RYB / dark full absorption"],math_mode,func(i): math_mode=i; apply())
	var row2 := HBoxContainer.new()
	box.add_child(row2)
	_choice(row2,"Embroidery",["Diamonds","Chevron","Cross stitch"],motif,func(i): motif=i; apply())
	_choice(row2,"Mask",["Double seam","Split porcelain","Diagonal mark"],mask_style,func(i): mask_style=i; apply())
	for item in [["Softer porcelain",func(on): softer_porcelain=on; apply()], ["Shoulder proxy",func(on): armor=on; apply()], ["Long weapon proxy",func(on): weapon=on; apply()]]:
		var check := CheckButton.new()
		check.text = item[0]
		check.toggled.connect(item[1])
		row2.add_child(check)
