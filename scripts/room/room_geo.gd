class_name RoomGeo
extends RefCounted
## Room dimensions (world units). One base screen = 1920 x 1080; the room is
## three screens wide and one seamless space.

const SCREEN_W := 1920.0
const WIDTH := SCREEN_W * 3.0
const HEIGHT := 1080.0
const WALL_BOTTOM := 620.0      # baseboard line / back edge of the floor
const WALK_TOP := 650.0         # characters may walk from here...
const WALK_BOTTOM := 1062.0     # ...to here (limited depth)
const WALK_LEFT := 40.0
const WALK_RIGHT := WIDTH - 40.0
const WINDOW_RECT := Rect2(2420, 86, 920, 452)
const WALL_ITEM_TOP := 60.0
const WALL_ITEM_BOTTOM := 570.0
const CELL := 20.0


static func walk_rect() -> Rect2:
	return Rect2(WALK_LEFT, WALK_TOP, WALK_RIGHT - WALK_LEFT, WALK_BOTTOM - WALK_TOP)


static func clamp_walk(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, WALK_LEFT, WALK_RIGHT), clampf(p.y, WALK_TOP, WALK_BOTTOM))


static func is_floor_point(p: Vector2) -> bool:
	return p.y >= WALL_BOTTOM and p.y <= HEIGHT and p.x >= 0 and p.x <= WIDTH


static func is_wall_point(p: Vector2) -> bool:
	return p.y >= 0 and p.y < WALL_BOTTOM and p.x >= 0 and p.x <= WIDTH


## Gentle depth scale for characters (further back = slightly smaller).
static func depth_scale(y: float) -> float:
	return lerpf(0.9, 1.0, clampf((y - WALK_TOP) / (WALK_BOTTOM - WALK_TOP), 0.0, 1.0))
