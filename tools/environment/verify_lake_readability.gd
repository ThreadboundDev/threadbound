extends SceneTree
func _initialize():
 call_deferred('verify')
func verify():
 var water=load('res://Src/Environment/Greybox/greybox_polygon_water.tscn').instantiate()
 water.lake_presentation=true
 water.points=PackedVector2Array([Vector2(-400,-400),Vector2(400,-400),Vector2(400,400),Vector2(-400,400)])
 root.add_child(water)
 var pocket=load('res://Src/Environment/Greybox/greybox_polygon_water.tscn').instantiate()
 pocket.air_pocket=true;pocket.lake_presentation=true
 pocket.points=PackedVector2Array([Vector2(-50,-100),Vector2(50,-100),Vector2(50,100),Vector2(-50,100)])
 root.add_child(pocket)
 var p=load('res://Src/Characters/Player/player.tscn').instantiate();p.set_physics_process(false);root.add_child(p)
 await process_frame
 p.global_position-=p.get_water_sample_position()
 p._prototype_water_surfaces[water]=-400.0
 assert(not p.is_in_prototype_water(),'Pocket overrides overlapping water')
 assert(not water._is_visible_water(Vector2.ZERO),'No wake inside dry pocket')
 assert(pocket._fill.z_index<0 and not pocket._fill.z_as_relative,'Pocket is behind tiles')
 p.global_position.x+=51
 assert(p.is_in_prototype_water(),'Center crossing pocket edge immediately enters water')
 assert(water._is_visible_water(Vector2(51,0)))
 p.velocity=Vector2.ZERO
 p.is_wall_clinging=true
 p.update_animations(1.0)
 assert(p.live_3d_visual._logical_animation==&'Swim_Idle','Blocked swimmer never runs/clings')
 p.global_position.x=410
 assert(not p.is_in_prototype_water(),'Stale collider overlap cannot keep player wet beyond polygon')
 p.global_position.x=200
 p._prototype_water_surfaces.clear()
 assert(p.is_in_prototype_water(),'Geometry classifies water before delayed enter signal')
 var mat=p.live_3d_visual._sword_mesh.get_active_material(0)
 assert(mat.roughness<0.4 and mat.specular_mode==BaseMaterial3D.SPECULAR_SCHLICK_GGX)
 print('PASS: dry-pocket precedence, wet edges, delayed overlap, wall-idle, wake clipping, pocket depth, sword material')
 p.queue_free();water.queue_free();pocket.queue_free();await process_frame;quit()
