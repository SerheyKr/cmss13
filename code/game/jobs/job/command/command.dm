/datum/job/command
	selection_class = "job_command"
	supervisors = "the acting commanding officer"
	total_positions = 1
	spawn_positions = 1

/datum/timelock/command
	name = "Command Roles"

/datum/timelock/command/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_COMMAND_ROLES_LIST

/datum/timelock/mp
	name = "MP Roles"

/datum/timelock/mp/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_POLICE_ROLES_LIST

/datum/timelock/human
	name = "Human Roles"

/datum/timelock/human/can_play(client/C)
	return C.get_total_human_playtime() >= time_required

/datum/timelock/human/get_role_requirement(client/C)
	return time_required - C.get_total_human_playtime()

/datum/timelock/dropship
	name = "Dropship Roles"

/datum/timelock/dropship/New(name, time_required, list/roles)
	. = ..()
	src.roles = JOB_DROPSHIP_ROLES_LIST

/datum/job/command/spawn_in_player(mob/new_player/NP)
	. = ..()
	if (MODE_HAS_FLAG(MODE_FACTION_CLASH))
		var/mob/living/carbon/human/huma = .
		if (!huma.attached_objective)
			huma.attached_objective = new /datum/cm_objective/capture_prisoners/upp(huma)
