require ("util")
local task = require("tasks")
local destination = {x = 0, y = 0}
local state = 1
local idle = 0
local pick = 0
local dropping = 0
local dupevent = 0
local dbg = 0
local mining_done = 0

local finished = 0

local function debug(p, msg)
	if dbg > 0 then
		p.print(msg)
	end
end

local function build(p, position, item, direction)
	-- Check if we have the item
	if p.get_item_count(item) == 0 then
		debug(p, string.format("build: not enough items: %d", state))
		return false
	end

	-- Grenade special stuff
	if item == "grenade" then
		p.update_selected_entity(position)
		if not p.selected then
			return false
		end
		p.surface.create_entity{name = item, position = p.position, target=p.selected, force="player", speed=0.35}
		p.remove_item({name = item, count = 1})
		return true
	end

	-- Brick special stuff Doesn't work
	--if item == "stone-brick" then
	--	p.surface.set_tiles({name = item, position = position})
		--canplace = p.can_place_entity{name = "tile", inner_name = item, position = position, force="player"}
		--if canplace then
		--	p.surface.create_entity{name = "tile", inner_name = item, position = position, force="player"}	
		--	return true
		--else
			--debug(p, string.format("build: cannot place: %d", state))
		--	return false
		--end
	--	return true
	--end

	-- Check if we can actually place the item at this tile
	local canplace = p.can_place_entity{name = item, position = position, direction = direction}
	local asm = false

	if canplace then
		canplace = p.surface.can_fast_replace{name = item, position = position, direction = direction, force = "player"}
		if canplace then
			asm = p.surface.create_entity{name = item, position = position, direction = direction, force="player", fast_replace=true, player=p}
			if asm then
				--When fast replace succeeds, it triggers the on_player_mined_entity event for each item replaced.
				--My handler for that event advances state (otherwise the player would "mine" forever). After the build
				--completes, state on_tick advances state doTask() completes through normal state advancement.
				--Therefore state gets advanced twice in most cases. So I decrement state here so the net value of state
				--is incremented by only one.
				--This issue becomes a serious bug with the splitter, since fast replacing with that item is able to trigger
				--two on_player_mined_entity events, thus advancing state yet another time. For now I handle that by making
				--sure splitters replace at most 1 belt.
				--From swni on Reddit: "Presumably the reason that "state" gets advanced when using fast replace is because 
				--              on_player_mined_item gets called for picking up the replaced building."
				--I have a better answer for this, but it breaks my 0.18.17 run:
				--Using the mining_done variable means I don't increment state in the on_player_mined_item event.
				--It's a better way, which I would want to use in the future. I wonder if it is dependent upon the
				--order events are processed, possibly a race condition (on_tick vs on_player_mined_entity)
				--Hey also, can_fast_replace does not do distance checking, so it could be
				--cheaty here if I were dishonest. (Is this still true?)
				state = state - 1
			end
		else
			asm = p.surface.create_entity{name = item, position = position, direction = direction, force="player"}
		end
	else
		--debug(p, string.format("build: cannot place: %d", state))
		return false
	end
	if asm then
		p.remove_item({name = item, count = 1})
	end
	return true
end

local function craft(p, count, recipe)
	amt = p.begin_crafting{recipe = recipe, count = count}
	--XETX Do I want to return false if amt = 0?
	return true
end

local function filter(p, position, filter, slot)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("filter: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("filter: entity not reachable: %d", state))
	 	return false
	end
	p.selected.set_filter(slot, filter)
	return true
end

local function launch(p, position)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("launch: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("launch: entity not reachable: %d", state))
		return false
	end
	return p.selected.launch_rocket()
end

local function limit(p, position, limit, slot)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("limit: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("limit: entity not reachable: %d", state))
		return false
	end

	local otherinv = p.selected.get_inventory(slot)

	if not otherinv then
		debug(p, string.format("limit: no slot: %d", state))
		return true
	end

	--hasbar No longer in the API
	--if not otherinv.hasbar() then
	--	debug(p, string.format("limit: entity has no bar: %d", state))
	--	return true
	--end

	-- Setting setbar to 1 completely limits all slots, so it's off by one
	otherinv.set_bar(limit+1)
	return true
end

local function priority(p, position, input, output, filter)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("priority: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("priority: entity not reachable: %d", state))
	    return false
	end
	p.selected.splitter_input_priority = input
	p.selected.splitter_output_priority = output
	if filter == "none" then
		p.selected.splitter_filter = nil
	else
		p.selected.splitter_filter = filter
	end
	return true
end

local function put(p, position, item, amount, slot)
	p.update_selected_entity(position)

	if not p.selected then
		--debug(p, string.format("put: entity not selected: %d", state))
		return false
	end

 	if not p.can_reach_entity(p.selected) then
 		--debug(p, string.format("put: entity not reachable: %d", state))
 		return false
 	end

	local amountininventory = p.get_item_count(item)
	local otherinv = p.selected.get_inventory(slot)
	local toinsert = math.min(amountininventory, amount)

	if toinsert == 0 then
		debug(p, string.format("put: nothing to insert: %d", state))
		return true
	end
	if not otherinv then
		--debug(p, string.format("put: no slot: %d", state))
		return false
	end

	local inserted = otherinv.insert{name=item, count=toinsert}
	--if we already failed for trying to insert no items, then if no items were inserted, it must be because it is full
	if inserted == 0 then
		debug(p, string.format("put: nothing inserted: %d", state))
		return true
	end

	p.remove_item{name=item, count=inserted}
	return true
end

local function recipe(p, position, recipe)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("recipe: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("recipe entity not reachable: %d", state))
		return false
	end
	if recipe == "none" then
		recipe = nil
	end
	local items = p.selected.set_recipe(recipe)
	if items then
		for name, count in pairs(items) do
			p.insert{name=name, count=count}
		end
	end
	return true
end

local function rotate(p, position, direction)
	local opts = {reverse = false}
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("rotate: entity not selected: %d", state))
		return false
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("rotate: entity not reachable: %d", state))
	 	return false
	end
	if direction == "ccw" then
		opts = {reverse = true}
	end
	p.selected.rotate(opts)
	if direction == "180" then
		p.selected.rotate(opts)
	end
	return true
end

local function speed(speed)
	game.speed = speed
	return true
end

local function take(p, position, item, amount, slot)
	p.update_selected_entity(position)

	if not p.selected then
		--debug(p, string.format("take: entity not selected: %d", state))
		return false
	end

	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		--debug(p, string.format("take: entity not reachable: %d", state))
		return false
	end

	local otherinv = p.selected.get_inventory(slot)

	if not otherinv then
		--debug(p, string.format("take: no slot: %d", state))
		return false
	end

	local totake = amount
	local amountintarget = otherinv.get_item_count(item)
	if totake == -1 then totake = amountintarget
	else totake = math.min(amountintarget, amount)
	end

	if amountintarget == 0 then
		debug(p, string.format("take: nothing to take: %d", state))
		return true
	end

	local taken = p.insert{name=item, count=totake}

	if taken == 0 then
		debug(p, string.format("take: nothing taken: %d", state))
		return true
	end

	otherinv.remove{name=item, count=taken}
	return true
end

local function tech(p, research)
	p.force.research_queue_enabled = true
	p.force.add_research(research)
	return true
end

local function transfer(p, position, numslots, slot)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("transfer: entity not selected: %d", state))
		return false
	end

	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("transfer: entity not reachable: %d", state))
		return false
	end

	local src = p.get_inventory(defines.inventory.character_main)
	local dst = p.selected.get_inventory(slot)
	local i = 1
	while i <= numslots do
		local src_stack = src[i]
		local dst_stack = dst[i]
		if dst_stack.can_set_stack(src_stack) then
			dst_stack.set_stack(src_stack)
			src_stack.clear()
		else
			return true
		end
		i = i + 1
	end
	return true
end

local function clsobj(p)
	p.gui.left.children[1].visible = false
	return true
end

local function drop(p, position, item)
	local canplace = p.can_place_entity{name = item, position = position}
	if canplace then
		p.surface.create_entity{name = "item-on-ground",
								stack = {
									name = item,
									count = 1,
								},
								position = position,
								force = "player",
								spill = true
								}
	end
	return true
end

local function blueprint(p, topleft, bottomright, position, direction)
	p.cursor_stack.set_stack('blueprint')
	p.cursor_stack.create_blueprint{area = {topleft, bottomright},
	                                surface=p.surface, force=p.force}
	p.cursor_stack.build_blueprint{surface=p.surface, force=p.force, position=position, direction=direction}
	p.cursor_stack.clear()
	return true
end

local function walk(delta_x, delta_y)
	if delta_x > 0.2 then
		-- Easterly
		if delta_y > 0.2 then
			return {walking = true, direction = defines.direction.southeast}
		elseif delta_y < -0.2 then
			return {walking = true, direction = defines.direction.northeast}
		else
			return {walking = true, direction = defines.direction.east}
		end
	elseif delta_x < -0.2 then
		-- Westerly
		if delta_y > 0.2 then
			return {walking = true, direction = defines.direction.southwest}
		elseif delta_y < -0.2 then
			return {walking = true, direction = defines.direction.northwest}
		else
			return {walking = true, direction = defines.direction.west}
		end
	else
		-- Vertically
		if delta_y > 0.2 then
			return {walking = true, direction = defines.direction.south}
		elseif delta_y < -0.2 then
			return {walking = true, direction = defines.direction.north}
		else
			return {walking = false, direction = defines.direction.north}
		end
	end
end

local function doTask(p, task)
	if task[1] == "build" then
		return build(p, task[2], task[3], task[4])
	elseif task[1] == "craft" then
		return craft(p, task[2], task[3])
	elseif task[1] == "filter" then
		return filter(p, task[2], task[3], task[4])
	elseif task[1] == "idle" then
		idle = task[2]
		return true
	elseif task[1] == "launch" then
		return launch(p, task[2])
	elseif task[1] == "limit" then
		return limit(p, task[2], task[3], task[4])
	elseif task[1] == "move" then
		destination = {x = task[2][1], y = task[2][2]}
		return true
	elseif task[1] == "pick" then
		pick = task[2]
		return true
	elseif task[1] == "priority" then
		return priority(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "put" then
		return put(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "recipe" then
		return recipe(p, task[2], task[3])
	elseif task[1] == "rotate" then
		return rotate(p, task[2], task[3])
	elseif task[1] == "speed" then
		return speed(task[2])
	elseif task[1] == "take" then
		return take(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "tech" then
		return tech(p, task[2])
	elseif task[1] == "transfer" then
		return transfer(p, task[2], task[3], task[4])
	elseif task[1] == "blueprint" then
		return blueprint(p, task[2], task[3], task[4], task[5], task[6]) 
	elseif task[1] == "clsobj" then
		return clsobj(p)
	elseif task[1] == "drop" then
		dropping = task[2]
	end
end

local function printGui(p, ge, depth)
	for k, v in pairs(ge.children) do
		debug(p, string.format("%s%s %s", depth, k, v.type))
		printGui(p, v, string.format("%s  ", depth))
	end
end

script.on_event(defines.events.on_game_created_from_scenario, function()
	-- Skips the freeplay intro
	remote.call("freeplay", "set_skip_intro", true)
end)

script.on_event(defines.events.on_tick, function(event)
	local p = game.players[1]
	local pos = p.position
	local g = p.gui

	if task[state] == nil or task[state][1] == "break" then
		debug(p, string.format("(%.2f, %.2f) Complete after %f seconds (%d ticks)", pos.x, pos.y, p.online_time / 60, p.online_time))		
		dbg = 0
		return
	else
		debug(p, string.format("(%.2f, %.2f, %d) %d %s", pos.x, pos.y, event.tick, state, task[state][1]))
		--if state == 1 then			
		--	printGui(p, g, "")
			-- In the introduction I need to click the initial "Continue" button to progress.
			--script.raise_event(defines.events.on_gui_click,{
			--	element=g.center.children[1].children[2].children[2],
			--	player_index=1,
			--	button=defines.mouse_button_type.left,
			--	alt=false,
			--	control=false,
			--	shift=false})			
		--end
		--state = state
	end
	dupevent = 0

	local walking = walk(destination.x - pos.x, destination.y - pos.y)
		
	if walking.walking == false then
		if idle > 0 then
			idle = idle - 1
		elseif pick > 0 then
			pick = pick - 1
			p.picking_state = true
			debug(p, string.format("picking %d", pick))
		elseif dropping > 0 then
			dropping = dropping - 1
			debug(p, string.format("%d", dropping))
			drop(p, task[state][3], task[state][4])
		elseif task[state][1] == "walk" or task[state][1] == "shortcut" then
			destination = {x = task[state][2][1], y = task[state][2][2]}
			walking = walk(destination.x - pos.x, destination.y - pos.y)
			state = state + 1
		elseif task[state][1] == "mine" then
			--XETX Replace this
			p.update_selected_entity(task[state][2])
			p.mining_state = {mining = true, position = task[state][2]}
			--XETX With this
			--if mining_done == 1 then
			--	mining_done = 0
			--	state = state + 1
			--	-- Do I lose a tick here?
			--else
			--	p.update_selected_entity(task[state][2])
			--	p.mining_state = {mining = true, position = task[state][2]}
			--	mining_done = 0
			--end
			--XETX For better mining handling (fixes fast-replace weirdness)
		elseif doTask(p, task[state]) then
			-- Do task while standing still
			state = state + 1
		end
	else
		if task[state][1] == "shortcut" then
			destination = {x = task[state][2][1], y = task[state][2][2]}
			walking = walk(destination.x - pos.x, destination.y - pos.y)
			state = state + 1
		elseif task[state][1] ~= "walk" and task[state][1] ~= "mine" and task[state][1] ~= "idle" and task[state][1] ~= "pick" then
			if doTask(p, task[state]) then
				-- Do task while walking
				state = state + 1
			end
		end
	end
	p.walking_state = walking
end)

script.on_event(defines.events.on_player_mined_entity, function(event)
	--XETX Replace this
	state = state + 1
	--XETX With this
	--if task[state][1] == "mine" then
	--	mining_done = 1
	--end
	--XETX For better mining handling (fixes fast-replace weirdness)
	
	--local p = game.players[1]
	--local d = event.buffer.get_contents()
	--debug(p, string.format("%d,%d,%d", event.tick,d["coal"], d["stone"]))
end)

--script.on_event(defines.events.on_player_mined_item, function(event)
--	if dupevent ~= 1 and task[state] ~= nil and task[state][1] ~= "break" then
--		state = state + 1
--		-- When mining/picking up something with multiple items, this event
--		-- is triggered for each item. But we only want to update state once
--		-- so we use dupevent to regulate that.
--		dupevent = 1
--	end
--	local p = game.players[1]
--	debug(p, string.format("mined_item on %d", event.tick))
--end)