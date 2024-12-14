/datum/emergency_call/upp_cryo
	name = "UPP Naval Infantry (Squad)"
	mob_max = 5
	mob_min = 1
	probability = 0
	objectives = "Assist the UPP forces"
	max_engineers = 1
	max_medics = 1
	max_heavies = 0
	name_of_spawn = /obj/effect/landmark/late_join/upp
	shuttle_id = ""
	var/leaders = 0
	spawn_max_amount = TRUE
	var/heavy_pick = TRUE // whether heavy should count as either a minigunner or shotgunner

/datum/emergency_call/upp_cryo/spawn_candidates(quiet_launch, announce_incoming, override_spawn_loc)
	var/datum/squad/marine/cryo/cryo_squad = GLOB.RoleAuthority.squads_by_type[/datum/squad/upp/five]
	leaders = cryo_squad.roles_in[JOB_UPP_LEADER]
	. = ..()
	marine_announcement("Successfully deployed [mob_max] additional troops, of which [length(members)] are ready for duty.", "ROSTOCK ANNOUNCEMENT SYSTEM", 'sound/misc/notice2.ogg', logging = ARES_LOG_NONE, faction_to_display = FACTION_UPP)
	if(mob_max > length(members))
		announce_dchat("Some cryomarines were not taken, use the Join As Freed Mob verb to take one of them.")

/datum/emergency_call/upp_cryo/create_member(datum/mind/mind, turf/override_spawn_loc)
	var/turf/spawn_loc = override_spawn_loc ? override_spawn_loc : get_spawn_point()

	if(!istype(spawn_loc))
		return //Didn't find a useable spawn point.

	var/mob/living/carbon/human/human = new(spawn_loc)

	if(mind)
		mind.transfer_to(human, TRUE)
	else
		human.create_hud()

	if(!mind)
		FOR_DVIEW(var/obj/structure/machinery/cryopod/pod, 7, human, HIDE_INVISIBLE_OBSERVER)
			if(pod && !pod.occupant)
				pod.go_in_cryopod(human, silent = TRUE)
				break
		FOR_DVIEW_END

	sleep(5)
	if(!leader && (!mind || HAS_FLAG(human.client.prefs.toggles_ert, PLAY_LEADER) && check_timelock(human.client, JOB_SQUAD_LEADER, time_required_for_job)))
		leader = human
		arm_equipment(human, /datum/equipment_preset/upp/leader, TRUE, TRUE)
		to_chat(human, SPAN_ROLE_HEADER("You are an Officer of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
	else if(medics < max_medics && (!mind || HAS_FLAG(human.client.prefs.toggles_ert, PLAY_MEDIC) && check_timelock(human.client, JOB_SQUAD_MEDIC, time_required_for_job)))
		medics++
		to_chat(human, SPAN_ROLE_HEADER("You are a Medic of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
		arm_equipment(human, /datum/equipment_preset/upp/medic, TRUE, TRUE)
	else if(engineers < engineers && (!mind || HAS_FLAG(human.client.prefs.toggles_ert, PLAY_ENGINEER) && check_timelock(human.client, JOB_SQUAD_ENGI, time_required_for_job)))
		engineers++
		to_chat(human, SPAN_ROLE_HEADER("You are a Sapper of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
		arm_equipment(human, /datum/equipment_preset/upp/sapper, TRUE, TRUE)
	else if(heavies < max_heavies && (!mind || ((!heavy_pick && HAS_FLAG(human.client.prefs.toggles_ert, PLAY_HEAVY)) || (heavy_pick && HAS_FLAG(human.client.prefs.toggles_ert, (PLAY_HEAVY|PLAY_SMARTGUNNER)))) && check_timelock(human.client, heavy_pick ? list(JOB_SQUAD_SPECIALIST, JOB_SQUAD_SMARTGUN) : JOB_SQUAD_SPECIALIST, time_required_for_job)))
		heavies++
		to_chat(human, SPAN_ROLE_HEADER("You are a Sergeant of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
		var/equipment_path = /datum/equipment_preset/upp/specialist
		if(heavy_pick)
			if(HAS_FLAG(human.client.prefs.toggles_ert, PLAY_HEAVY) && HAS_FLAG(human.client.prefs.toggles_ert, PLAY_SMARTGUNNER))
				equipment_path = pick(/datum/equipment_preset/upp/specialist, /datum/equipment_preset/upp/machinegunner)
			else if(HAS_FLAG(human.client.prefs.toggles_ert, PLAY_SMARTGUNNER) && !HAS_FLAG(human.client.prefs.toggles_ert, PLAY_HEAVY))
				equipment_path = /datum/equipment_preset/upp/machinegunner
		arm_equipment(human, equipment_path, TRUE, TRUE)
	else if(smartgunners < max_smartgunners && (!mind || HAS_FLAG(human.client.prefs.toggles_ert, PLAY_SMARTGUNNER) && check_timelock(human.client, JOB_SQUAD_SMARTGUN, time_required_for_job)))
		smartgunners++
		to_chat(human, SPAN_ROLE_HEADER("You are a sergeant of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
		arm_equipment(human, /datum/equipment_preset/upp/machinegunner, TRUE, TRUE)
	else
		to_chat(human, SPAN_ROLE_HEADER("You are a soldier of the Union of Progressive People, a powerful socialist state that rivals the United Americas!"))
		arm_equipment(human, /datum/equipment_preset/upp/soldier, TRUE, TRUE)

	sleep(10)
	if(!mind)
		human.free_for_ghosts()

	print_backstory(human)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(to_chat), human, SPAN_BOLD("Objectives: [objectives]")), 1 SECONDS)
