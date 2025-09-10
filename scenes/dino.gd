extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1200      
const EXTRA_JUMP_FORCE : int = -2000 
const MAX_JUMP_TIME : float = 1  

var jump_time : float = 0.0
var is_jumping : bool = false

func _physics_process(delta):
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		is_jumping = false
		jump_time = 0.0
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false
			
			if Input.is_action_just_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				is_jumping = true
			elif Input.is_action_pressed("ui_down"):
				$AnimatedSprite2D.play("duck")
				$RunCol.disabled = true
			else:
				$AnimatedSprite2D.play("run")
	else:
		$AnimatedSprite2D.play("jump")
		
		if is_jumping and Input.is_action_pressed("ui_accept") and jump_time < MAX_JUMP_TIME:
			velocity.y += EXTRA_JUMP_FORCE * delta
			jump_time += delta
	
	move_and_slide()
