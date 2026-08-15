class_name LoreCatalog
extends RefCounted

const ORDER: Array[StringName] = [&"threadbound", &"blossom", &"trial_power", &"trial_balance", &"trial_essence", &"fragment_power", &"fragment_balance", &"fragment_essence", &"eryndor", &"field_threadling", &"field_tensioner", &"field_loomkin", &"proto_weaver"]

const ENTRIES := {
	&"threadbound": {"title": "What Is a Threadborne?", "category": "FOUNDATIONS", "body": "A Threadborne is a living Thread that slipped from the wound in the world's Weave and was cut free before purpose could close around it. Untuned. Unclaimed. Unbound. It carries no promised fate—only the possibility of becoming."},
	&"blossom": {"title": "Blossoms of Eryndor", "category": "ERYNDOR", "body": "Blossoms are living extensions of Eryndor's desire to remain connected to what moves across her. They remember, restore, and offer the Threadborne somewhere to return. Through them the world may nurture a journey, but it does not direct one. Eryndor cares; she does not orchestrate."},
	&"trial_power": {"title": "Trial of Power", "category": "THE FIRST WEAVE", "body": "Power without resistance is only motion. The red wing asks whether strength can act decisively without mistaking domination for purpose. Break what binds the way—and notice what your victory leaves behind."},
	&"trial_balance": {"title": "Trial of Balance", "category": "THE FIRST WEAVE", "body": "Balance is not stillness. The blue wing asks its bearer to move with intention under pressure, carrying one decision cleanly into the next without mistaking control for harmony."},
	&"trial_essence": {"title": "Trial of Essence", "category": "THE FIRST WEAVE", "body": "Essence lies beneath appearances. The yellow wing asks its bearer to recognize what remains true when paths vanish, forms deceive, and certainty becomes another veil."},
	&"fragment_power": {"title": "Fragment of Power", "category": "LOOSE THREADS", "body": "A loose strand carrying the heat of the primordial Thread of Power. The First Weaver once wove that force alongside Eryndor, where no single hand was meant to hold it. This fragment remains free. The greater Thread does not; it endures within the Monarch."},
	&"fragment_balance": {"title": "Fragment of Balance", "category": "LOOSE THREADS", "body": "A loose strand carrying the faint measure of the primordial Thread of Balance. The First Weaver once wove that force alongside Eryndor, where no single hand was meant to hold it. This fragment remains free. The greater Thread does not; it endures within the Hermit."},
	&"fragment_essence": {"title": "Fragment of Essence", "category": "LOOSE THREADS", "body": "A loose strand carrying the quiet perception of the primordial Thread of Essence. The First Weaver once wove that force alongside Eryndor, where no single hand was meant to hold it. This fragment remains free. The greater Thread does not; it endures within the Sage."},
	&"eryndor": {"title": "Eryndor, the World That Remembers", "category": "ERYNDOR", "body": "Eryndor is not merely a realm, but the consciousness within it—the canvas, witness, and memory of creation. She feels the lives woven through her, yet cannot command their choices without denying what makes them alive. She nurtures. She remembers. She does not rule."},
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
