extends KinematicBody2D

var velocity = Vector2()
var damage

func _ready():
    set_process(true)
    
func start_at(pos, dir, type, dmg, _lifetime, size, speed):
    $Sprite.animation = type
    position = pos
    rotation = dir
    $Explosion.set_scale(size)
    $Sprite.set_scale(size)
    damage = dmg
    velocity = Vector2(speed, 0).rotated(dir)
    add_to_group("bullets")
    speed = speed

func _physics_process(delta):
    var _collision = move_and_collide(velocity * delta)

func _on_VisibilityNotifier2D_screen_exited():
    queue_free()
    
func hit():
    velocity = Vector2(0, 0)
    $Sprite.hide()
    $Explosion.show()
    $Explosion.play("smoke")
    
func _on_Lifetime_timeout():
    hit()

func _on_Explosion_animation_finished():
    queue_free()

func _on_Area2D_body_entered(body):
    if not body.is_in_group("bullets"):
        hit()
        $Timer.start()
    if body.is_in_group("bullets"):
        velocity = Vector2(0, 0)
        $Sprite.hide()
        $Explosion.show()
        $Explosion.play("smoke")

func _on_Timer_timeout():
    velocity = Vector2(0, 0)
    $Sprite.hide()
    $Explosion.show()
    $Explosion.play("smoke")
