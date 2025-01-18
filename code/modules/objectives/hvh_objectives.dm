/datum/cm_objective/capture_prisoners
	name = "Capture"
	objective_flags = OBJECTIVE_DO_NOT_TREE
	value = OBJECTIVE_PRISONER_VALUE
	state = OBJECTIVE_INACTIVE
	controller = TREE_MARINE
	blocked_for_hvh = FALSE
	number_of_clues_to_generate = 0
	var/mob/living/target

/datum/cm_objective/capture_prisoners/activate()
	state = OBJECTIVE_INACTIVE

/datum/cm_objective/capture_prisoners/deactivate()
	state = OBJECTIVE_ACTIVE

/datum/cm_objective/capture_prisoners/upp
	controller = TREE_UPP

/datum/cm_objective/capture_prisoners/New(mob/living/creature)
	if(istype(creature, /mob/living))
		target = creature
		RegisterSignal(creature, COMSIG_MOB_DEATH, PROC_REF(handle_death))
		RegisterSignal(creature, COMSIG_PARENT_QDELETING, PROC_REF(handle_corpse_deletion))
		activate()
	. = ..()

/datum/cm_objective/capture_prisoners/proc/handle_corpse_deletion(mob/living/carbon/deleted_mob)
	SIGNAL_HANDLER

	qdel(src)

/datum/cm_objective/capture_prisoners/proc/handle_death(mob/living/carbon/dead_mob)
	SIGNAL_HANDLER

	deactivate()

	RegisterSignal(dead_mob, COMSIG_HUMAN_REVIVED, PROC_REF(handle_mob_revival))

/datum/cm_objective/capture_prisoners/proc/handle_mob_revival(mob/living/carbon/revived_mob)
	SIGNAL_HANDLER

	UnregisterSignal(revived_mob, COMSIG_HUMAN_REVIVED)

	activate()

/datum/cm_objective/capture_prisoners/complete()
	var/datum/techtree/tree = GET_TREE(controller)
	tree.statistics["captured"]++
	tree.statistics["captured_total_points_earned"] += value

	state = OBJECTIVE_COMPLETE
	award_points()
	deactivate()

/datum/cm_objective/capture_prisoners/check_completion()
	. = ..()
	if(target.stat != DEAD && state == OBJECTIVE_ACTIVE)
		complete()
		return TRUE
	return FALSE

GLOBAL_LIST_EMPTY(capture_scanners)

/obj/structure/machinery/medical_pod/capturescanner
	name = "Capture scanner USCM"
	icon_state = "body_scanner"
	var/faction = FACTION_MARINE

	use_power = USE_POWER_IDLE
	idle_power_usage = 60
	active_power_usage = 5000 //5 kW.

	push_in_timer = 2 SECONDS
	wrenchable = FALSE

/obj/structure/machinery/medical_pod/capturescanner/upp
	faction = FACTION_UPP
	name = "Capture scanner UPP"

/obj/structure/machinery/medical_pod/capturescanner/New()
	GLOB.capture_scanners += src
	. = ..()

/obj/structure/machinery/medical_pod/capturescanner/go_in(mob/creature, mob/putter)
	if (isxeno(creature))
		return

	/// who is doing the work of putting/going in the scanner
	var/mob/main_character
	if(!putter)
		main_character = creature
	else
		main_character = putter
		return


	if(go_in_timer)
		if(!do_after(main_character, go_in_timer, INTERRUPT_NO_NEEDHAND, BUSY_ICON_GENERIC))
			return

	if(occupant)
		to_chat(main_character, SPAN_BOLDNOTICE("\The [src] is already occupied!"))
		return
	if(main_character != creature)
		to_chat(main_character, SPAN_NOTICE("You move [creature.name] inside \the [src]."))
	else
		to_chat(main_character, SPAN_NOTICE("You move into \the [src]."))

	creature.forceMove(src)
	occupant = M
	update_use_power(USE_POWER_ACTIVE)
	update_icon()
	//prevents occupant's belonging from landing inside the machine
	for(var/obj/O in src)
		O.forceMove(loc)

	var/mob/living/carbon/human/huma = creature;
	playsound(src, 'sound/machines/scanning_pod1.ogg')
	if(huma)
		var/datum/cm_objective/attached_objective = huma.attached_objective
		if(attached_objective && faction != huma.personal_faction)
			if(attached_objective.check_completion())
				to_chat(main_character, SPAN_NOTICE("You added prisoner information to the ship prisoner network"))
				return
	to_chat(main_character, SPAN_NOTICE("You failed to add anything useful to the ship prisoner network"))

/obj/structure/machinery/medical_pod/capturescanner/Destroy()
	GLOB.capture_scanners -= src
	if(occupant)
		go_out()
	. = ..()

/obj/structure/machinery/medical_pod/capturescanner/relaymove(mob/user)
	if(user.is_mob_incapacitated(TRUE))
		return
	go_out()

/obj/structure/machinery/medical_pod/capturescanner/ex_act(severity, datum/cause_data/cause_data)
	for(var/atom/movable/mob as mob|obj in src)
		mob.forceMove(loc)
		mob.ex_act(severity, , cause_data)

	switch(severity)
		if(0 to EXPLOSION_THRESHOLD_LOW)
			if (prob(25))
				deconstruct(FALSE)
				return
		if(EXPLOSION_THRESHOLD_LOW to EXPLOSION_THRESHOLD_MEDIUM)
			if (prob(50))
				deconstruct(FALSE)
				return
		if(EXPLOSION_THRESHOLD_MEDIUM to INFINITY)
			deconstruct(FALSE)
			return

#ifdef OBJECTS_PROXY_SPEECH
// Transfers speech to occupant
/obj/structure/machinery/medical_pod/capturescanner/hear_talk(mob/living/sourcemob, message, verb, language, italics)
	if(!QDELETED(occupant) && istype(occupant) && occupant.stat != DEAD)
		proxy_object_heard(src, sourcemob, occupant, message, verb, language, italics)
	else
		..(sourcemob, message, verb, language, italics)
#endif // ifdef OBJECTS_PROXY_SPEECH
