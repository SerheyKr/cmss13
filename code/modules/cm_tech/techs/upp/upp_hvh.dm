
/datum/tech/repeatable/cryomarine_upp
	name = "Wake Up Additional Troops"
	desc = "Wakes up additional troops to fight against any threats."
	icon_state = "cryotroops"

	announce_message = "Additional troops are being taken out of cryo."
	announce_name = "ROSTOCK SPECIAL ASSETS AUTHORIZED"
	announce_faction = FACTION_UPP

	required_points = 5
	increase_per_purchase = 0

	flags = TREE_FLAG_UPP
	tier = /datum/tier/one

	log_to_ares = FALSE

/datum/tech/repeatable/cryomarine_upp/can_unlock(mob/M)
	. = ..()
	if(!.)
		return
	if(!SSticker.mode)
		to_chat(M, SPAN_WARNING("You can't do this right now!"))
		return

/datum/tech/repeatable/cryomarine_upp/on_unlock()
	. = ..()
	SSticker.mode.get_specific_call(/datum/emergency_call/upp_cryo, TRUE, FALSE)
