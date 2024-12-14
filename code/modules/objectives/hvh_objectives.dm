/datum/cm_objective/capture_prisoners
	name = "Capture prisoners"
	objective_flags = OBJECTIVE_DO_NOT_TREE
	value = OBJECTIVE_PRISONER_VALUE
	state = OBJECTIVE_ACTIVE
	controller = TREE_MARINE
	blocked_for_hvh = FALSE
	var/list/scored_bodies = list()

/datum/cm_objective/capture_prisoners/post_round_start()
	activate()

/datum/cm_objective/capture_prisoners/upp
	controller = TREE_UPP
	scored_bodies = list()



/obj/structure/machinery/medical_pod/capturescanner
	name = "Capture scanner"
	icon_state = "body_scanner"

	use_power = USE_POWER_IDLE
	idle_power_usage = 60
	active_power_usage = 10000 //10 kW.

	push_in_timer = null

	var/obj/structure/machinery/captured_scanconsole/connected

/obj/structure/machinery/medical_pod/capturescanner/Initialize()
	. = ..()
	connect_captured_scanconsole()
	flags_atom |= USES_HEARING

/obj/structure/machinery/medical_pod/capturescanner/go_in(mob/M, mob/putter)
	. = ..()
	playsound(src, 'sound/machines/scanning_pod1.ogg')

/obj/structure/machinery/medical_pod/capturescanner/proc/connect_captured_scanconsole()
	if(connected)
		return
	if(dir == EAST || dir == SOUTH)
		connected = locate(/obj/structure/machinery/captured_scanconsole, get_step(src, EAST))
	if(dir == WEST || dir == NORTH)
		connected = locate(/obj/structure/machinery/captured_scanconsole, get_step(src, WEST))
	if(connected)
		connected.connected = src

/obj/structure/machinery/medical_pod/capturescanner/Destroy()
	if(occupant)
		go_out()
	if(connected)
		connected.connected = null
		QDEL_NULL(connected)
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

/obj/structure/machinery/captured_scanconsole
	name = "captured scanner console"
	icon = 'icons/obj/structures/machinery/cryogenics.dmi'
	icon_state = "body_scannerconsole"
	density = FALSE
	anchored = TRUE
	dir = SOUTH
	unslashable = TRUE
	var/obj/structure/machinery/medical_pod/capturescanner/connected
	var/known_implants = list(/obj/item/implant/chem, /obj/item/implant/death_alarm, /obj/item/implant/loyalty, /obj/item/implant/tracking, /obj/item/implant/neurostim)
	var/delete
	var/temphtml
	var/datum/health_scan/last_health_display

/obj/structure/machinery/captured_scanconsole/Initialize()
	. = ..()
	connect_bodyscanner()


/obj/structure/machinery/captured_scanconsole/proc/connect_bodyscanner()
	if(connected)
		return
	if(dir == EAST || dir == SOUTH)
		connected = locate(/obj/structure/machinery/medical_pod/capturescanner,get_step(src, WEST))
	if(dir == WEST || dir == NORTH)
		connected = locate(/obj/structure/machinery/medical_pod/capturescanner,get_step(src, EAST))
	if(connected)
		connected.connected = src


/obj/structure/machinery/captured_scanconsole/Destroy()
	QDEL_NULL(last_health_display)
	if(connected)
		if(connected.occupant)
			connected.go_out()

		connected.connected = null
		QDEL_NULL(connected)
	. = ..()


/obj/structure/machinery/captured_scanconsole/ex_act(severity)
	switch(severity)
		if(EXPLOSION_THRESHOLD_LOW to EXPLOSION_THRESHOLD_MEDIUM)
			if (prob(50))
				deconstruct(FALSE)
				return
		if(EXPLOSION_THRESHOLD_MEDIUM to INFINITY)
			deconstruct(FALSE)
			return

/obj/structure/machinery/captured_scanconsole/power_change()
	..()
	if(stat & BROKEN)
		icon_state = "body_scannerconsole-p"
	else
		if (stat & NOPOWER)
			spawn(rand(0, 15))
				src.icon_state = "body_scannerconsole-p"
		else
			icon_state = initial(icon_state)



/obj/structure/machinery/captured_scanconsole/attack_remote(user as mob)
	return src.attack_hand(user)

/obj/structure/machinery/captured_scanconsole/attack_hand(mob/living/user)
	if(..())
		return
	if(inoperable())
		to_chat(user, SPAN_WARNING("This console is not functional."))
		return
	if(!connected || (connected.inoperable()))
		to_chat(user, SPAN_WARNING("This console is not connected to a functioning body scanner."))
		return

	if(!connected.occupant)
		to_chat(user, SPAN_WARNING("No lifeform detected."))
		return

	if(!ishuman(connected.occupant))
		to_chat(user, SPAN_WARNING("This device can only scan compatible lifeforms."))
		return

	var/mob/living/carbon/human/occupant = connected.occupant

	if (!isliving(occupant) || occupant.stat == DEAD)
		to_chat(user, SPAN_WARNING("This device can only scan active lifeforms."))
		return



	//visible_message(SPAN_NOTICE("\The [src] pings as it stores the scan report of [H.real_name]"))
	playsound(src.loc, 'sound/machines/screen_output1.ogg', 25)

	return
