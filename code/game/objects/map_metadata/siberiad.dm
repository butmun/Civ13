/obj/map_metadata/siberiad
	ID = MAP_SIBERIAD
	title = "Operation Siberiad"
	lobby_icon = "icons/lobby/siberiad.png"
	caribbean_blocking_area_types = list(/area/caribbean/no_mans_land/invisible_wall,/area/caribbean/no_mans_land/invisible_wall/one,/area/caribbean/no_mans_land/invisible_wall/two)
	respawn_delay = 600
	no_hardcore = FALSE
	ambience = list('sound/ambience/winter.ogg')

	faction_organization = list(
		AMERICAN,
		RUSSIAN)

	roundend_condition_sides = list(
		list(AMERICAN) = /area/caribbean/no_mans_land/capturable/one,
		list(RUSSIAN) = /area/caribbean/no_mans_land/capturable/one,
		)
	age = "2049"
	faction_distribution_coeffs = list(AMERICAN = 0.5, RUSSIAN = 0.5)
	battle_name = "Siberian Conflict"
	mission_start_message = "<font size=4>The remnants of the <font color = 'blue'>Coalition</font color> and the <font color = red><b>Soviet Army</b></font> are fighting for the control of an <b>Military Industrial Complex</b> in the <b>MIDDLE</b> of the area of operations.<br>In order to win, a side has to hold the <b>Control Room</b> for<b>5 minutes</b>.<br>The battle will start in <b>5 minutes</b>.</font>"
	faction1 = AMERICAN
	faction2 = RUSSIAN
	ordinal_age = 7
	songs = list(
		"Audio - Emissions:1" = "sound/music/emissions.ogg")
	gamemode = "King of the Hill"

/obj/map_metadata/siberiad/faction2_can_cross_blocks()
	return (processes.ticker.playtime_elapsed >= 3600 || admin_ended_all_grace_periods)

/obj/map_metadata/siberiad/faction1_can_cross_blocks()
	return (processes.ticker.playtime_elapsed >= 3600 || admin_ended_all_grace_periods)

/obj/map_metadata/siberiad/job_enabled_specialcheck(var/datum/job/J)
	..()
	if (istype(J, /datum/job/american))
		if (J.is_siberiad)
			. = TRUE
		else
			. = FALSE
	else if (istype(J, /datum/job/russian))
		if (J.is_siberiad)
			. = TRUE
		else
			. = FALSE
	else
		. = FALSE

/obj/map_metadata/siberiad/short_win_time(faction)
	if (!(alive_n_of_side(faction1)) || !(alive_n_of_side(faction2)))
		return 600
	else
		return 3000 // 5 minutes

/obj/map_metadata/siberiad/long_win_time(faction)
	if (!(alive_n_of_side(faction1)) || !(alive_n_of_side(faction2)))
		return 600
	else
		return 3000 // 5 minutes

/obj/map_metadata/siberiad/roundend_condition_def2name(define)
	..()
	switch (define)
		if (AMERICAN)
			return "American"
		if (RUSSIAN)
			return "Soviet"

/obj/map_metadata/siberiad/roundend_condition_def2army(define)
	..()
	switch (define)
		if (AMERICAN)
			return "Americans"
		if (RUSSIAN)
			return "Soviets"

/obj/map_metadata/siberiad/army2name(army)
	..()
	switch (army)
		if ("Americans")
			return "American"
		if ("Soviets")
			return "Soviet"

/obj/map_metadata/siberiad/cross_message(faction)
	if (faction == AMERICAN)
		return "<font size = 4>The <b><font color = blue>Coalition</b></font> may now cross the invisible wall!</font>"
	else if (faction == RUSSIAN)
		return "<font size = 4>The <b><font color = red>Soviets</b></font> may now cross the invisible wall!</font>"
	else
		return ""

/obj/map_metadata/siberiad/reverse_cross_message(faction)
	if (faction == AMERICAN)
		return "<span class = 'userdanger'>The <b><font color = blue>Coalition</b></font> may no longer cross the invisible wall!</span>"
	else if (faction == RUSSIAN)
		return "<span class = 'userdanger'>The <b><font color = red>Soviets</b></font> may no longer cross the invisible wall!</span>"
	else
		return ""

/obj/map_metadata/siberiad/update_win_condition()

	if (world.time >= next_win && next_win != -1)
		if (win_condition_spam_check)
			return FALSE
		ticker.finished = TRUE
		var/message = "The [battle_name ? battle_name : "battle"] has ended in a stalemate!"
		if (current_winner && current_loser)
			message = "The battle is over! The [current_winner] were victorious over the [current_loser][battle_name ? " in the [battle_name]" : ""]!"
		world << "<font size = 4><span class = 'notice'>[message]</span></font>"
		if (current_winner == "Americans")
			for (var/obj/structure/nuclear_missile/nuke in world)
				nuke.activate()
		win_condition_spam_check = TRUE
		return FALSE
	// German major
	else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.33, TRUE))
		if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.33))
			if (last_win_condition != win_condition.hash)
				current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[1][1])] have captured the Industrial Complex! They will win in {time} minute{s}."
				next_win = world.time + short_win_time(roundend_condition_sides[2][1])
				announce_current_win_condition()
				current_winner = roundend_condition_def2army(roundend_condition_sides[1][1])
				current_loser = roundend_condition_def2army(roundend_condition_sides[2][1])
	// German minor
	else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.01, TRUE))
		if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.01))
			if (last_win_condition != win_condition.hash)
				current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[1][1])] have captured the Industrial Complex! They will win in {time} minute{s}."
				next_win = world.time + long_win_time(roundend_condition_sides[2][1])
				announce_current_win_condition()
				current_winner = roundend_condition_def2army(roundend_condition_sides[1][1])
				current_loser = roundend_condition_def2army(roundend_condition_sides[2][1])
	// Soviet major
	else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.33, TRUE))
		if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.33))
			if (last_win_condition != win_condition.hash)
				current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[2][1])] have captured the Industrial Complex! They will win in {time} minute{s}."
				next_win = world.time + short_win_time(roundend_condition_sides[1][1])
				announce_current_win_condition()
				current_winner = roundend_condition_def2army(roundend_condition_sides[2][1])
				current_loser = roundend_condition_def2army(roundend_condition_sides[1][1])
	// Soviet minor
	else if (win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[1]]), roundend_condition_sides[2], roundend_condition_sides[1], 1.01, TRUE))
		if (!win_condition.check(typesof(roundend_condition_sides[roundend_condition_sides[2]]), roundend_condition_sides[1], roundend_condition_sides[2], 1.01))
			if (last_win_condition != win_condition.hash)
				current_win_condition = "The [roundend_condition_def2army(roundend_condition_sides[2][1])] have captured the Industrial Complex! They will win in {time} minute{s}."
				next_win = world.time + long_win_time(roundend_condition_sides[1][1])
				announce_current_win_condition()
				current_winner = roundend_condition_def2army(roundend_condition_sides[2][1])
				current_loser = roundend_condition_def2army(roundend_condition_sides[1][1])

	else
		if (current_win_condition != no_winner && current_winner && current_loser)
			world << "<font size = 3>The [current_winner] have lost control of the Industrial Complex!</font>"
			current_winner = null
			current_loser = null
		next_win = -1
		current_win_condition = no_winner
		win_condition.hash = 0
	last_win_condition = win_condition.hash
	return TRUE

/obj/map_metadata/siberiad/check_caribbean_block(var/mob/living/human/H, var/turf/T)
	if (!istype(H) || !istype(T))
		return FALSE
	var/area/A = get_area(T)
	if (istype(A, /area/caribbean/no_mans_land/invisible_wall))
		if (istype(A, /area/caribbean/no_mans_land/invisible_wall/one))
			if (H.faction_text == faction1)
				return TRUE
		else if (istype(A, /area/caribbean/no_mans_land/invisible_wall/two))
			if (H.faction_text == faction2)
				return TRUE
		else
			return !faction1_can_cross_blocks()
	return FALSE

// MAP SPECIFIC OBJECTS

/obj/structure/nuclear_missile
	name = "nuclear missile"
	desc = "A short range tactical nuclear missile."
	icon = 'icons/obj/decals_wider.dmi'
	icon_state = "rocket"
	density = TRUE
	opacity = FALSE
	not_movable = TRUE
	not_disassemblable = TRUE
	flammable = FALSE
	anchored = TRUE
	var/active = FALSE
	pixel_x = -32
	layer = 6.01

/obj/structure/nuclear_missile/update_icon()
	if (active)
		icon_state = "rocket_fly"
	else
		icon_state = "rocket"
/obj/structure/nuclear_missile/proc/activate()
	if (!active)
		active = TRUE
		update_icon()
		var/sound/uploaded_sound = sound('sound/effects/aircraft/effects/missile_big.ogg', repeat = FALSE, wait = TRUE, channel = 777)
		uploaded_sound.priority = 250
		for (var/mob/M in player_list)
			if (!new_player_mob_list.Find(M))
				M << SPAN_DANGER("<font size=3>A nuclear missile has been launched!</font>")
				M.client << uploaded_sound
		qdel(src)
