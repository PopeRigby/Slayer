extends KinematicBody2D

signal health_changed
signal died

export (PackedScene) var Bullet
export (int) var rot_speed
export (int) var damage
export (int) var start_health
export (float) var bullet_lifetime
# Member variables
# Member variables
const GRAVITY = 1300.0 # pixels/second/second

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 50
const WALK_FORCE = 1600
const WALK_MIN_SPEED = 10
const WALK_MAX_SPEED = 400
const STOP_FORCE = 1500
const JUMP_SPEED = 600
const JUMP_MAX_AIRBORNE_TIME = 0.4
const SLIDE_SPEED = 600
const MAX_SLIDE_TIME = 0.4

var velocity = Vector2()
var rot_dir
var can_shoot = true
var health
var on_air_time = 100
var jumping = false
var sliding = false
var moving_left = false
var moving_right = false

var prev_jump_pressed = false

    
func _ready():
    health = start_health
    emit_signal("health_changed", health)
    
func _input(event):		
    if event.is_action_pressed("tank_fire") and can_shoot:
        can_shoot = false
        #yield($AnimationPlayer, "animation_finished")
        $GunTimer.start()
        var b = Bullet.instance()
        b.start_at($"Turret/Muzzle".global_position, $Turret.global_rotation,
                   'blue', damage, bullet_lifetime)
        $Bullets.add_child(b)
    
        
func _physics_process(delta):
    var mpos = get_global_mouse_position()
    $Turret.global_rotation = mpos.angle_to_point(position)
        # Create forces
    var force = Vector2(0, GRAVITY)
    
    var move_left = Input.is_action_pressed("move_left")
    var move_right = Input.is_action_pressed("move_right")
    var jump = Input.is_action_pressed("jump")
    var slide = Input.is_action_pressed("slide")
    
    var stop = true
    
    if move_left:
        if velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED:
            force.x -= WALK_FORCE
            stop = false
            moving_left = true
    elif move_right:
        if velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED:
            force.x += WALK_FORCE
            stop = false
            moving_right = true
            
    if slide && move_right:
        velocity.x = +SLIDE_SPEED
        sliding = true   
    elif slide && move_left:
        velocity.x = -SLIDE_SPEED
        sliding = true 
    
    if stop:
        var vsign = sign(velocity.x)
        var vlen = abs(velocity.x)
        
        vlen -= STOP_FORCE * delta
        if vlen < 0:
            vlen = 0
        
        velocity.x = vlen * vsign
    
    # Integrate forces to velocity
    velocity += force * delta    
    # Integrate velocity into motion and move
    velocity = move_and_slide(velocity, Vector2(0, -1))
    
    if is_on_floor():
        on_air_time = 0
        
    if jumping and velocity.y > 0:
        # If falling, no longer jumping
        jumping = false
        
        

    
    if on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping:
        # Jump must also be allowed to happen if the character left the floor a little bit ago.
        # Makes controls more snappy.
        velocity.y = -JUMP_SPEED
        jumping = true
    
    on_air_time += delta
    prev_jump_pressed = jump


func _on_GunTimer_timeout():
    can_shoot = true
    
func take_damage(amount):
    health -= amount
    emit_signal("health_changed", (health * 100 / start_health))
    if health <= 0:
        emit_signal("died")
        print("Dead!")
