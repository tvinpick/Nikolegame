class_name InteractionService
extends RefCounted
## Reservations of anchors/slots and of actors (exclusive ownership).
## * reserve_slot(f, anchor, actor) -> slot index or -1
## * release_actor(actor) frees everything the actor holds
## * lock_actor(target, owner) for "pick up pet", joint play, bathing, etc.
## Double-start protection: an actor can hold at most one anchor at a time.

var slots: Dictionary = {}       # "uid:anchor" -> Array of actor ids (index = slot)
var held_by: Dictionary = {}     # actor id -> "uid:anchor"
var actor_locks: Dictionary = {} # actor id -> owner id


static func key(f: Furniture, anchor_name: String) -> String:
	return "%d:%s" % [f.uid, anchor_name]


func capacity(f: Furniture, anchor_name: String) -> int:
	var a := Content.resolve_anchor(f.item_id, anchor_name)
	return int(a.get("slots", 1)) if not a.is_empty() else 0


func free_slots(f: Furniture, anchor_name: String) -> int:
	var k := key(f, anchor_name)
	var used := 0
	for v in slots.get(k, []):
		if v != "":
			used += 1
	return capacity(f, anchor_name) - used


func reserve_slot(f: Furniture, anchor_name: String, actor_id: String) -> int:
	if f == null or anchor_name == "":
		return -1
	var k := key(f, anchor_name)
	if held_by.get(actor_id, "") == k:
		var arr0: Array = slots.get(k, [])
		return arr0.find(actor_id)
	release_actor(actor_id)
	var cap := capacity(f, anchor_name)
	var arr: Array = slots.get(k, [])
	while arr.size() < cap:
		arr.append("")
	for i in cap:
		if arr[i] == "":
			arr[i] = actor_id
			slots[k] = arr
			held_by[actor_id] = k
			Diag.event("reserve", {"key": k, "actor": actor_id, "slot": i})
			return i
	return -1


func release_actor(actor_id: String) -> void:
	var k: String = held_by.get(actor_id, "")
	if k == "":
		return
	var arr: Array = slots.get(k, [])
	for i in arr.size():
		if arr[i] == actor_id:
			arr[i] = ""
	held_by.erase(actor_id)
	Diag.event("release", {"key": k, "actor": actor_id})


func holder_key(actor_id: String) -> String:
	return held_by.get(actor_id, "")


func occupants(f: Furniture) -> Array:
	var out: Array = []
	var prefix := "%d:" % f.uid
	for k in slots.keys():
		if str(k).begins_with(prefix):
			for a in slots[k]:
				if a != "":
					out.append(a)
	return out


## Free all reservations on a furniture (it was moved/stored). Returns actors to interrupt.
func evict(f: Furniture) -> Array:
	var out: Array = []
	var prefix := "%d:" % f.uid
	for k in slots.keys():
		if str(k).begins_with(prefix):
			for a in slots[k]:
				if a != "":
					out.append(a)
					held_by.erase(a)
			slots.erase(k)
	return out


func lock_actor(target: String, owner: String) -> bool:
	var cur: String = actor_locks.get(target, "")
	if cur != "" and cur != owner:
		return false
	actor_locks[target] = owner
	Diag.event("actor_lock", {"target": target, "owner": owner})
	return true


func unlock_actor(target: String, owner: String) -> void:
	if actor_locks.get(target, "") == owner:
		actor_locks.erase(target)
		Diag.event("actor_unlock", {"target": target, "owner": owner})


func locked_by(target: String) -> String:
	return actor_locks.get(target, "")


func snapshot() -> Dictionary:
	return {"slots": slots.duplicate(true), "locks": actor_locks.duplicate()}
