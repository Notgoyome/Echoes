extends CharacterBody2D

class_name Player

# movement
@export var acceleration = 800
@export var friction = 10
@export var air_friction = 10
@export var ground_friction = 500
@export var max_speed = 100
var actual_max_speed = 0

var can_move = true
var has_acceleration = true
var has_friction = true
var is_moving = false

var input_vector = Vector2.ZERO
var last_input_vector = Vector2(1, 0)

# gravity
var air_trigger = false

# jump
var jump_height: float = 32
@export var jump_time: float = 0.3
@export var fall_time: float = 0.4
var jump_velocity: float = (2 * jump_height) / jump_time * -1
var peak_velocity: float = (2 * jump_height) / (jump_time * jump_time)
var fall_velocity: float = (2 * jump_height) / (fall_time * fall_time)
var can_jump = true
var has_gravity = true
var is_falling = false
var is_coyote = false

# CLIMB
var can_climb = false
var request_climb = false
var hold : Hold = null
@export var max_climb_stamina = 100.0
var climb_stamina = 100.0

# keep_velocity
var platform_velocity = Vector2.ZERO

# animation
@onready var animated_sprite: AnimatedSprite2D = $Animation

#jump buffer
@onready var jump_buffer : JumpBufferComponent = $JumpBufferComponent

func _ready() -> void:
	Engine.time_scale = 1

	#platform_on_leave = PLATFORM_ON_LEAVE_ADD_VELOCITY
	
	#platform_on_leave = PLATFORM_ON_LEAVE_DO_NOTHING
	# platform_on_leave = PLATFORM_ON_LEAVE_ADD_VELOCITY
	actual_max_speed = max_speed
	pass

# Main physics process
func _physics_process(delta: float) -> void: ### SKOTCH !!! SEPARER LES FONCTIONS EN COMPONENTS
	input_vector = get_input_vector()
	update_sprite_direction(input_vector)
	apply_movement(delta, input_vector)
	apply_gravity(delta)
	handle_jump()
	var res = move_and_slide()

	#permet d'éviter le double velocity bug, le bloc donne la vélocité puis push le joueur, donc 2x velocity
	#SKOTCH SCOTCH, le probleme étant, que si on est sur une platforme plus rapide que soit ,
	# et que l'on tombe de la platforme,la platforme nous donne sa vélocitié, 
	# mais si elle parvient a nous rattraper elle nous donne encore sa vélocité
	if get_platform_velocity() != Vector2.ZERO:
		platform_velocity = get_platform_velocity()
	
	elif platform_velocity != Vector2.ZERO and get_platform_velocity() == Vector2.ZERO:
		if max_speed + abs(platform_velocity.x) < abs(velocity.x): # limit to player speed and platform speed
			velocity.x = max_speed * input_vector.x + platform_velocity.x
			platform_velocity = Vector2.ZERO




	for i in range(get_slide_collision_count()):
		var node = get_slide_collision(i).get_collider()
		if node.has_method("trigger_fall"):
			if air_trigger:
				node.trigger_fall()
		elif node.has_method("trigger"):
			node.trigger()
	if is_on_floor() and air_trigger: #scotch risky, opter pour le state?
		air_trigger = false
		pass
		


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("climb"):
		request_climb = true
	if Input.is_action_just_released("climb"):
		request_climb = false




# Handle input direction
func get_input_vector() -> Vector2:
	var new_input_vector = input_vector
	new_input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	#new_input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	if new_input_vector != Vector2.ZERO:
		last_input_vector = new_input_vector
	return new_input_vector

# Update the sprite direction based on movement
func update_sprite_direction(input_vector: Vector2) -> void:
	if input_vector.x < 0:
		animated_sprite.flip_h = true
	elif input_vector.x > 0:
		animated_sprite.flip_h = false

# Apply movement acceleration or friction
func apply_movement(delta: float, input_vector: Vector2) -> void:
	if can_move and input_vector != Vector2.ZERO:
		if has_acceleration:
			var new_x = velocity.move_toward(input_vector * actual_max_speed, acceleration * delta).x

			if sign(input_vector.x) != sign(velocity.x): # ssi le joueur se retourne
				velocity.x = new_x
			if abs(new_x) > abs(velocity.x): # evite que le joueur se ralentisse lui meme en avançant dans la meme direction
				velocity.x = new_x
			else:
				velocity.x = velocity.move_toward(Vector2.ZERO, friction/5 * delta).x
				
			if is_on_floor():
				velocity.x = new_x

		# else:
		# 	velocity.x = input_vector.x * actual_max_speed
		is_moving = true
	if input_vector == Vector2.ZERO:
		if has_friction and jump_buffer.jump_requested == false:
			velocity.x = velocity.move_toward(Vector2.ZERO, friction * delta).x

		is_moving = false

# Handle jumping logic
func handle_jump() -> void:
	if can_jump and jump_buffer.jump_requested:
		velocity.y = jump_velocity
		jump_buffer.jump_requested = false
		#ONLY IF PLAYER DIDN4T LEAVE THE PLATFORM be careful of coyote timer
		if is_coyote:
			velocity.x -= get_platform_velocity().x * 1
		velocity.y -= get_platform_velocity().y
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

# Apply gravity
func apply_gravity(delta: float) -> void:
	if has_gravity:
		velocity.y += get_self_gravity() * delta

# Get the current gravity based on the vertical velocity
func get_self_gravity() -> float:
	if velocity.y < 0:
		is_falling = false
		return peak_velocity
	else:
		is_falling = true
		return fall_velocity


func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


#CLIMB SYSTEM

signal on_exit_climb
signal on_enter_climb

func set_climb_state(state: bool) -> void:
	can_climb = state
	if state:
		emit_signal("on_enter_climb")
	else:
		emit_signal("on_exit_climb")
	pass # Replace with function body.
