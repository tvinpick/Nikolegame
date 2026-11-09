class_name NavGrid
extends RefCounted
## Floor navigation on a grid (AStarGrid2D). Furniture footprints become solid
## cells; the grid is rebuilt whenever furniture is placed, moved or stored.
## Characters ask for paths; if a target is blocked they get the nearest free
## cell (recovery), so nobody gets stuck inside a moved sofa.

var astar := AStarGrid2D.new()
var cell := RoomGeo.CELL
var origin := Vector2(RoomGeo.WALK_LEFT, RoomGeo.WALK_TOP)
var size := Vector2i.ZERO
var version := 0
var blockers: Array = []   # Array of Rect2 (inflated footprints)


func _init() -> void:
	size = Vector2i(int(ceil((RoomGeo.WALK_RIGHT - RoomGeo.WALK_LEFT) / cell)) + 1, int(ceil((RoomGeo.WALK_BOTTOM - RoomGeo.WALK_TOP) / cell)) + 1)
	astar.region = Rect2i(Vector2i.ZERO, size)
	astar.cell_size = Vector2(cell, cell)
	astar.offset = origin
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()


## rects: footprints in world floor coordinates. pad: clearance for bodies.
func rebuild(rects: Array, pad := 14.0) -> void:
	astar.fill_solid_region(astar.region, false)
	blockers.clear()
	for r in rects:
		var rr: Rect2 = (r as Rect2).grow(pad)
		blockers.append(rr)
		var a := to_cell(rr.position)
		var b := to_cell(rr.end)
		for x in range(max(0, a.x), min(size.x, b.x + 1)):
			for y in range(max(0, a.y), min(size.y, b.y + 1)):
				astar.set_point_solid(Vector2i(x, y), true)
	version += 1


func to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(round((p.x - origin.x) / cell)), int(round((p.y - origin.y) / cell)))


func to_world(c: Vector2i) -> Vector2:
	return origin + Vector2(c) * cell


func in_bounds(c: Vector2i) -> bool:
	return astar.is_in_boundsv(c)


func is_free(p: Vector2) -> bool:
	var c := to_cell(p)
	return in_bounds(c) and not astar.is_point_solid(c)


func nearest_free(p: Vector2, max_radius := 30) -> Vector2:
	var c := to_cell(RoomGeo.clamp_walk(p))
	if in_bounds(c) and not astar.is_point_solid(c):
		return to_world(c)
	for r in range(1, max_radius):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				var cc := c + Vector2i(dx, dy)
				if in_bounds(cc) and not astar.is_point_solid(cc):
					var d := Vector2(dx, dy).length()
					if d < best_d:
						best_d = d
						best = cc
		if best.x >= 0:
			return to_world(best)
	return p


## Returns world-space path (first point = start cell). Empty if unreachable.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := to_cell(nearest_free(from))
	var b := to_cell(nearest_free(to))
	if not in_bounds(a) or not in_bounds(b):
		return PackedVector2Array()
	var path := astar.get_point_path(a, b)
	return smooth(path)


func reachable(from: Vector2, to: Vector2) -> bool:
	if not is_free(to):
		return false
	var a := to_cell(nearest_free(from))
	var b := to_cell(to)
	return astar.get_id_path(a, b).size() > 0


## Remove redundant grid points by line-of-sight checks (fewer zigzags).
func smooth(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path
	var out := PackedVector2Array([path[0]])
	var i := 0
	while i < path.size() - 1:
		var j := path.size() - 1
		while j > i + 1 and not line_free(path[i], path[j]):
			j -= 1
		out.append(path[j])
		i = j
	return out


func line_free(a: Vector2, b: Vector2) -> bool:
	var steps := int(a.distance_to(b) / (cell * 0.5)) + 1
	for s in steps + 1:
		var p := a.lerp(b, float(s) / steps)
		if not is_free(p):
			return false
	return true
