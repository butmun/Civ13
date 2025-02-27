var/list/organ_cache = list()

/obj/item/organ
	name = "organ"
	icon = 'icons/obj/surgery.dmi'
	value = 0
	var/dead_icon
	var/mob/living/human/owner = null
	var/status = 0
	var/vital //Lose a vital limb, die immediately.
	var/damage = 0 // amount of damage to the organ

	var/min_bruised_damage = 10
	var/min_broken_damage = 30
	var/max_damage
	var/organ_tag = "organ"

	var/parent_organ = "chest"
	var/rejecting   // Is this organ already being rejected?

	var/list/transplant_data
	var/list/datum/autopsy_data/autopsy_data = list()
	var/list/trace_chemicals = list() // traces of chemicals in the organ,
									  // links chemical IDs to number of ticks for which they'll stay in the blood
	germ_level = FALSE
	var/datum/dna/dna
	var/datum/species/species
	flammable = TRUE

/obj/item/organ/Destroy()
	if (!owner)
		return ..()

	if (istype(owner, /mob/living/human))
		if ((owner.internal_organs) && (src in owner.internal_organs))
			owner.internal_organs -= src
		if (istype(owner, /mob/living/human))
			if ((owner.internal_organs_by_name) && (src in owner.internal_organs_by_name))
				owner.internal_organs_by_name -= src
			if ((owner.organs) && (src in owner.organs))
				owner.organs -= src
			if ((owner.organs_by_name) && (src in owner.organs_by_name))
				owner.organs_by_name -= src
	if (src in owner.contents)
		owner.contents -= src

	return ..()

/obj/item/organ/proc/organ_check()
	if (!src)
		return
	if (!loc || isturf(loc))
		spawn(3000)
			if (src)
				if (!loc || isturf(loc))
					qdel(src)
					return
	spawn(3000)
		if (src)
			organ_check()

/obj/item/organ/proc/update_health()
	return

/obj/item/organ/New(var/mob/living/human/holder, var/internal)
	..(holder)
	organ_check()
	organ_list += src
	create_reagents(5)
	if (!max_damage)
		max_damage = min_broken_damage * 2
	if (istype(holder))
		owner = holder
		species = all_species["Human"]
		if (holder.dna)
			dna = holder.dna.Clone()
			species = all_species[dna.species]
		else
			log_debug("[src] at [loc] spawned without a proper DNA.")
		var/mob/living/human/H = holder
		if (istype(H))
			if (internal)
				var/obj/item/organ/external/E = H.get_organ(parent_organ)
				if (E)
					if (E.internal_organs == null)
						E.internal_organs = list()
					E.internal_organs |= src
			if (dna)
				if (!blood_DNA)
					blood_DNA = list()
				blood_DNA[dna.unique_enzymes] = dna.b_type
		if (internal)
			holder.internal_organs |= src
	update_icon()

/obj/item/organ/Destroy()
	organ_list -= src
	..()

/obj/item/organ/proc/set_dna(var/datum/dna/new_dna)
	if (new_dna)
		dna = new_dna.Clone()
		if (!blood_DNA)
			blood_DNA = list()
		blood_DNA.Cut()
		blood_DNA[dna.unique_enzymes] = dna.b_type
		species = all_species[new_dna.species]

/obj/item/organ/proc/die()
	damage = max_damage
	status |= ORGAN_DEAD
	processing_objects -= src
	if (dead_icon)
		icon_state = dead_icon
	if (owner && vital)
		owner.death()
		owner.can_defib = FALSE

/obj/item/organ/process()

	if (loc != owner)
		owner = null

	//dead already, no need for more processing
	if (status & ORGAN_DEAD)
		return

	if (!owner)
		var/datum/reagent/blood/B = locate(/datum/reagent/blood) in reagents.reagent_list
		if (B && prob(40))
			reagents.remove_reagent("blood",0.1)
			blood_splatter(src,B,1)
		if (config.organs_decay) damage += rand(1,3)
		if (damage >= max_damage)
			damage = max_damage
		germ_level += rand(2,6)
		if (germ_level >= INFECTION_LEVEL_TWO)
			germ_level += rand(2,6)
		if (germ_level >= INFECTION_LEVEL_THREE)
			die()

	else if (owner && owner.bodytemperature >= 170)	//cryo stops germs from moving and doing their bad stuffs
		//** Handle antibiotics and curing infections
		handle_antibiotics()
		handle_rejection()
		handle_germ_effects()

	//check if we've hit max_damage
	if (damage >= max_damage)
		die()

/obj/item/organ/examine(mob/user)
	..(user)
	if (status & ORGAN_DEAD)
		user << "<span class='notice'>The decay has set in.</span>"

/obj/item/organ/proc/handle_germ_effects()
	//** Handle the effects of infections
	var/antibiotics = owner.reagents.get_reagent_amount("penicillin")

	if (germ_level > 0 && germ_level < INFECTION_LEVEL_ONE && prob(30))
		germ_level--

	if (germ_level >= INFECTION_LEVEL_ONE)
		//aiming for germ level to go from ambient to INFECTION_LEVEL_TWO in an average of 15 minutes
		if (antibiotics < 5 && prob(round(germ_level/6)))
			germ_level+=0.5

	if (germ_level >= INFECTION_LEVEL_ONE)
		var/fever_temperature = (owner.species.heat_level_1 - owner.species.body_temperature - 5)* min(germ_level/INFECTION_LEVEL_TWO, TRUE) + owner.species.body_temperature
		owner.bodytemperature += between(0, (fever_temperature - T20C)/BODYTEMP_COLD_DIVISOR + 1, fever_temperature - owner.bodytemperature)

	if (germ_level >= INFECTION_LEVEL_TWO)
		var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
		//spread germs
		if (antibiotics < 5 && parent.germ_level < germ_level && ( parent.germ_level < INFECTION_LEVEL_ONE*2 || prob(30) ))
			parent.germ_level+=0.5

		if (prob(3))	//about once every 30 seconds
			take_damage(1,silent=prob(30))

/obj/item/organ/proc/handle_rejection()
	// Process unsuitable transplants. TODO: consider some kind of
	// immunosuppressant that changes transplant data to make it match.
	if (dna)
		if (!rejecting)
			if (blood_incompatible(dna.b_type, owner.dna.b_type, species, owner.species))
				rejecting = TRUE
		else
			rejecting++ //Rejection severity increases over time.
			if (rejecting % 10 == FALSE) //Only fire every ten rejection ticks.
				switch(rejecting)
					if (1 to 50)
						germ_level+=0.5
					if (51 to 200)
						germ_level += rand(1,2)
					if (201 to 500)
						germ_level += rand(2,3)
					if (501 to INFINITY)
						germ_level += rand(3,5)
						owner.reagents.add_reagent("toxin", rand(1,2))

/obj/item/organ/proc/receive_chem(chemical as obj)
	return FALSE

/obj/item/organ/proc/rejuvenate()
	damage = FALSE
	status = 0
/obj/item/organ/proc/is_damaged()
	return damage > 0

/obj/item/organ/proc/is_bruised()
	return damage >= min_bruised_damage

/obj/item/organ/proc/is_broken()
	return (damage >= min_broken_damage || (status & ORGAN_CUT_AWAY) || (status & ORGAN_BROKEN))

//Germs
/obj/item/organ/proc/handle_antibiotics()
	var/antibiotics = FALSE
	if (owner)
		antibiotics = owner.reagents.get_reagent_amount("penicillin")

	if (!germ_level || antibiotics < 5)
		return

	if (germ_level < INFECTION_LEVEL_ONE)
		germ_level = FALSE	//cure instantly
	else if (germ_level < INFECTION_LEVEL_TWO)
		germ_level -= 6	//at germ_level == 500, this should cure the infection in a minute
	else
		germ_level -= 2 //at germ_level == 1000, this will cure the infection in 5 minutes

/obj/item/organ/proc/take_damage(amount, var/silent=0)

	damage = between(0, damage + amount, max_damage)

	if (owner && parent_organ && amount > 0)
		var/obj/item/organ/external/parent = owner.get_organ(parent_organ)
		if (parent && !silent)
			owner.custom_pain("Something inside your [parent.name] hurts a lot.", 50)

/obj/item/organ/proc/bruise()
	damage = max(damage, min_bruised_damage)


/obj/item/organ/proc/removed(var/mob/living/user)

	if (!istype(owner))
		return

	owner.internal_organs_by_name[organ_tag] = null
	owner.internal_organs_by_name -= organ_tag
	owner.internal_organs_by_name -= null
	owner.internal_organs -= src

	var/obj/item/organ/external/affected = owner.get_organ(parent_organ)
	if (affected) affected.internal_organs -= src

	loc = get_turf(owner)
	processing_objects |= src
	rejecting = null
	if (reagents)
		var/datum/reagent/blood/organ_blood = locate(/datum/reagent/blood) in reagents.reagent_list
		if (!organ_blood || !organ_blood.data["blood_DNA"])
			owner.vessel.trans_to(src, 5, TRUE, TRUE)

	if (owner && vital)
		if (user)
			user.attack_log += "\[[time_stamp()]\]<font color='red'> removed a vital organ ([src]) from [owner.name] ([owner.ckey]) (INTENT: [uppertext(user.a_intent)])</font>"
			owner.attack_log += "\[[time_stamp()]\]<font color='orange'> had a vital organ ([src]) removed by [user.name] ([user.ckey]) (INTENT: [uppertext(user.a_intent)])</font>"
			msg_admin_attack("[user.name] ([user.ckey]) removed a vital organ ([src]) from [owner.name] ([owner.ckey]) (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)", user.ckey, owner.ckey)
		owner.death()
		owner.can_defib = FALSE

	owner = null

/obj/item/organ/proc/replaced(var/mob/living/human/target,var/obj/item/organ/external/affected)

	if (!istype(target)) return

	var/datum/reagent/blood/transplant_blood = locate(/datum/reagent/blood) in reagents.reagent_list
	transplant_data = list()
	if (!transplant_blood)
		transplant_data["species"] =	target.species.name
		transplant_data["blood_type"] = target.dna.b_type
		transplant_data["blood_DNA"] =  target.dna.unique_enzymes
	else
		transplant_data["species"] =	transplant_blood.data["species"]
		transplant_data["blood_type"] = transplant_blood.data["blood_type"]
		transplant_data["blood_DNA"] =  transplant_blood.data["blood_DNA"]

	owner = target
	loc = owner
	processing_objects -= src
	target.internal_organs |= src
	affected.internal_organs |= src
	target.internal_organs_by_name[organ_tag] = src

/obj/item/organ/eyes/replaced(var/mob/living/human/target)

	// Apply our eye colour to the target.
	if (istype(target) && eye_colour)
		target.r_eyes = eye_colour[1]
		target.g_eyes = eye_colour[2]
		target.b_eyes = eye_colour[3]
		target.update_eyes()
	..()

/obj/item/organ/proc/bitten(mob/user)


	user << "<span class = 'notice'>You take an experimental bite out of \the [src].</span>"
	var/datum/reagent/blood/B = locate(/datum/reagent/blood) in reagents.reagent_list
	blood_splatter(src,B,1)

	user.drop_from_inventory(src)
	var/obj/item/weapon/reagent_containers/food/snacks/organ/O = new(get_turf(src))
	O.name = name
	O.icon = icon
	O.icon_state = icon_state

	// Pass over the blood.
	reagents.trans_to(O, reagents.total_volume)

	if (fingerprints) O.fingerprints = fingerprints.Copy()
	if (fingerprintshidden) O.fingerprintshidden = fingerprintshidden.Copy()
	if (fingerprintslast) O.fingerprintslast = fingerprintslast

	user.put_in_active_hand(O)
	qdel(src)

/obj/item/organ/attack_self(mob/user as mob)

	// Convert it to an edible form, yum yum.
	if (user.a_intent == I_HELP && user.targeted_organ == "mouth")
		bitten(user)
		return

/obj/item/organ/attackby(obj/i as obj, mob/user as mob)
	if (istype(i, /obj/item/weapon))
		var/obj/item/weapon/W = i
		if (W.sharp)
			user.visible_message("<span class = 'notice'>[user] starts to carve [src] into a few meat slabs.</span>")
			if (do_after(user, 30, src))
				user.visible_message("<span class = 'notice'>[user] carves [src] into a few meat slabs.</span>")
				for (var/v in TRUE to rand(2,4))
					var/obj/item/weapon/reagent_containers/food/snacks/meat/human/meat = new/obj/item/weapon/reagent_containers/food/snacks/meat/human(get_turf(src))
					meat.name = "[name] meatsteak"
				qdel(src)

/obj/item/organ/proc/is_usable()
	return !(status & (ORGAN_CUT_AWAY|ORGAN_MUTATED|ORGAN_DEAD))

/obj/item/organ/external/stump/is_usable()
	return 0

/obj/item/organ/is_usable()
	return ..() && !is_broken()