extends Node2D

onready var links = $Links 
var direction := Vector2(0,0)   # The direction in which the chain was shot
var tip := Vector2(0,0)         # The global position the tip should be in
var hit = false                             # We use an extra var for this, because the chain is 
								# connected to the player and thus all .position
								# properties would get messed with when the player
								# moves.

const SPEED = 70   # The speed with which the chain moves

var flying = false	# Whether the chain is moving through the air
var hooked = false	# Whether the chain has connected to a wall

# shoot() shoots the chain in a given direction
sync func shoot():
	$WhipSound.play()
	direction = get_local_mouse_position().normalized() # Normalize the direction and save it
	flying = true # Keep track of our current scan
	tip = self.global_position
	# reset the tip position to the player's position
	# if tip has not hooked after a second release and reset timer

sync func release() -> void:
	flying = false
	hooked = false

# Every graphics frame we update the visuals
func _process(_delta: float) -> void:
	self.visible = flying or hooked	# Only visible if flying or attached to something
	if not self.visible:
		return
		# Not visible -> nothing to draw
	var tip_loc = to_local(tip)
	# Easier to work in local coordinates
	# We rotate the links (= chain) and the tip to fit on the line between self.position (= origin = player.position) and the tip
	links.rotation = self.position.angle_to_point(tip_loc) - deg2rad(90)
	$Tip.rotation = self.position.angle_to_point(tip_loc) - deg2rad(90)
	links.position = tip_loc
	# The links are moved to start at the tip
	links.region_rect.size.y = tip_loc.length() * 1.01
# Every physics frame we update the tip position
func _physics_process(_delta: float) -> void:
	$Tip.global_position = tip
	# The player might have moved and thus updated the position of the tip -> reset it
	if flying:
		# if move_and_collide() always moves, but returns true if we did collide
		if $Tip.move_and_collide(direction * SPEED ,false ,true, false):  
			hooked = true
			flying = false			
	tip = $Tip.global_position
	# set `tip` as starting position for next frame
