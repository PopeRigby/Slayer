extends KinematicBody2D

var velocity = Vector2()
export (int) var speed
export (int, 0, 200) var push = 100
var damage
var hit_pos
var weapon_type
var player
var area_effect


func _ready():
	set_process(true)
	player = get_parent().get_parent().get_parent().get_parent()
# warning-ignore:shadowed_variable
func start_at(pos, dir, type, dmg, _lifetime, size, speed, area_dmg):
	$Sprite.animation = type
	position = pos
	rotation = dir
	$Explosion.set_scale(Vector2(0.1,0.1))
	$Sprite.set_scale(size)
	damage = dmg
	velocity = Vector2(speed, 0).rotated(dir)
	add_to_group("bullets")
	speed = speed
	area_effect = area_dmg

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta, false)
	if collision:
		hit()  
		
		if collision.collider.is_in_group("tiles"):
			hit_pos = get_position()
			collision.collider.get_parent().hit(hit_pos, damage, area_effect)
			collision.collider.hit(hit_pos, player.get_node("Weapon").global_rotation)
		if collision.collider.is_in_group("bodies"):
			collision.collider.apply_central_impulse(-collision.normal * push)
			if collision.collider.is_in_group("destruct"):
				collision.collider.get_parent().subdivide(self , collision.collider)
		elif collision.collider.is_in_group("bullets"):
			velocity = Vector2(0, 0)
			$Sprite.hide()
			$Explosion.show()
			$Explosion.play("smoke")
			$Tracer.hide()
		if collision.collider.is_in_group("Players"):
			collision.collider.take_damage(damage, player.get_node("Weapon/Weapon_Sprite").texture.resource_path, player.username, global_position, player.get_node("Weapon").global_rotation)
#			if collision.collider.health == 0:
#			else:

			
		$Timer.start()   

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
	
func hit():
	velocity = Vector2(0,0)
	$CollisionShape2D.disabled = true
	$Sprite.hide()
#	$Explosion.show()
#	$Explosion.play("smoke")
	$Tracer.hide()

func _on_Lifetime_timeout():
	hit()

#func _on_Explosion_animation_finished():
#	queue_free()

func _on_Timer_timeout():
	velocity = Vector2(0, 0)
	$Sprite.hide()
#	$Explosion.show()
#	$Explosion.play("smoke")
	$Tracer.hide()
