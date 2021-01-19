extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
enum FACES {
	RIGHT,
	FORWARD,
	LEFT,
	BACK,
	UP,	
	DOWN
}
const FACE_POSITION = [
	Vector2(0,0),
	Vector2(1,0),
	Vector2(2,0),
	Vector2(0,1),
	Vector2(1,1),
	Vector2(2,1)
]
const FACE_SIZE = 1024

const MOUSE_SENSITIVITY = .005

export(Texture) var OBJECTS_TEXTURE

onready var camera = $StaticBody/MeshInstance/Camera
var last_click_position
var last_position
 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(event):
	if event is InputEventMouseMotion:
		camera.rotation += Vector3(0,event.relative.x * MOUSE_SENSITIVITY,0)
		camera.rotation += Vector3(-event.relative.y * MOUSE_SENSITIVITY, 0, 0)
		
	if event is InputEventMouseButton:
		last_click_position = event.position
		
func _physics_process(delta):
	if last_position != last_click_position:
		var color = get_clicked_object(last_click_position)		
		print("R:%d G:%d B:%d" % [int(color.r * 256), int(color.g * 256), int(color.b * 256)])
		last_position = last_click_position
	
func get_cube_position_data_at(position):
	var from = camera.project_ray_origin(position)
	var to = from + camera.project_ray_normal(position) * 1000
	
	var space_state = get_world().direct_space_state
	return space_state.intersect_ray(to, from)
		
func position_at_cube_to_texture_coords(position):
	return get_coords_in_texture(get_cube_position_data_at(position))
	
func get_pixel_from_objects_texture(pixel: Vector2):
	var texture_data = OBJECTS_TEXTURE.get_data()
	var color
	
	texture_data.lock()
	color = texture_data.get_pixelv(pixel)
	texture_data.unlock()
	
	return color
	
func get_clicked_object(position):
	var coords = position_at_cube_to_texture_coords(position)
	
	return get_pixel_from_objects_texture(coords)
			
func is_facing(normal, direction):
	return abs(normal.dot(direction) - 1) < 0.01
	
func get_coords_in_texture(hit_metadata):
	var plane_coords_parts = get_face_and_coords(hit_metadata.normal, hit_metadata.position)
	return FACE_POSITION[plane_coords_parts.face] * FACE_SIZE + plane_coords_parts.coords * FACE_SIZE	
	
func get_face_and_coords(normal, position):
	var coords: Vector2
	var face
	if is_facing(normal, Vector3.UP):
		face = FACES.UP
		coords = Vector2(position.x, position.z).rotated(PI/2)
	if is_facing(normal, Vector3.DOWN):
		face = FACES.DOWN
		coords = Vector2(-position.x, -position.z).rotated(PI/2)
	if is_facing(normal, Vector3.LEFT): 
		face = FACES.LEFT
		coords = Vector2(-position.z, position.y)
	if is_facing(normal, Vector3.RIGHT):
		face = FACES.RIGHT
		coords = Vector2(position.z, position.y)
	if is_facing(normal, Vector3.FORWARD): 
		face = FACES.FORWARD
		coords = Vector2(position.x, position.y)
	if is_facing(normal, Vector3.BACK):
		face = FACES.BACK
		coords = Vector2(-position.x, position.y)
		
		
	coords /= Vector2(-5, -5)
	coords += Vector2(0.5, 0.5)
	
	return({"face": face, "coords": coords})
	
