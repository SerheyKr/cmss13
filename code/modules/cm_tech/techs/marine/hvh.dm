
/datum/tech/repeatable/cryomarine_hvh
	name = "Wake Up Additional Troops"
	desc = "Wakes up additional troops to fight against any threats."
	icon_state = "cryotroops"

	announce_message = "Additional troops are being taken out of cryo."

	required_points = 5
	increase_per_purchase = 0

	flags = TREE_FLAG_MARINE_HVH
	tier = /datum/tier/one

/datum/tech/repeatable/cryomarine_hvh/can_unlock(mob/M)
	. = ..()
	if(!.)
		return
	if(!SSticker.mode)
		to_chat(M, SPAN_WARNING("You can't do this right now!"))
		return

/datum/tech/repeatable/cryomarine_hvh/on_unlock()
	. = ..()
	SSticker.mode.get_specific_call(/datum/emergency_call/cryo_squad/tech, TRUE, FALSE) // "Marine Cryo Reinforcements (Tech)"
