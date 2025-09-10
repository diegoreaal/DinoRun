extends Node

# PRE-CARGA DE ESCENAS DE OBSTÁCULOS
var stump_scene = preload("res://scenes/stump.tscn")  
var rock_scene = preload("res://scenes/rock.tscn")    
var barrel_scene = preload("res://scenes/barrel.tscn")
var bird_scene = preload("res://scenes/bird.tscn")    
var obstacle_types := [stump_scene, rock_scene, barrel_scene] 
var obstacles : Array                                  
var bird_heights := [200, 390]                         

# VARIABLES DEL JUEGO
const DINO_START_POS := Vector2i(150, 485)  
const CAM_START_POS := Vector2i(576, 324)   
var difficulty                               
const MAX_DIFFICULTY : int = 2              
var score : int                             
const SCORE_MODIFIER : int = 10             # Factor para mostrar el puntaje (divide el score real)
var high_score : int                        
var speed : float                           
const START_SPEED : float = 10.0            
const MAX_SPEED : int = 25                  
const SPEED_MODIFIER : int = 5000           
var screen_size : Vector2i                  
var ground_height : int                     
var game_running : bool                     
var last_obs                                
var lives : int
const MAX_LIVES : int = 3

# FUNCIÓN QUE SE EJECUTA AL INICIAR EL JUEGO
func _ready():
	screen_size = get_window().size  
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()  
	$GameOver.get_node("Button").pressed.connect(new_game) 
	new_game() 

# INICIAR NUEVO JUEGO
func new_game():
	# Reinicia variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false  # Despausa el juego
	difficulty = 0
	lives = MAX_LIVES
	update_lives_label()  
	
	# Elimina todos los obstáculos existentes
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	# Restablece posiciones iniciales
	$Dino.position = DINO_START_POS
	$Dino.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	# Muestra mensaje inicial y oculta pantalla de Game Over
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

# CICLO PRINCIPAL DEL JUEGO
func _process(delta):
	if game_running:
		# Aumenta velocidad en base al puntaje
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		
		# Ajusta dificultad según score
		adjust_difficulty()
		
		# Genera nuevos obstáculos
		generate_obs()
		
		# Mueve al dino y la cámara hacia adelante
		$Dino.position.x += speed
		$Camera2D.position.x += speed
		
		# Actualiza el puntaje
		score += speed
		show_score()
		
		# Desplaza el suelo para que parezca infinito
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
		# Elimina obstáculos que ya salieron de la pantalla
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)
	else:
		# Si el juego no está corriendo y el jugador presiona Enter (ui_accept), lo inicia
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

# GENERAR OBSTÁCULOS
func generate_obs():
	# Genera obstáculo si no hay o si el último está lo suficientemente lejos
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1 # Cantidad máxima según dificultad
		for i in range(randi() % max_obs + 1): 
			obs = obs_type.instantiate() 
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			# Calcula posición del obstáculo en X y Y
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
		
		# Con dificultad máxima, chance de generar un pájaro
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				obs = bird_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()] # Altura aleatoria
				add_obs(obs, obs_x, obs_y)

# AGREGAR OBSTÁCULO A LA ESCENA
func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs) # Conecta colisión con Dino
	add_child(obs)
	obstacles.append(obs)

# ELIMINAR OBSTÁCULO
func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)


func hit_obs(body):
	if body.name == "Dino":
		lives -= 1
		update_lives_label()
		if lives <= 0:
			game_over()
		else:
			$Dino.position.y -= 50

# ACTUALIZAR PUNTAJE EN HUD
func show_score():
	$HUD.get_node("ScoreLabel").text = "PUNTUACIÓN: " + str(score / SCORE_MODIFIER)

# CHEQUEAR Y ACTUALIZAR RECORD
func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "MEJOR PUNTUACIÓN: " + str(high_score / SCORE_MODIFIER)

# AJUSTAR DIFICULTAD SEGÚN SCORE
func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

# GAME OVER
func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	$GameOver.show()

func update_lives_label():
	$HUD.get_node("LivesLabel").text = "VIDAS: " + str(lives)
