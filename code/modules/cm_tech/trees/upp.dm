GLOBAL_LIST_EMPTY(upp_leaders)

/datum/techtree/upp/proc/transfer_leader_to(mob/living/carbon/human/H)
	if(!H)
		return
	remove_leader()

	RegisterSignal(H, COMSIG_MOVABLE_MOVED, PROC_REF(handle_zlevel_check))
	RegisterSignal(H, COMSIG_MOB_DEATH, PROC_REF(handle_death))

	leader = H

/datum/techtree/upp/proc/remove_leader()
	if(!leader)
		return
	UnregisterSignal(leader, list(
		COMSIG_MOB_DEATH,
		COMSIG_MOVABLE_MOVED
	))
	leader = null

/datum/techtree/upp/proc/handle_death(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if((H.job in job_cannot_be_overridden) && (!dead_leader || !dead_leader.check_tod()))
		RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(cleanup_dead_leader))
		RegisterSignal(H, COMSIG_HUMAN_REVIVED, PROC_REF(readd_leader))
		dead_leader = H
	remove_leader()

/datum/techtree/upp/proc/cleanup_dead_leader(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(dead_leader == H)
		dead_leader = null

/datum/techtree/upp/proc/readd_leader(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(H != dead_leader)
		stack_trace("Non-leader attempted to be re-added back to command.")
		return
	remove_dead_leader()
	transfer_leader_to(H)

/datum/techtree/upp/proc/handle_zlevel_check(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(!is_mainship_level(H.z))
		remove_leader()

/datum/techtree/upp/proc/remove_dead_leader()
	if(!dead_leader)
		return

	UnregisterSignal(dead_leader, list(
		COMSIG_HUMAN_REVIVED,
		COMSIG_PARENT_QDELETING
	))
	dead_leader = null


GLOBAL_LIST_EMPTY(tech_controls_upp)

/datum/techtree/upp
	name = TREE_UPP
	flags = TREE_FLAG_UPP

	background_icon_locked = "marine"

	var/mob/living/carbon/human/leader
	var/mob/living/carbon/human/dead_leader
	var/job_cannot_be_overridden = list(
		JOB_UPP_KOL_OFFICER,
		JOB_UPP_KPT_OFFICER,
		JOB_UPP_MAY_GENERAL,
		JOB_UPP_LT_GENERAL,
		JOB_UPP_GENERAL
	)

	tree_faction = FACTION_UPP

/datum/techtree/upp/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_POST_SETUP, PROC_REF(setup_leader))

/datum/techtree/upp/proc/setup_leader(datum/source)
	SIGNAL_HANDLER
	if(length(GLOB.upp_leaders))
		var/mob/M = GLOB.upp_leaders[JOB_UPP_KOL_OFFICER]
		if(!M)
			M = GLOB.upp_leaders[JOB_UPP_KPT_OFFICER]
		if(M)
			transfer_leader_to(M)

/datum/techtree/upp/generate_tree()
	. = ..()
	for(var/tech_control in GLOB.tech_controls_marine)
		var/obj/structure/machinery/computer/tech_control/TC = tech_control
		TC.attached_tree = src

/datum/techtree/upp/has_access(mob/M, access_required)
	switch(access_required)
		if(TREE_ACCESS_VIEW)
			if(M.faction == tree_faction)
				return TRUE
		if(TREE_ACCESS_MODIFY)
			if(skillcheck(M, SKILL_INTEL, SKILL_INTEL_TRAINED))
				return TRUE

	return FALSE

/datum/techtree/upp/can_attack(mob/living/carbon/H)
	return !ishuman(H)

/obj/structure/machinery/computer/tech_control_upp
	name = "UPP tech control console"
	desc = "A console used to make upp tech purchases."

	icon_state = "techweb"

	req_access = list(ACCESS_UPP_LEADERSHIP)
	density = TRUE
	anchored = TRUE
	wrenchable = FALSE

	var/datum/techtree/upp/attached_tree

/obj/structure/machinery/computer/tech_control_upp/Initialize()
	. = ..()
	GLOB.tech_controls_upp += src
	if(SStechtree.initialized)
		attached_tree = GET_TREE(TREE_UPP)

/obj/structure/machinery/computer/tech_control_upp/Destroy()
	GLOB.tech_controls_upp -= src
	attached_tree = null
	return ..()

// Disallow deconstructing
/obj/structure/machinery/computer/tech_control_upp/attackby(obj/item/I, mob/user)
	return

/obj/structure/machinery/computer/tech_control_upp/attack_hand(mob/M)
	. = ..()

	if(!skillcheck(M, SKILL_INTEL, SKILL_INTEL_TRAINED) && SSmapping.configs[GROUND_MAP].map_name != MAP_WHISKEY_OUTPOST)
		to_chat(M, SPAN_WARNING("You don't have the training to use the [src]."))
		return

	if(!attached_tree)
		return

	var/datum/techtree/tree = GET_TREE(TREE_UPP)
	tree.enter_mob(usr, FALSE)

/datum/techtree/upp/on_tier_change(datum/tier/oldtier)
	if(tier.tier < 2)
		return //No need to announce tier updates for tier 1
	var/name = "ROSTOCK DEFCON LEVEL INCREASED"
	var/input = "THREAT ASSESSMENT LEVEL INCREASED TO LEVEL [tier.tier].\n\nLEVEL [tier.tier] assets have been authorised to handle the situation."
	marine_announcement(message = input, title = name, sound_to_play = 'sound/AI/commandreport.ogg', logging = ARES_LOG_NONE, faction_to_display = tree_faction)

/datum/techtree/upp/can_attack(mob/living/carbon/H)
	return !ishuman(H)
