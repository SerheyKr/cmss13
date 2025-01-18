/datum/job/logistics
	supervisors = "the auxiliary support officer"
	total_positions = 1
	spawn_positions = 1

/datum/timelock/engineer
	name = "Engineering Roles"

/datum/timelock/engineer/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_ENGINEER_ROLES_LIST

/datum/timelock/requisition
	name = "Requisition Roles"

/datum/timelock/requisition/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_REQUISITION_ROLES_LIST

/datum/job/logistics/spawn_in_player(mob/new_player/NP)
	. = ..()
	if (MODE_HAS_FLAG(MODE_FACTION_CLASH))
		var/mob/living/carbon/human/huma = .
		if (!huma.attached_objective)
			huma.attached_objective = new /datum/cm_objective/capture_prisoners/upp(huma)
