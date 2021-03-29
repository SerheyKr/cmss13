// To clarify:
// For STORAGE_CLICK_GATHER and STORAGE_QUICK_GATHER functionality,
// see item/attackby() (/game/obj/items.dm)
// Do not remove this functionality without good reason, cough reagent_containers cough.
// -Sayu


/obj/item/storage
	name = "storage"
	icon = 'icons/obj/items/storage.dmi'
	w_class = SIZE_MEDIUM
	var/list/can_hold = new/list() //List of objects which this item can store (if set, it can't store anything else)
	var/list/cant_hold = new/list() //List of objects which this item can't store (in effect only if can_hold isn't set)
	var/list/bypass_w_limit = new/list() //a list of objects which this item can store despite not passing the w_class limit
	var/list/click_border_start = new/list() //In slotless storage, stores areas where clicking will refer to the associated item
	var/list/click_border_end = new/list()
	var/max_w_class = SIZE_SMALL //Max size of objects that this object can store (in effect only if can_hold isn't set)
	var/max_storage_space = 14 //The sum of the storage costs of all the items in this storage item.
	var/storage_slots = 7 //The number of storage slots in this container.
	var/obj/screen/storage/boxes = null
	var/obj/screen/storage/storage_start = null //storage UI
	var/obj/screen/storage/storage_continue = null
	var/obj/screen/storage/storage_end = null
	var/obj/screen/storage/stored_start = null
	var/obj/screen/storage/stored_continue = null
	var/obj/screen/storage/stored_end = null
	var/obj/screen/close/closer = null
	var/foldable = null
	var/use_sound = "rustle"	//sound played when used. null for no sound.
	var/opened = FALSE //Has it been opened before?
	var/list/content_watchers //list of mobs currently seeing the storage's contents
	var/storage_flags = STORAGE_FLAGS_DEFAULT



/obj/item/storage/MouseDrop(obj/over_object as obj)
	if(CAN_PICKUP(usr, src))
		if(over_object == usr) // this must come before the screen objects only block
			open(usr)
			return

		if(!istype(over_object, /obj/screen))
			return ..()

		//Makes sure that the storage is equipped, so that we can't drag it into our hand from miles away.
		//There's got to be a better way of doing this.
		if(loc != usr || (loc && loc.loc == usr))
			return

		if(!usr.is_mob_restrained() && !usr.stat)
			switch(over_object.name)
				if("r_hand")
					usr.drop_inv_item_on_ground(src)
					usr.put_in_r_hand(src)
				if("l_hand")
					usr.drop_inv_item_on_ground(src)
					usr.put_in_l_hand(src)
			add_fingerprint(usr)

/obj/item/storage/clicked(var/mob/user, var/list/mods)
	if(!mods["shift"] && mods["middle"] && CAN_PICKUP(user, src))
		open(user)
		return
	. = ..()

/obj/item/storage/proc/return_inv()
	RETURN_TYPE(/list)
	var/list/L = list(  )

	L += src.contents

	for(var/obj/item/storage/S in src)
		L += S.return_inv()
	for(var/obj/item/gift/G in src)
		L += G.gift
		if (isstorage(G.gift))
			L += G.gift:return_inv()
	return L

/obj/item/storage/proc/show_to(mob/user as mob)
	if(user.s_active != src)
		for(var/obj/item/I in src)
			if(I.on_found(user))
				return
	if(user.s_active)
		user.s_active.hide_from(user)
	user.client.screen -= boxes
	user.client.screen -= storage_start
	user.client.screen -= storage_continue
	user.client.screen -= storage_end
	user.client.screen -= closer
	user.client.screen -= contents
	user.client.screen += closer
	user.client.screen += contents

	if(storage_slots)
		user.client.screen += boxes
	else
		user.client.screen += storage_start
		user.client.screen += storage_continue
		user.client.screen += storage_end

	user.s_active = src
	add_to_watchers(user)
	return

/obj/item/storage/proc/add_to_watchers(mob/user)
	if(!(user in content_watchers))
		LAZYADD(content_watchers, user)
		RegisterSignal(user, COMSIG_PARENT_QDELETING, .proc/watcher_deleted)

/obj/item/storage/proc/del_from_watchers(mob/watcher)
	if(watcher in content_watchers)
		LAZYREMOVE(content_watchers, watcher)
		UnregisterSignal(watcher, COMSIG_PARENT_QDELETING)

/obj/item/storage/proc/hide_from(mob/user as mob)
	if(user.client)
		user.client.screen -= src.boxes
		user.client.screen -= storage_start
		user.client.screen -= storage_continue
		user.client.screen -= storage_end
		user.client.screen -= src.closer
		user.client.screen -= src.contents
	if(user.s_active == src)
		user.s_active = null
	del_from_watchers(user)
	return

/obj/item/storage/proc/can_see_content()
	var/list/lookers = list()
	for(var/mob/M in content_watchers)
		if(M.s_active == src && M.client)
			lookers |= M
		else
			del_from_watchers(M)
	return lookers

/obj/item/storage/proc/open(mob/user)
	if(!opened)
		orient2hud()
		opened = 1
	if (use_sound)
		playsound(src.loc, src.use_sound, 25, 1, 3)

	if (user.s_active)
		user.s_active.close(user)
	show_to(user)

/obj/item/storage/proc/close(mob/user)

	hide_from(user)
	user.s_active = null
	return

//This proc draws out the inventory and places the items on it. tx and ty are the upper left tile and mx, my are the bottm right.
//The numbers are calculated from the bottom-left The bottom-left slot being 1,1.
/obj/item/storage/proc/orient_objs(tx, ty, mx, my)
	var/cx = tx
	var/cy = ty
	boxes.screen_loc = "[tx]:,[ty] to [mx],[my]"
	for (var/obj/O in contents)
		O.screen_loc = "[cx],[cy]"
		O.layer = ABOVE_HUD_LAYER
		cx++
		if (cx > mx)
			cx = tx
			cy--
	closer.screen_loc = "[mx+1],[my]"
	if (storage_flags & STORAGE_SHOW_FULLNESS)
		boxes.update_fullness(src)

//This proc draws out the inventory and places the items on it. It uses the standard position.
/obj/item/storage/proc/slot_orient_objs(var/rows, var/cols, var/list/obj/item/display_contents)
	var/cx = 4
	var/cy = 2+rows
	boxes.screen_loc = "4:16,2:16 to [4+cols]:16,[2+rows]:16"

	if (storage_flags & STORAGE_CONTENT_NUM_DISPLAY)
		for (var/datum/numbered_display/ND in display_contents)
			ND.sample_object.mouse_opacity = 2
			ND.sample_object.screen_loc = "[cx]:16,[cy]:16"
			ND.sample_object.maptext = "<font color='white'>[(ND.number > 1)? "[ND.number]" : ""]</font>"
			ND.sample_object.layer = ABOVE_HUD_LAYER
			cx++
			if (cx > (4+cols))
				cx = 4
				cy--
	else
		for (var/obj/O in contents)
			O.mouse_opacity = 2 //So storage items that start with contents get the opacity trick.
			O.screen_loc = "[cx]:16,[cy]:16"
			O.maptext = ""
			O.layer = ABOVE_HUD_LAYER
			cx++
			if (cx > (4+cols))
				cx = 4
				cy--
	closer.screen_loc = "[4+cols+1]:16,2:16"
	if (storage_flags & STORAGE_SHOW_FULLNESS)
		boxes.update_fullness(src)

var/list/global/item_storage_box_cache = list()

/datum/item_storage_box
	var/obj/screen/storage/start = null
	var/obj/screen/storage/continued = null
	var/obj/screen/storage/end = null

/datum/item_storage_box/New()
	start = new()
	start.icon_state = "stored_start"
	continued = new()
	continued.icon_state = "stored_continue"
	end = new()
	end.icon_state = "stored_end"

/obj/item/storage/proc/space_orient_objs(var/list/obj/item/display_contents)
	var/baseline_max_storage_space = 21 //should be equal to default backpack capacity
	var/storage_cap_width = 2 //length of sprite for start and end of the box representing total storage space
	var/stored_cap_width = 4 //length of sprite for start and end of the box representing the stored item
	var/storage_width = min(round(258 * max_storage_space/baseline_max_storage_space, 1), 284) //length of sprite for the box representing total storage space

	click_border_start.Cut()
	click_border_end.Cut()
	storage_start.overlays.Cut()

	if(QDELETED(storage_continue))
		storage_continue = new /obj/screen/storage()
		storage_continue.name = "storage"
		storage_continue.master = src
		storage_continue.icon_state = "storage_continue"
		storage_continue.screen_loc = "7,7 to 10,8"
		var/matrix/M = matrix()
		M.Scale((storage_width-storage_cap_width*2+3)/32,1)
		storage_continue.apply_transform(M)

	if(!opened) //initialize background box
		storage_start.screen_loc = "4:16,2:16"
		storage_continue.screen_loc = "4:[round(storage_cap_width+(storage_width-storage_cap_width*2)/2+2)],2:16"
		storage_end.screen_loc = "4:[19+storage_width-storage_cap_width],2:16"

	var/startpoint = 0
	var/endpoint = 1
	for(var/obj/item/O in contents)
		startpoint = endpoint + 1
		endpoint += storage_width * O.get_storage_cost()/max_storage_space

		click_border_start.Add(startpoint)
		click_border_end.Add(endpoint)

		if(!item_storage_box_cache["[startpoint], [endpoint], [stored_cap_width]"])
			var/datum/item_storage_box/box = new()
			var/matrix/M_start = matrix()
			var/matrix/M_continue = matrix()
			var/matrix/M_end = matrix()
			M_start.Translate(startpoint, 0)
			M_continue.Scale((endpoint-startpoint-stored_cap_width*2)/32,1)
			M_continue.Translate(startpoint+stored_cap_width+(endpoint-startpoint-stored_cap_width*2)/2 - 16,0)
			M_end.Translate(endpoint-stored_cap_width,0)
			box.start.apply_transform(M_start)
			box.continued.apply_transform(M_continue)
			box.end.apply_transform(M_end)
			item_storage_box_cache["[startpoint], [endpoint], [stored_cap_width]"] = box

		var/datum/item_storage_box/ISB = item_storage_box_cache["[startpoint], [endpoint], [stored_cap_width]"]
		stored_start = ISB.start
		stored_continue = ISB.continued
		stored_end = ISB.end

		storage_start.overlays += src.stored_start
		storage_start.overlays += src.stored_continue
		storage_start.overlays += src.stored_end

		O.screen_loc = "4:[round((startpoint+endpoint)/2)+2],2:16"
		O.maptext = ""
		O.layer = ABOVE_HUD_LAYER

	src.closer.screen_loc = "4:[storage_width+19],2:16"
	return

/obj/screen/storage/clicked(var/mob/user, var/list/mods)
	if(user.is_mob_incapacitated(TRUE))
		return 1

	// Placing something in the storage screen
	if(master)
		var/obj/item/storage/S = master
		var/obj/item/I = user.get_active_hand()
		if(I)
			if (master.attackby(I, user))
				user.next_move = world.time + 2
			return 1

		// Taking something out of the storage screen (including clicking on item border overlay)
		var/list/screen_loc_params = splittext(mods["screen-loc"], ",")
		var/list/screen_loc_X = splittext(screen_loc_params[1],":")
		var/click_x = text2num(screen_loc_X[1])*32+text2num(screen_loc_X[2]) - 144

		for(var/i in 1 to length(S.click_border_start))
			if (S.click_border_start[i] <= click_x && click_x <= S.click_border_end[i])
				I = LAZYACCESS(S.contents, i)
				if (I)
					if (I.clicked(user, mods))
						return 1

					I.attack_hand(user)
					return 1
	return 0


/datum/numbered_display
	var/obj/item/sample_object
	var/number

/datum/numbered_display/New(obj/item/sample)
	if(!istype(sample))
		qdel(src)
	sample_object = sample
	number = 1

/datum/numbered_display/Destroy()
	sample_object = null
	return ..()

//This proc determins the size of the inventory to be displayed. Please touch it only if you know what you're doing.
/obj/item/storage/proc/orient2hud()

	var/adjusted_contents = contents.len

	//Numbered contents display
	var/list/datum/numbered_display/numbered_contents
	if (storage_flags & STORAGE_CONTENT_NUM_DISPLAY)
		numbered_contents = list()
		adjusted_contents = 0
		for (var/obj/item/I in contents)
			var/found = 0
			for (var/datum/numbered_display/ND in numbered_contents)
				if (ND.sample_object.type == I.type)
					ND.number++
					found = 1
					break
			if (!found)
				adjusted_contents++
				numbered_contents.Add( new/datum/numbered_display(I) )

	if (storage_slots == null)
		src.space_orient_objs(numbered_contents)
	else
		var/row_num = 0
		var/col_count = min(7,storage_slots) -1
		if (adjusted_contents > 7)
			row_num = round((adjusted_contents-1) / 7) // 7 is the maximum allowed width.
		slot_orient_objs(row_num, col_count, numbered_contents)
	return

//This proc return 1 if the item can be picked up and 0 if it can't.
//Set the stop_messages to stop it from printing messages
/obj/item/storage/proc/can_be_inserted(obj/item/W as obj, stop_messages = 0)
	if(!istype(W) || (W.flags_item & NODROP)) return //Not an item

	if(src.loc == W)
		return 0 //Means the item is already in the storage item

	//specific labeler check
	if(istype(W, /obj/item/tool/hand_labeler))
		var/obj/item/tool/hand_labeler/L = W
		if(L.mode)
			return 0

	if(W.heat_source && !isigniter(W))
		to_chat(usr, SPAN_ALERT("[W] is on fire!"))
		return

	if(storage_slots != null && contents.len >= storage_slots)
		if(!stop_messages)
			to_chat(usr, SPAN_NOTICE("[src] is full, make some space."))
		return 0 //Storage item is full

	if(can_hold.len)
		var/ok = 0
		for(var/A in can_hold)
			if(istype(W, A))
				ok = 1
				break
		if(!ok)
			if(!stop_messages)
				if (istype(W, /obj/item/tool/hand_labeler))
					return 0
				to_chat(usr, SPAN_NOTICE("[src] cannot hold [W]."))
			return 0

	for(var/A in cant_hold) //Check for specific items which this container can't hold.
		if(istype(W, A))
			if(!stop_messages)
				to_chat(usr, SPAN_NOTICE("[src] cannot hold [W]."))
			return 0

	var/w_limit_bypassed = 0
	if(bypass_w_limit.len)
		for(var/A in bypass_w_limit)
			if(istype(W, A))
				w_limit_bypassed = 1
				break

	if (!w_limit_bypassed && W.w_class > max_w_class)
		if(!stop_messages)
			to_chat(usr, SPAN_NOTICE("[W] is too long for this [src]."))
		return 0

	//calculate storage space only for containers that don't have slots
	if (storage_slots == null)
		var/sum_storage_cost = W.get_storage_cost()
		for(var/obj/item/I in contents)
			sum_storage_cost += I.get_storage_cost() //Adds up the combined storage costs which will be in the storage item if the item is added to it.

		if(sum_storage_cost > max_storage_space)
			if(!stop_messages)
				to_chat(usr, SPAN_NOTICE("[src] is full, make some space."))
			return 0

	if(W.w_class >= src.w_class && (isstorage(W)))
		if(!istype(src, /obj/item/storage/backpack/holding))	//bohs should be able to hold backpacks again. The override for putting a boh in a boh is in backpack.dm.
			if(!stop_messages)
				to_chat(usr, SPAN_NOTICE("[src] cannot hold [W] as it's a storage item of the same size."))
			return 0 //To prevent the stacking of same sized storage items.

	return 1

//This proc handles items being inserted. It does not perform any checks of whether an item can or can't be inserted. That's done by can_be_inserted()
//The stop_warning parameter will stop the insertion message from being displayed. It is intended for cases where you are inserting multiple items at once,
//such as when picking up all the items on a tile with one click.
//user can be null, it refers to the potential mob doing the insertion.
/obj/item/storage/proc/handle_item_insertion(obj/item/W, prevent_warning = 0, mob/user)
	if(!istype(W))
		return FALSE
	if(user && W.loc == user)
		if(!user.drop_inv_item_to_loc(W, src))
			return FALSE
	else
		W.forceMove(src)
	W.on_enter_storage(src)
	if(user)
		if (user.client && user.s_active != src)
			user.client.screen -= W
		add_fingerprint(user)
		if(!prevent_warning)
			var/visidist = W.w_class >= 3 ? 3 : 1
			user.visible_message(SPAN_NOTICE("[usr] puts [W] into [src]."),\
								SPAN_NOTICE("You put \the [W] into [src]."),\
								null, visidist)
	orient2hud()
	for(var/mob/M in can_see_content())
		show_to(M)
	if (storage_slots)
		W.mouse_opacity = 2 //not having to click the item's tiny sprite to take it out of the storage.
	update_icon()
	return TRUE

//Call this proc to handle the removal of an item from the storage item. The item will be moved to the atom sent as new_target
/obj/item/storage/proc/remove_from_storage(obj/item/W as obj, atom/new_location)
	if(!istype(W)) return 0

	for(var/mob/M in can_see_content())
		if(M.client)
			M.client.screen -= W

	if(new_location)
		if(ismob(new_location))
			W.layer = ABOVE_HUD_LAYER
			W.pickup(new_location)
		else
			W.layer = initial(W.layer)
		W.forceMove(new_location)
	else
		W.forceMove(get_turf(src))

	orient2hud()
	for(var/mob/M in can_see_content())
		show_to(M)
	if(W.maptext)
		W.maptext = ""
	W.on_exit_storage(src)
	update_icon()
	W.mouse_opacity = initial(W.mouse_opacity)
	return 1

//This proc is called when you want to place an item into the storage item.
/obj/item/storage/attackby(obj/item/W as obj, mob/user as mob)
	..()

	if(isrobot(user))
		to_chat(user, SPAN_NOTICE(" You're a robot. No."))
		return //Robots can't interact with storage items.

	if(!can_be_inserted(W))
		return

	W.add_fingerprint(user)
	return handle_item_insertion(W, FALSE, user)

/obj/item/storage/attack_hand(mob/user)
	if (loc == user)
		if(storage_flags & STORAGE_USING_DRAWING_METHOD && ishuman(user) && contents.len)
			var/obj/item/I = contents[contents.len]
			I.attack_hand(user)
		else
			open(user)
	else
		..()
		for(var/mob/M in content_watchers)
			close(M)
	add_fingerprint(user)

/obj/item/storage/verb/toggle_gathering_mode()
	set name = "Switch Gathering Method"
	set category = "Object"
	set src in usr
	storage_flags ^= STORAGE_GATHER_SIMULTAENOUSLY
	if (storage_flags & STORAGE_GATHER_SIMULTAENOUSLY)
		to_chat(usr, "[src] now picks up all items in a tile at once.")
	else
		to_chat(usr, "[src] now picks up one item at a time.")

/obj/item/storage/verb/toggle_draw_mode()
	set name = "Switch Storage Drawing Method"
	set category = "Object"
	set src in usr
	storage_flags ^= STORAGE_USING_DRAWING_METHOD
	if (storage_flags & STORAGE_USING_DRAWING_METHOD)
		to_chat(usr, "Clicking [src] with an empty hand now puts the last stored item in your hand.")
	else
		to_chat(usr, "Clicking [src] with an empty hand now opens the pouch storage menu.")

/obj/item/storage/verb/toggle_click_empty()
	set name = "Toggle Tile Dumping"
	set category = "Object"
	set src in usr
	storage_flags ^= STORAGE_CLICK_EMPTY
	if (storage_flags & STORAGE_CLICK_EMPTY)
		to_chat(usr, "Clicking on a tile with [src] in your hand now empties its contents on that tile.")
	else
		to_chat(usr, "Clicking on a tile with [src] in your hand will no longer do anything.")

/obj/item/storage/verb/empty_verb()
	set name = "Empty"
	set category = "Object"
	set src in usr
	var/mob/living/carbon/human/H = usr
	if (!ishuman(H) || loc != H || H.is_mob_restrained())
		return

	empty(H, get_turf(H))

/obj/item/storage/proc/empty(var/mob/user, var/turf/T)
	if (!ishuman(user) || loc != user || user.is_mob_restrained())
		return
	if (!(storage_flags & STORAGE_ALLOW_EMPTY))
		return

	if (!isturf(T) || get_dist(src, T) > 1)
		T = get_turf(src)

	if(!allowed(user))
		to_chat(user, SPAN_WARNING("Access denied."))
		return

	if (!(storage_flags & STORAGE_QUICK_EMPTY))
		user.visible_message(SPAN_NOTICE("[user] starts to empty \the [src]..."),
			SPAN_NOTICE("You start to empty \the [src]..."))
		if (!do_after(user, 2 SECONDS, INTERRUPT_ALL, BUSY_ICON_GENERIC))
			return

	hide_from(user)
	for (var/obj/item/I in contents)
		remove_from_storage(I, T)
	user.visible_message(SPAN_NOTICE("[user] empties \the [src]."),
		SPAN_NOTICE("You empty \the [src]."))


/obj/item/storage/proc/dump_into(obj/item/storage/M, mob/user)
	if(user.action_busy)
		return

	if(istype(M,/obj/item/ammo_magazine/shotgun)) //for inserting handfuls of shotgun shells
		var/obj/item/ammo_magazine/shotgun/B = M
		var/handfuls = round(B.current_rounds / 5,1) //The number of handfuls, we round up because we still want the last one that isn't full
		if(B.current_rounds != 0)
			if(contents.len < storage_slots)
				to_chat(user, SPAN_NOTICE("You start refilling [src] with [B]."))
				if(!do_after(user, 15, INTERRUPT_ALL, BUSY_ICON_GENERIC)) return
				for(var/i = 1 to handfuls)
					if(contents.len < storage_slots)
						//Hijacked from /obj/item/ammo_magazine/proc/create_handful because it had to be handled differently
						//All this because shell types are instances and not their own objects
						var/R
						var/obj/item/ammo_magazine/handful/new_handful = new /obj/item/ammo_magazine/handful
						var/MR = B.caliber == "12g" ? 5 : 8
						R = 5 ? min(B.current_rounds, 5) : min(B.current_rounds, MR)
						new_handful.generate_handful(B.default_ammo, B.caliber, MR, R, B.gun_type)
						B.current_rounds -= R
						handle_item_insertion(new_handful,1,user)
						update_icon(-R)
					else
						break
				playsound(user.loc, "rustle", 15, 1, 6)
				B.update_icon()
			else
				to_chat(user, SPAN_WARNING("[src] is full."))
		else
			to_chat(user, SPAN_WARNING("[B] is empty."))

	else if(istype(M,/obj/item/storage)) //for transfering from storage containers
		if(M.contents.len)
			if(contents.len < storage_slots)
				to_chat(user, SPAN_NOTICE("You start refilling [src] with [M]."))
				if(!do_after(user, 15, INTERRUPT_ALL, BUSY_ICON_GENERIC)) return
				for(var/obj/item/I in M)
					if(contents.len < storage_slots)
						M.remove_from_storage(I)
						handle_item_insertion(I, 1, user) //quiet insertion
					else
						break
				playsound(user.loc, "rustle", 15, 1, 6)
			else
				to_chat(user, SPAN_WARNING("[src] is full."))
		else
			to_chat(user, SPAN_WARNING("[M] is empty."))
	return TRUE

/obj/item/storage/Initialize()
	. = ..()
	if (!(storage_flags & STORAGE_QUICK_GATHER))
		verbs -= /obj/item/storage/verb/toggle_gathering_mode

	if (!(storage_flags & STORAGE_ALLOW_DRAWING_METHOD_TOGGLE))
		verbs -= /obj/item/storage/verb/toggle_draw_mode

	if (!(storage_flags & STORAGE_ALLOW_EMPTY))
		verbs -= /obj/item/storage/verb/empty_verb

	boxes = new
	boxes.name = "storage"
	boxes.master = src
	boxes.icon_state = "block"
	boxes.screen_loc = "7,7 to 10,8"
	boxes.layer = HUD_LAYER

	storage_start = new /obj/screen/storage()
	storage_start.name = "storage"
	storage_start.master = src
	storage_start.icon_state = "storage_start"
	storage_start.screen_loc = "7,7 to 10,8"
	storage_end = new /obj/screen/storage()
	storage_end.name = "storage"
	storage_end.master = src
	storage_end.icon_state = "storage_end"
	storage_end.screen_loc = "7,7 to 10,8"

	closer = new
	closer.master = src

	fill_preset_inventory()

	update_icon()

/*
 * We need to do this separately from Destroy too...
 * When a mob is deleted, it's first ghostize()ed,
 * then its equipement is deleted. This means that client
 * is already unset and can't be used for clearing 
 * screen objects properly.
 */
/obj/item/storage/proc/watcher_deleted(mob/watcher)
	SIGNAL_HANDLER
	hide_from(watcher)

/obj/item/storage/Destroy()
	for(var/mob/M in content_watchers)
		hide_from(M)
	content_watchers = null
	QDEL_NULL(boxes)
	QDEL_NULL(storage_start)
	QDEL_NULL(storage_continue)
	QDEL_NULL(storage_end)
	QDEL_NULL(stored_start)
	QDEL_NULL(stored_continue)
	QDEL_NULL(stored_end)
	QDEL_NULL(closer)
	return ..()

/obj/item/storage/emp_act(severity)
	if(!istype(src.loc, /mob/living))
		for(var/obj/O in contents)
			O.emp_act(severity)
	..()

/obj/item/storage/attack_self(mob/user)
	//Clicking on itself will empty it, if it has the verb to do that.
	if (storage_flags & STORAGE_ALLOW_EMPTY)
		empty(user)
		return

	//Otherwise we'll try to fold it.
	if ( contents.len )
		return

	if(!foldable)
		return

	// Close any open UI windows first
	for (var/mob/M in content_watchers)
		close(M)

	if(ispath(foldable))
		new foldable(get_turf(src))
	to_chat(user, SPAN_NOTICE("You fold [src] flat."))
	qdel(src)

/obj/item/storage/afterattack(atom/target, mob/user, proximity)
	if(!proximity)
		return

	if(isturf(target) && get_dist(src, target) <= 1 && storage_flags & STORAGE_CLICK_EMPTY)
		empty(user, target)

/obj/item/storage/hear_talk(mob/M as mob, text)
	for (var/atom/A in src)
		if(istype(A,/obj/))
			var/obj/O = A
			O.hear_talk(M, text)

/obj/item/proc/get_storage_cost() //framework for adjusting storage costs
	if (storage_cost)
		return storage_cost
	else
		return w_class

/obj/item/storage/proc/fill_preset_inventory()
	return

//Returns the storage depth of an atom. This is the number of storage items the atom is contained in before reaching toplevel (the area).
//Returns -1 if the atom was not found on container.
/atom/proc/storage_depth(atom/container)
	var/depth = 0
	var/atom/cur_atom = src

	while (cur_atom && !(cur_atom in container.contents))
		if (isarea(cur_atom))
			return -1
		if (isstorage(cur_atom.loc))
			depth++
		cur_atom = cur_atom.loc

	if (!cur_atom)
		return -1	//inside something with a null loc.

	return depth

//Like storage depth, but returns the depth to the nearest turf
//Returns -1 if no top level turf (a loc was null somewhere, or a non-turf atom's loc was an area somehow).
/atom/proc/storage_depth_turf()
	var/depth = 0
	var/atom/cur_atom = src

	while (cur_atom && !isturf(cur_atom))
		if (isarea(cur_atom))
			return -1
		if (isstorage(cur_atom.loc))
			depth++
		cur_atom = cur_atom.loc

	if (!cur_atom)
		return -1	//inside something with a null loc.

	return depth
