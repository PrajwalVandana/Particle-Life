extends Node2D


const SimulationParticle = preload("res://SimulationParticle.gd")
const Set = preload("res://Set.gd")

@export var NUM_PARTICLES: int = 1000
@export var NUM_COLORS: int = 6
@export var ATTRACTION_FACTOR: Array[Array] = [  # [on][by]
	[1, -0.4, -0.8],
	[-0.37, 0.5, -0.9],
	[0.3, 0.8, -0.8]
]
@export var TYPE_COLORS: Array[Color] = [
	Color(255, 0, 0),
	Color(0, 255, 0),
	Color(0, 0, 255),
	Color(255, 255, 0),
	Color(0, 255, 255),
	Color(255, 0, 255)
]
@export_range(0, 1) var THRESHOLD_DIST: float = 0.3
@export var FRICTIONAL_HALF_LIFE: float = 0.04
@export var MAX_INTERACTION_DIST: float = 40
@export var FORCE_SCALE: float = 800
@export var PARTICLE_SIZE: int = 2
@export var TIME_SCALE: float = 0.1
@export var NUM_CHUNK_LAYERS: int = 1
@export var COLLISION_DAMPING_FACTOR: float = 0.5
# @export var BOUNDARY_REPULSION_FACTOR: float = 1

var CHUNK_SIZE: int = ceil(MAX_INTERACTION_DIST/(NUM_CHUNK_LAYERS+0.5))

var particles: Array[SimulationParticle]
var chunks: Dictionary


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var screen_rect = get_viewport_rect()
	var screen_size = screen_rect.size
	for i in range(NUM_PARTICLES):
		var p = SimulationParticle.new()
		p.position = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
		p.velocity = Vector2(0, 0)
		p.type = randi() % NUM_COLORS
		particles.append(p)

		var id = chunk_id(p.position)
		if not chunks.has(id):
			chunks[id] = Set.new()
		chunks[id].add(i)

	# randomize attraction matrix
	ATTRACTION_FACTOR = []
	for i in range(NUM_COLORS):
		ATTRACTION_FACTOR.append([])
		for j in range(NUM_COLORS):
			ATTRACTION_FACTOR[i].append(0)

	for i in range(NUM_COLORS):
		for j in range(NUM_COLORS):
			ATTRACTION_FACTOR[i][j] = randf_range(-1, 1)

	print(ATTRACTION_FACTOR)


func _process(delta: float) -> void:
	var screen_rect = get_viewport_rect()
	var screen_size = screen_rect.size
	delta *= TIME_SCALE
	for i in range(particles.size()):
		var p = particles[i]
		var f = Vector2(0, 0)

		for id in neighbors(chunk_id(p.position)):
			if not chunks.has(id): continue
			for j in chunks[id]:
				var q = particles[j]
				if p == q:
					continue
				f += force(p, q)

		p.velocity *= friction(delta)
		p.velocity += f * delta

	for i in range(particles.size()):
		var p = particles[i]
		var old_id = chunk_id(p.position)

		p.position += p.velocity * delta
		if not screen_rect.has_point(p.position):
			# wrap around
			# p.position.x -= screen_size.x * floor(p.position.x/screen_size.x)
			# p.position.y -= screen_size.y * floor(p.position.y/screen_size.y)

			# bounce off wall
			if p.position.x > screen_size.x:
				p.position.x = screen_size.x - (p.position.x - screen_size.x)
				p.velocity.x *= -(1-COLLISION_DAMPING_FACTOR)
			elif p.position.x < 0:
				p.position.x = -p.position.x
				p.velocity.x *= -(1-COLLISION_DAMPING_FACTOR)

			if p.position.y > screen_size.y:
				p.position.y = screen_size.y - (p.position.y - screen_size.y)
				p.velocity.y *= -(1-COLLISION_DAMPING_FACTOR)
			elif p.position.y < 0:
				p.position.y = -p.position.y
				p.velocity.y *= -(1-COLLISION_DAMPING_FACTOR)

		var new_id = chunk_id(p.position)
		if old_id != new_id:
			chunks[old_id].erase(i)
			if not chunks.has(new_id):
				chunks[new_id] = Set.new()
			chunks[new_id].add(i)

	for id in chunks.keys():
		if chunks[id].is_empty():
			chunks.erase(id)

	queue_redraw()
	print(Engine.get_frames_per_second())


func _draw():
	for p in particles:
		draw_circle(p.position, PARTICLE_SIZE, TYPE_COLORS[p.type])

func force(on: SimulationParticle, by: SimulationParticle) -> Vector2:
	return MAX_INTERACTION_DIST * FORCE_SCALE * _force(
		on.dist_to(by)/MAX_INTERACTION_DIST,
		ATTRACTION_FACTOR[on.type][by.type]
	) * on.dir_to(by)


func _force(dist: float, attraction: float) -> float:  # TODO: implement properly
	if dist < THRESHOLD_DIST:
		return dist/THRESHOLD_DIST - 1;
	elif dist < 1:
		# return attraction * (1 - abs(2*dist - THRESHOLD_DIST - 1)/(1 - THRESHOLD_DIST))
		return attraction - attraction/((1-THRESHOLD_DIST)/2)**2*(dist-(1+THRESHOLD_DIST)/2)**2
	else:
		return 0


func friction(dt: float) -> float:
	return (0.5)**(dt/FRICTIONAL_HALF_LIFE)


func chunk_id(pos: Vector2) -> Vector2:
	return Vector2(
		floor(pos.x/CHUNK_SIZE),
		floor(pos.y/CHUNK_SIZE)
	)


func neighbors(id: Vector2, include_self: bool = true) -> Array:
	var result = []
	for x in range(-NUM_CHUNK_LAYERS, NUM_CHUNK_LAYERS+1):
		for y in range(-NUM_CHUNK_LAYERS, NUM_CHUNK_LAYERS+1):
			if x == 0 and y == 0 and not include_self: continue
			result.append(id + Vector2(x, y))

	return result


# func boundary_force(p: SimulationParticle, id: Vector2) -> Vector2:
# 	var dir = Vector2(0, 0)
# 	var dist = 0
# 	if id.x == 0:
# 		dist = p.position.x
# 		dir = Vector2(1, 0)
# 	elif id.y == 0:
# 		dist = p.position.y
# 		dir = Vector2(0, 1)
# 	elif id.x == floor(get_viewport_rect().size.x/CHUNK_SIZE):
# 		dist = get_viewport_rect().size.x - p.position.x
# 		dir = Vector2(-1, 0)
# 	elif id.y == floor(get_viewport_rect().size.y/CHUNK_SIZE):
# 		dist = get_viewport_rect().size.y - p.position.y
# 		dir = Vector2(0, -1)
# 	else:
# 		return dir

# 	return dir * BOUNDARY_REPULSION_FACTOR * FORCE_SCALE * 1/dist**2
