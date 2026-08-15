class_name LoreCatalog
extends RefCounted

const ORDER: Array[StringName] = [&"threadbound", &"blossom", &"trial_power", &"trial_balance", &"trial_essence", &"eryndor", &"field_threadling", &"field_tensioner", &"field_loomkin", &"proto_weaver"]

const ENTRIES := {
	&"threadbound": {"title": "What Is a Threadbound?", "category": "FOUNDATIONS", "body": "A Threadbound is not born to a single shape. They draw loose Threads into themselves, learning new ways to move, fight, and answer the world. No Thread chooses for its bearer. It only makes another choice possible."},
	&"blossom": {"title": "Blossoms of Eryndor", "category": "ERYNDOR", "body": "These pale flowers gather memories shed by the living. A traveler who rests beneath their petals may mend body and spirit—and leave a small impression behind, so the Blossom might remember where their journey should resume."},
	&"trial_power": {"title": "Trial of Power", "category": "THE FIRST WEAVE", "body": "Power is not merely force. It is the will to act while resistance still has a voice. The red wing binds its lesson in opposition: break what holds the way, but learn what your strength disturbs."},
	&"trial_balance": {"title": "Trial of Balance", "category": "THE FIRST WEAVE", "body": "Balance is motion given intention. The blue wing asks its bearer to control momentum under pressure, carrying one decision cleanly into the next before the Weave falls out of measure."},
	&"trial_essence": {"title": "Trial of Essence", "category": "THE FIRST WEAVE", "body": "Essence hides beneath appearances. The yellow wing rewards the mind that watches what vanishes, what returns, and what remains true when the path refuses to stay still."},
	&"eryndor": {"title": "Eryndor, the Unfinished Realm", "category": "ERYNDOR", "body": "Eryndor was woven to endure, not to remain unchanged. Roads remember old travelers, ruins keep arguments their builders forgot, and every living Thread tugs faintly upon the whole. The realm is unfinished because its people are."},
	&"field_threadling": {"title": "Follower's Field Note: Threadling", "category": "FIELD NOTES", "body": "A small knot of instinct wrapped around a sharper one. Threadlings rush whatever disturbs their territory. Their courage is admirable from a distance and inconvenient from anywhere else."},
	&"field_tensioner": {"title": "Follower's Field Note: Tensioner", "category": "FIELD NOTES", "body": "Tensioners draw the surrounding Weave taut before striking. Watch the body, not the weapon: its posture announces the attack before the point begins to move."},
	&"field_loomkin": {"title": "Follower's Field Note: Loomkin", "category": "FIELD NOTES", "body": "Loomkin are stubborn tangles given weight and appetite. Their broad forms conceal surprising reach. A needle may find purchase easily, but being close to one is rarely the same as being safe."},
	&"proto_weaver": {"title": "The Proto-Weaver", "category": "THE THREE BEARERS", "body": "We made it to hold three answers without choosing among them. Power gave it purpose. Balance gave it order. Essence gave it understanding. None of us thought to give it mercy. If it still guards the First Weave, then our lesson remains unfinished. —The Three Bearers"},
}

static func get_entry(lore_id: StringName) -> Dictionary:
	return ENTRIES.get(lore_id, {}) as Dictionary

static func get_title(lore_id: StringName) -> String:
	return String(get_entry(lore_id).get("title", String(lore_id).capitalize()))

static func get_unlocked_entries() -> Array[StringName]:
	var entries: Array[StringName] = []
	for lore_id in ORDER:
		if DemoProgress.has_lore(lore_id):
			entries.append(lore_id)
	return entries
