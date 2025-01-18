/datum/job/civilian
	gear_preset = /datum/equipment_preset/colonist

/datum/timelock/medic
	name = "Medical Roles"

/datum/timelock/medic/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_MEDIC_ROLES_LIST

/datum/timelock/corporate
	name = "Corporate Roles"

/datum/timelock/corporate/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_CORPORATE_ROLES_LIST


/datum/timelock/civil
	name = "Civil Roles"

/datum/timelock/civil/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_CIVIL_ROLES_LIST

/datum/job/civilian/spawn_in_player(mob/new_player/NP)
	. = ..()
	if (MODE_HAS_FLAG(MODE_FACTION_CLASH))
		var/mob/living/carbon/human/huma = .
		if (!huma.attached_objective)
			huma.attached_objective = new /datum/cm_objective/capture_prisoners/upp(huma)
