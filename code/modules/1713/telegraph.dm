/obj/structure/telegraph
	name = "telegraph"
	desc = "Used to communicate with distant places."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "telegraph"
	flammable = FALSE
	not_movable = FALSE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/currmsg = ""
	var/list/allowedlist = list("a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z")
/obj/structure/telegraph/proc/convertmsg(var/message)
	var/output = ""
	for (var/i=1, i<=length(message), i++)
		var/ascii_char = text2ascii(message,i)
		switch(ascii_char)
			// A  .. Z
			if (65 to 90)			//Uppercase Letters
				output += ascii2text(ascii_char)

			// a  .. z
			if (97 to 122)			//Lowercase Letters
				output += ascii2text(ascii_char-32)
	return output


/obj/structure/telegraph/verb/name_telegraph()
	set category = null
	set name = "Name"
	set desc = "Name this telegraph."

	set src in view(1)
	var/yn = input(usr, "Name this telegraph?") in list("Yes", "No")
	if (yn == "Yes")
		var/_name = input(usr, "What name?") as text
		name = sanitize(_name, 20)
	return

/obj/structure/telegraph/proc/transmit(var/msg, var/stripmsg)
	if (!msg)
		return
	for (var/obj/structure/phoneline/PL in range(2,src))
		PL.transmit(msg,stripmsg,src,PL)
		return

/obj/structure/telegraph/proc/receive(var/msg, var/stripmsg)
	if (!msg || !stripmsg)
		return
	playsound(loc, 'sound/machines/telegraph.ogg', 65)
	visible_message(msg)
	for (var/obj/structure/teleprinter/TP in range(1,src))
		TP.print(stripmsg)
	return

/obj/structure/telegraph/attack_hand(var/mob/user as mob)
	var/message = input(usr, "Write a word. Up to 10 characters, no spaces, symbols or numbers.") as text
	message = sanitize(message, 10)
	message = convertmsg(message)
	if (message && message != "")
		var/stripmsg = message
		currmsg = "<b><font size=2 color=#FFAE19>\icon[getFlatIcon(src)] [name]:</b></font> \"...[message]...\""
		transmit(currmsg,stripmsg)
		playsound(loc, 'sound/machines/telegraph.ogg', 65)
		icon_state = "telegraph_active"
		update_icon()
		spawn(22)
			icon_state = "telegraph"
			update_icon()
	return

/obj/structure/teleprinter
	name = "teleprinter"
	desc = "Will convert telegraph messages to paper."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "teleprinter0"
	flammable = FALSE
	not_movable = FALSE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/list/inpaper = list()

/obj/structure/teleprinter/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (istype(W, /obj/item/weapon/paper))
		if (isemptylist(inpaper))
			inpaper += W
			user << "You put the paper in the teleprinter."
			user.drop_from_inventory(W)
			W.forceMove(locate(0,0,0))
			icon_state = "teleprinter1"
			update_icon()
		else
			user << "There already is a paper inside! Remove it first."
			return

/obj/structure/teleprinter/attack_hand(var/mob/user as mob)
	for(var/obj/item/weapon/C in inpaper)
		user << "You remove \the [C]."
		C.loc = get_turf(src)
		inpaper -= C
		icon_state = "teleprinter0"
		update_icon()
	return

/obj/structure/teleprinter/proc/print(var/new_text)
	if (isemptylist(inpaper))
		return
	else
		for(var/obj/item/weapon/paper/C in inpaper)
			if (C.free_space >= 22)
				new_text = "<b><font face='Courier New'>Telegram at [roundduration2text()]: [new_text]</b></font><br>"
				C.info += new_text
				C.free_space -= length(strip_html_properly(new_text))

/obj/structure/phoneline
	name = "utility pole"
	desc = "A wood pole with cable hooks on top. Used for phone and telegraph wiring."
	icon = 'icons/obj/obj32x64.dmi'
	icon_state = "powerline"
	flammable = TRUE
	not_movable = TRUE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/obj/structure/phonecable/horizontal/h_cable = null
	var/obj/structure/phonecable/vertical/v_cable = null
	var/currmsg = ""
	var/lastproc = 0
	New()
		..()
		update_lines()

/obj/structure/phoneline/proc/transmit(var/msg, var/stripmsg, var/obj/structure/telegraph/TL, var/obj/structure/phoneline/origin)
	if (!msg || !TL)
		return
	if (world.time <= lastproc)
		return
	else
		//left
		for (var/obj/structure/phoneline/PL in get_turf(locate(x-3,y,z)))
			if (PL != origin && PL != src)
				PL.transmit(msg,stripmsg,TL,src)

		//right
		for (var/obj/structure/phoneline/PL in get_turf(locate(x+3,y,z)))
			if (PL != origin && PL != src)
				PL.transmit(msg,stripmsg,TL,src)

		//up
		for (var/obj/structure/phoneline/PL in get_turf(locate(x,y+3,z)))
			if (PL != origin && PL != src)
				PL.transmit(msg,stripmsg,TL,src)

		//down
		for (var/obj/structure/phoneline/PL in get_turf(locate(x,y-3,z)))
			if (PL != origin && PL != src)
				PL.transmit(msg,stripmsg,TL,src)

		//right next to it
		for (var/obj/structure/phoneline/PL in range(1,src))
			if (PL != origin && PL != src)
				PL.transmit(msg,stripmsg,TL,src)

		for (var/obj/structure/telegraph/TLG in range(2,src))
			if (TLG != TL)
				TLG.receive(msg,stripmsg)
	lastproc = world.time+3
/obj/structure/phoneline/proc/ring_phone(var/target, var/origin, var/obj/structure/telephone/originphone)
	if (!origin || !target)
		return
	if (world.time <= lastproc)
		return
	else
		//left
		for (var/obj/structure/phoneline/PL in get_turf(locate(x-3,y,z)))
			if (PL != origin && PL != src)
				PL.ring_phone(target,origin, originphone)

		//right
		for (var/obj/structure/phoneline/PL in get_turf(locate(x+3,y,z)))
			if (PL != origin && PL != src)
				PL.ring_phone(target,origin, originphone)

		//up
		for (var/obj/structure/phoneline/PL in get_turf(locate(x,y+3,z)))
			if (PL != origin && PL != src)
				PL.ring_phone(target,origin, originphone)

		//down
		for (var/obj/structure/phoneline/PL in get_turf(locate(x,y-3,z)))
			if (PL != origin && PL != src)
				PL.ring_phone(target,origin, originphone)

		//right next to it
		for (var/obj/structure/phoneline/PL in range(1,src))
			if (PL != origin && PL != src)
				PL.ring_phone(target,origin, originphone)

		for (var/obj/structure/telephone/TLG in range(2,src))
			if (TLG.phonenumber == target && TLG.phonenumber != origin)
				if (!TLG.ringing)
					TLG.ringproc(origin, originphone)
	lastproc = world.time+3
/obj/structure/phonecable
	name = "communications cable"
	desc = "A thin copper cable used for communications"
	icon = 'icons/obj/obj128x128.dmi'
	icon_state = "cable_h"
	flammable = TRUE
	not_movable = TRUE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	layer = 5

/obj/structure/phonecable/vertical
	icon_state = "cable_v"

/obj/structure/phonecable/horizontal
	icon_state = "cable_h"

/obj/structure/phonecable/vertical/v2
	icon_state = "cable_v2"

/obj/structure/phoneline/proc/update_lines()
	//left
	for (var/obj/structure/phoneline/PL in get_turf(locate(x-3,y,z)))
		if (!PL.h_cable)
			new/obj/structure/phonecable/horizontal(get_turf(PL))

	//right
	for (var/obj/structure/phoneline/PL in get_turf(locate(x+3,y,z)))
		if (!h_cable)
			new/obj/structure/phonecable/horizontal(get_turf(src))

	//up
	for (var/obj/structure/phoneline/PL in get_turf(locate(x,y+3,z)))
		if (!v_cable)
			new/obj/structure/phonecable/vertical(get_turf(locate(x,y+1,z)))

	//down
	for (var/obj/structure/phoneline/PL in get_turf(locate(x,y-3,z)))
		if (!PL.v_cable)
			new/obj/structure/phonecable/vertical/v2(get_turf(locate(x,y-2,z)))

/////////////////////////////RADIO/////////////////////////////////////
/obj/structure/radio
	name = "radio receiver"
	desc = "Used to communicate with distant places. Set to 150kHz."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "radio_vintage"
	flammable = FALSE
	not_movable = FALSE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/freq = 150 //150 to 300
	var/receiver = TRUE
	var/transmitter = FALSE
	var/receiver_on = TRUE
	var/transmitter_on = FALSE
	var/mob/user = null
	powerneeded = 5
	var/on = FALSE

/obj/structure/radio/transmitter
	name = "radio transmitter"
	icon_state = "radio_transmitter"
	transmitter = TRUE
	receiver = FALSE
	receiver_on = FALSE
	transmitter_on = TRUE
	powerneeded = 20

/obj/structure/radio/transmitter_receiver
	name = "two-way radio"
	icon_state = "radio"
	transmitter = TRUE
	receiver = TRUE
	receiver_on = TRUE
	transmitter_on = TRUE
	powerneeded = 20

/obj/structure/radio/transmitter_receiver/nopower
	name = "two-way radio"
	icon_state = "radio"
	transmitter = TRUE
	receiver = TRUE
	receiver_on = TRUE
	transmitter_on = TRUE
	powerneeded = 0

var/global/FREQ1 = rand(150,200)
var/global/FREQ2 = rand(201,250)

/obj/structure/radio/transmitter_receiver/nopower/faction1/New()
	..()
	freq = FREQ1
/obj/structure/radio/transmitter_receiver/nopower/faction2/New()
	..()
	freq = FREQ2
/obj/structure/radio/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if (!anchored && !istype(W, /obj/item/weapon/wrench))
		user << "<span class='notice'>Fix the radio in place with a wrench first.</span>"
		return
	if (istype(W, /obj/item/stack/cable_coil))
		if (powersource)
			user << "There's already a cable connected here! Split it further from the [src]."
			return
		var/obj/item/stack/cable_coil/CC = W
		powersource = CC.place_turf(get_turf(src), user, turn(get_dir(user,src),180))
		powersource.connections += src
		var/opdir1 = 0
		var/opdir2 = 0
		if (powersource.tiledir == "horizontal")
			opdir1 = 4
			opdir2 = 8
		else if  (powersource.tiledir == "vertical")
			opdir1 = 1
			opdir2 = 2
		powersource.update_icon()

		if (opdir1 != 0 && opdir2 != 0)
			for(var/obj/structure/cable/NCOO in get_turf(get_step(powersource,opdir1)))
				if ((NCOO.tiledir == powersource.tiledir) && NCOO != powersource)
					if (!(powersource in NCOO.connections) && !list_cmp(powersource.connections, NCOO.connections))
						NCOO.connections += powersource
					if (!(NCOO in powersource.connections) && !list_cmp(powersource.connections, NCOO.connections))
						powersource.connections += NCOO
					user << "You connect the two cables."

			for(var/obj/structure/cable/NCOC in get_turf(get_step(powersource,opdir2)))
				if ((NCOC.tiledir == powersource.tiledir) && NCOC != powersource)
					if (!(powersource in NCOC.connections) && !list_cmp(powersource.connections, NCOC.connections))
						NCOC.connections += powersource
					if (!(NCOC in powersource.connections) && !list_cmp(powersource.connections, NCOC.connections))
						powersource.connections += NCOC
		user << "You connect the cable to the [src]."
	else
		..()

/obj/structure/radio/proc/check_power()
	if (!powersource || powerneeded == 0)
		return FALSE
	else
		if (powersource.powered && ((powersource.powerflow-powersource.currentflow) >= powerneeded))
			if (!on)
				powersource.update_power(powerneeded,1)
				on = TRUE
				powersource.currentflow += powerneeded
				powersource.lastupdate2 = world.time
			return TRUE
		else
			if (on)
				powersource.update_power(powerneeded,1)
				on = FALSE
				powersource.currentflow -= powerneeded
				powersource.lastupdate2 = world.time
			return FALSE


/obj/structure/radio/attack_hand(var/mob/attacker)
	interact(attacker)

/obj/structure/radio/interact(var/mob/m)
	if (user)
		if (get_dist(src, user) > 1)
			user = null
	restart
	if (user && user != m)
		if (user.client)
			return
		else
			user = null
			goto restart
	else
		user = m
		do_html(user)

/obj/structure/radio/Topic(href, href_list, hsrc)

	var/mob/user = usr

	if (!user || user.lying)
		return

	user.face_atom(src)

	if (!locate(user) in range(1,src))
		user << "<span class = 'danger'>Get close to the [src] to use it.</span>"
		return FALSE

	if (!user.can_use_hands())
		user << "<span class = 'danger'>You have no hands to use this with.</span>"
		return FALSE

	if (href_list["set_frequency"])
		var/input = input(user, "Choose the frequency to sintonize, in kHz: (150-300, no decimals)") as num
		if (!input)
			return
		freq = sanitize_integer(input, min=150, max=300, default=150)
		user << "Frequency set to [freq]kHz."
		desc = "Used to communicate with distant places. Set to [freq]kHz."
		do_html(user)
		return

	if (href_list["receiver"])
		if (receiver)
			receiver_on = !receiver_on
			do_html(user)
			return

	if (href_list["transmitter"])
		if (transmitter)
			transmitter_on = !transmitter_on
			do_html(user)
			return


	do_html(user)


/obj/structure/radio/verb/name_radio()
	set category = null
	set name = "Name"
	set desc = "Name this radio."

	set src in view(1)
	var/yn = input(usr, "Name this radio?") in list("Yes", "No")
	if (yn == "Yes")
		var/_name = input(usr, "What name?") as text
		name = sanitize(_name, 20)
	return

/obj/structure/radio/proc/do_html(var/mob/m)
	var/style = "Radio Receiver/Transmitter"
	if (receiver && !transmitter)
		style = "Radio Receiver"
	if (!receiver && transmitter)
		style = "Radio Transmitter"
	if (m)
		if (check_power() == FALSE && powerneeded > 0)
			m << browse({"

			<br>
			<html>

			<head>
			<style>
			[common_browser_style]
			</style>
			</head>

			<body>

			<script language="javascript">

			function set(input) {
			  window.location="byond://?src=\ref[src];action="+input.name+"&value="+input.value;
			}

			</script>

			<center>
			<font size=3><b>[style]</b></font><br><br>
			<b><font size=2 color=#8b0000>POWER OFF</a><br><br>
			</center>
			</font></b><br>
			</body>
			</html>
			<br>
			"},  "window=artillery_window;border=1;can_close=1;can_resize=1;can_minimize=0;titlebar=1;size=500x500")
		else

			if (receiver && transmitter)
				m << browse({"

				<br>
				<html>

				<head>
				<style>
				[common_browser_style]
				</style>
				</head>

				<body>

				<script language="javascript">

				function set(input) {
				  window.location="byond://?src=\ref[src];action="+input.name+"&value="+input.value;
				}

				</script>

				<center>
				<font size=3><b>[style]</b></font><br><br>
				</center>
				<b><font size=2>Frequency: <a href='?src=\ref[src];set_frequency=1'>[freq]kHz</a><br><br>
				Transmitter: <a href='?src=\ref[src];transmitter=1'>[transmitter_on ? "ON" : "OFF"]</a><br><br>
				Receiver: <a href='?src=\ref[src];receiver=1'>[receiver_on ? "ON" : "OFF"]</a><br><br>
				</font></b><br>
				</body>
				</html>
				<br>
				"},  "window=artillery_window;border=1;can_close=1;can_resize=1;can_minimize=0;titlebar=1;size=500x500")
			else if (receiver && !transmitter)
				m << browse({"

				<br>
				<html>

				<head>
				<style>
				[common_browser_style]
				</style>
				</head>

				<body>

				<script language="javascript">

				function set(input) {
				  window.location="byond://?src=\ref[src];action="+input.name+"&value="+input.value;
				}

				</script>

				<center>
				<font size=3><b>[style]</b></font><br><br>
				</center>
				<b><font size=2>Frequency: <a href='?src=\ref[src];set_frequency=1'>[freq]kHz</a><br><br>
				Receiver: <a href='?src=\ref[src];receiver=1'>[receiver_on ? "ON" : "OFF"]</a><br><br>
				</font></b><br>
				</body>
				</html>
				<br>
				"},  "window=artillery_window;border=1;can_close=1;can_resize=1;can_minimize=0;titlebar=1;size=500x500")
			else if (!receiver && transmitter)
				m << browse({"

				<br>
				<html>

				<head>
				<style>
				[common_browser_style]
				</style>
				</head>

				<body>

				<script language="javascript">

				function set(input) {
				  window.location="byond://?src=\ref[src];action="+input.name+"&value="+input.value;
				}

				</script>

				<center>
				<font size=3><b>[style]</b></font><br><br>
				</center>
				<b><font size=2>Frequency: <a href='?src=\ref[src];set_frequency=1'>[freq]kHz</a><br><br>
				Transmitter: <a href='?src=\ref[src];transmitter=1'>[transmitter_on ? "ON" : "OFF"]</a><br><br>
				</font></b><br>
				</body>
				</html>
				<br>
				"},  "window=artillery_window;border=1;can_close=1;can_resize=1;can_minimize=0;titlebar=1;size=500x500")

/obj/structure/radio/proc/broadcast(var/msg, var/mob/living/carbon/human/speaker)

	// ignore emotes.
	if (dd_hasprefix(msg, "*"))
		return

	var/list/tried_mobs = list()

	for (var/mob/living/carbon/human/hearer in human_mob_list)
		if (tried_mobs.Find(hearer))
			continue
		tried_mobs += hearer
		var/list/used_radios = list()
		if (hearer.stat == CONSCIOUS)
			var/list/radios = list()
			for (var/obj/structure/radio/radio in view(world.view, hearer))
				if (radio.receiver_on)
					radios |= radio
				if (used_radios.Find(radio))
					continue
				used_radios += radio
				if (radio.freq == freq && radio.receiver_on && (radio.check_power() || radio.powerneeded == 0))
					hearer.hear_radio(msg, speaker.default_language, speaker, src, radio)
	// let observers hear it
	for (var/mob/observer/O in mob_list)
		O.hear_radio(msg, speaker.default_language, speaker, src)


/////////////////////////////PHONE/////////////////////////////////////
/obj/structure/telephone
	name = "telephone"
	desc = "Used to communicate with other telephones. No number."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "telephone"
	flammable = FALSE
	not_movable = FALSE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/phonenumber = 0
	var/ringing = FALSE
	var/ringingnum = FALSE
	var/obj/structure/telephone/origincall = null
	var/connected = FALSE

var/list/global/phone_numbers = list()

/obj/structure/telephone/New()
	..()
	if (phonenumber == 0)
		new_phonenumber()

/obj/structure/telephone/proc/new_phonenumber()
	var/tempnum = 0
	tempnum = rand(1000,9999)
	if (tempnum in phone_numbers)
		new_phonenumber()
		return
	else
		phonenumber = tempnum
		phone_numbers += tempnum
		desc = "Used to communicate with other telephones. Number: [phonenumber]."
		return

/obj/structure/telephone/proc/ringproc(var/origin,var/obj/structure/telephone/ocall)
	ringing = TRUE
	ringingnum = origin
	origincall = ocall
	spawn(0)
		if (ringing)
			ring(origin)
	spawn(40)
		if (ringing)
			ring(origin)
	spawn(80)
		if (ringing)
			ring(origin)
	spawn(120)
		if (ringing)
			ring(origin)
	spawn(160)
		if (ringing)
			ring(origin)
	spawn(200)
		ringing = FALSE
		ringingnum = FALSE
		if (!connected)
			origincall = null
	return
/obj/structure/telephone/proc/ring()
	if (ringing)
		playsound(loc, 'sound/machines/telephone.ogg', 65)
		visible_message("\The [src] rings!")
	else
		return

/obj/structure/telephone/proc/broadcast(var/msg, var/mob/living/carbon/human/speaker)

	// ignore emotes.
	if (dd_hasprefix(msg, "*"))
		return

	var/list/tried_mobs = list()

	for (var/mob/living/carbon/human/hearer in human_mob_list)
		if (tried_mobs.Find(hearer))
			continue
		tried_mobs += hearer
		if (hearer.stat == CONSCIOUS)
			for (var/obj/structure/telephone/phone in view(world.view, hearer))
				if (src == phone.origincall)
					hearer.hear_phone(msg, speaker.default_language, speaker, src, phone)

/obj/structure/telephone/attack_hand(var/mob/user as mob)
	if (!connected && !ringing)
		var/input = input(user, "Choose the number to call: (4 digits, no decimals)") as num
		if (!input)
			return
		var/tgtnum = 0
		tgtnum = sanitize_integer(input, min=1000, max=9999, default=0) //0 as a first digit doesnt really work
		if (tgtnum == 0)
			return
		for (var/obj/structure/phoneline/PL in range(2,src))
			PL.ring_phone(tgtnum,phonenumber, src)
			visible_message("<b><font size=2 color=#FFAE19>\icon[getFlatIcon(src)] Telephone:</b> </font>Ringing [tgtnum]...")
			spawn(200)
				if (!connected)
					visible_message("<b><font size=2 color=#FFAE19>\icon[getFlatIcon(src)] Telephone:</b> </font>Nobody picked up the phone at [tgtnum].")
					return
	if (connected)
		connected = FALSE
		origincall.connected = FALSE
		origincall.origincall = null
		origincall = null
		user << "You hang up the phone."

	if (ringing && ringingnum)
		ringing = FALSE
		connected = ringingnum
		if (origincall)
			origincall.connected = phonenumber
			origincall.ringing = FALSE
			origincall.origincall = src
		user << "You pick up the phone."


//////////////////////////RADIO RECORDER////////////////////
// basically this enables you to schedule regular broadcasts.
/obj/structure/radiorecorder
	name = "voice recorder"
	desc = "Used to record programs to be broadcast by radio."
	icon = 'icons/obj/modern_structures.dmi'
	icon_state = "recorder"
	flammable = TRUE
	not_movable = FALSE
	not_disassemblable = TRUE
	density = FALSE
	opacity = FALSE
	var/list/storedphrases = list()
	var/on = FALSE
	var/bdrunning = FALSE
	var/mob/living/carbon/human/owner = null

/obj/structure/radiorecorder/update_icon()
	..()
	if (on)
		icon_state = "recorder_on"
	else
		icon_state = "recorder"

/obj/structure/radiorecorder/attack_hand(var/mob/user as mob)
	var/input1 = WWinput(user, "Do you want to add or remove phrases?", "Voice Recorder", "Cancel", list("Cancel","Add","Remove"))
	if (input1 == "Cancel")
		return
	else if (input1 == "Add")
		var/input3 = input(usr, "What phrase? Maximum 100 characters.") as text
		if (input3 == "")
			return
		else
			input3 = sanitize(input3, 100)
			storedphrases += input3
			return

	else if (input1 == "Remove")
		var/list/sp2 = storedphrases
		sp2 += "Cancel"
		var/input2 = WWinput(user, "What phrase to remove?", "Voice Recorder", "Cancel", storedphrases)
		if (input2 == "Cancel")
			return
		else
			storedphrases -= input2
			return

/obj/structure/radiorecorder/verb/turnon()
	set category = null
	set name = "Turn On/Off"
	set desc = "Make the recorder play or turn it off."

	set src in view(1)

	if (on)
		usr << "You turn the [src] off."
		on = FALSE
		update_icon()
		return
	else
		usr << "You turn the [src] on."
		on = TRUE
		update_icon()
		owner = usr
		if (!bdrunning)
			broadcast()
			bdrunning = TRUE
		return

/obj/structure/radiorecorder/proc/broadcast()
	if (!on)
		bdrunning = FALSE
		return
	else
		var/bdphrase = pick(storedphrases)
		for(var/obj/structure/radio/RD in range(1,src))
			if (RD.transmitter && RD.transmitter_on && (RD.check_power() || RD.powerneeded == 0))
				RD.broadcast(bdphrase, owner)
		spawn(1200)
			broadcast()