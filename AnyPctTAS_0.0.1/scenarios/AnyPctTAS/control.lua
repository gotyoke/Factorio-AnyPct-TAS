-- See https://github.com/yournamehere/factorio-tas-playback
--local cmd = require("commands")
require ("util")
local silo_script = require("silo-script")
local task = require("tasks")
local state = 1
local dupevent = 0
local destination = {x = 0, y = 0}
local refx = 0
local refy = 0
local ticks = 0
local pick = 0
local dbg = 0

local function debug(p, msg)
	if dbg > 0 then
		p.print(msg)
	end
end

local function speed(speed)
	game.speed = speed
end

local function tech(p, research)
  p.force.current_research = research
end

local function build(p, item, position, direction)
	-- Check if we have the item
	if p.get_item_count(item) == 0 then
		debug(p, string.format("build: not enough items: %d", state))
		return
	end

	-- Grenade special stuff
	if item == "grenade" then
		p.update_selected_entity(position)
		if not p.selected then
			return
		end
		p.surface.create_entity{name = item, position = p.position, target=p.selected, force="player", speed=0.35}
		p.remove_item({name = item, count = 1})
		return
	end

	-- Check if we can actually place the item at this tile
	local canplace = p.can_place_entity{name = item, position = position, direction = direction}
	local asm = false

	if canplace then
		canplace = p.surface.can_fast_replace{name = item, position = position, direction = direction, force = "player"}
		if canplace then
			asm = p.surface.create_entity{name = item, position = position, direction = direction, force="player", fast_replace=true, player=p}
			if asm then
				--For some weird unknown reason, when using the fast_replace=true version,
				--the state variable gets advanced an extra step. So I gotta do this to
				--to keep things in sync     ¯\_(ツ)_/¯
				--Hey also, can_fast_replace does not do distance checking, so it could be
				--cheaty here if I were dishonest.
				state = state - 1
			end
		else
			asm = p.surface.create_entity{name = item, position = position, direction = direction, force="player"}
		end
	else
		debug(p, string.format("build: cannot place: %d", state))
	end
	if asm then
		p.remove_item({name = item, count = 1})
	end
end

local function transfer(p, position, numslots, slot)
	p.update_selected_entity(position)

	if not p.selected then
		debug(p, string.format("transfer: entity not selected: %d", state))
		return
	end

	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("transfer: entity not reachable: %d", state))
		return
	end

	local src = p.get_inventory(defines.inventory.player_main)
	local dst = p.selected.get_inventory(slot)
	local i = 1
	while i <= numslots do
		local src_stack = src[i]
		local dst_stack = dst[i]
		if dst_stack.can_set_stack(src_stack) then
			dst_stack.set_stack(src_stack)
			src_stack.clear()
		else
			return
		end
		i = i + 1
	end
end

local function put(p, position, item, amount, slot)
	p.update_selected_entity(position)

	if not p.selected then
		debug(p, string.format("put: entity not selected: %d", state))
		return
	end

 	if not p.can_reach_entity(p.selected) then
 		debug(p, string.format("put: entity not reachable: %d", state))
 		return
 	end

	local amountininventory = p.get_item_count(item)
	local otherinv = p.selected.get_inventory(slot)
	local toinsert = math.min(amountininventory, amount)

	if toinsert == 0 then
		debug(p, string.format("put: nothing to insert: %d", state))
		return
	end
	if not otherinv then
		debug(p, string.format("put: no slot: %d", state))
		return
	end

	local inserted = otherinv.insert{name=item, count=toinsert}

	--if we already failed for trying to insert no items, then if no items were inserted, it must be because it is full
	if inserted == 0 then
		debug(p, string.format("put: nothing inserted: %d", state))
		return
	end

	p.remove_item{name=item, count=inserted}
end

local function take(p, position, item, amount, slot)
	p.update_selected_entity(position)

	if not p.selected then
		debug(p, string.format("take: entity not selected: %d", state))
		return
	end

	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("take: entity not reachable: %d", state))
		return
	end

	local otherinv = p.selected.get_inventory(slot)

	if not otherinv then
		debug(p, string.format("take: no slot: %d", state))
		return
	end

	local totake = amount
	local amountintarget = otherinv.get_item_count(item)
	if totake == -1 then totake = amountintarget
	else totake = math.min(amountintarget, amount)
	end

	if amountintarget == 0 then
		debug(p, string.format("take: nothing to take: %d", state))
		return
	end

	local taken = p.insert{name=item, count=totake}

	if taken == 0 then
		debug(p, string.format("take: nothing taken: %d", state))
		return
	end

	otherinv.remove{name=item, count=taken}
end

local function limit(p, position, limit, slot)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("limit: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("limit: entity not reachable: %d", state))
	  return
	end

	local otherinv = p.selected.get_inventory(slot)

	if not otherinv then
		debug(p, string.format("limit: no slot: %d", state))
		return
	end

	if not otherinv.hasbar() then
		debug(p, string.format("limit: entity has no bar: %d", state))
		return
	end

	-- Setting setbar to 1 completely limits all slots, so it's off by one
	otherinv.setbar(limit+1)
end

local function craft(p, count, recipe)
	amt = p.begin_crafting{recipe = recipe, count = count}
end

local function walk(delta_x, delta_y)
	if delta_x > 0.5 then
		-- Easterly
		if delta_y > 0.5 then
			return {walking = true, direction = defines.direction.southeast}
		elseif delta_y < -0.5 then
			return {walking = true, direction = defines.direction.northeast}
		else
			return {walking = true, direction = defines.direction.east}
		end
	elseif delta_x < -0.5 then
		-- Westerly
		if delta_y > 0.5 then
			return {walking = true, direction = defines.direction.southwest}
		elseif delta_y < -0.5 then
			return {walking = true, direction = defines.direction.northwest}
		else
			return {walking = true, direction = defines.direction.west}
		end
	else
		-- Vertically
		if delta_y > 0.5 then
			return {walking = true, direction = defines.direction.south}
		elseif delta_y < -0.5 then
			return {walking = true, direction = defines.direction.north}
		else
			return nil
		end
	end
end

local function recipe(p, position, recipe)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("recipe: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("recipe entity not reachable: %d", state))
		return
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
end

local function priority(p, position, input, output, filter)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("priority: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("priority: entity not reachable: %d", state))
	    return
	end
	p.selected.splitter_input_priority = input
	p.selected.splitter_output_priority = output
	if filter == "none" then
		p.selected.splitter_filter = nil
	else
		p.selected.splitter_filter = filter
	end
end

local function filter(p, position, slot, filter)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("filter: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("filter: entity not reachable: %d", state))
	 	return
	end
	p.selected.set_filter(slot, filter)	
end

local function rotate(p, position, direction)
	local opts = {reverse = false}
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("rotate: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("rotate: entity not reachable: %d", state))
	 	return
	end
	if direction == "ccw" then
		opts = {reverse = true}
	end
	p.selected.rotate(opts)
end

local function launch(p, position)
	p.update_selected_entity(position)
	if not p.selected then
		debug(p, string.format("launch: entity not selected: %d", state))
		return
	end
	-- Check if we are in reach of this tile
	if not p.can_reach_entity(p.selected) then
		debug(p, string.format("launch: entity not reachable: %d", state))
		return
	end
	p.selected.launch_rocket()
end

local function doTask(p, task)
	if task[1] == "build" then
		build(p, task[2], task[3], task[4])
	elseif task[1] == "put" then
		put(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "craft" then
		craft(p, task[2], task[3])
	elseif task[1] == "take" then
		take(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "limit" then
		limit(p, task[2], task[3], task[4])
	elseif task[1] == "priority" then
		priority(p, task[2], task[3], task[4], task[5])
	elseif task[1] == "filter" then
		filter(p, task[2], task[3], task[4])
	elseif task[1] == "recipe" then
		recipe(p, task[2], task[3])
	elseif task[1] == "refxy" then
		refxy(task[2], task[3])
	elseif task[1] == "ticks" then
		ticks = task[2]
	elseif task[1] == "pick" then
		pick = task[2]
	elseif task[1] == "speed" then
		speed(task[2])
	elseif task[1] == "tech" then
		tech(p, task[2])
	elseif task[1] == "move" then
		destination = {x = task[2][1], y = task[2][2]}
	elseif task[1] == "rotate" then
		rotate(p, task[2], task[3])
	elseif task[1] == "transfer" then
		transfer(p, task[2], task[3], task[4])
	elseif task[1] == "launch" then
		launch(p, task[2])
	end
end


-- In each tick you can have the walking_state or the mining_state set to true.
-- In addition, each tick you can issue one action
--   craft: player.begin_crafting
--   put: player.remove_item and player.selected.insert
--   take: player.insert and player.selected.remove
--   build: player.surface.create_entity and player.remove_item
--   tech: player.force.current_research
--   recipe (sets assembler recipe)
script.on_event(defines.events.on_tick, function()
	local p = game.players[1]
	local pos = p.position

	if task[state] == nil or task[state][1] == "break" then
	--	p.print(string.format("(%.2f, %.2f)", pos.x, pos.y))
		return
	else
		debug(string.format("(%.2f, %.2f) %d", pos.x, pos.y, state))
	    --p.print(string.format("%d %d", game.tick, state))
	end

	dupevent = 0
	local walking = walk(destination.x - pos.x, destination.y - pos.y)
	if walking then
		p.walking_state = walking
		if task[state][1] ~= "walk" and task[state][1] ~= "mine" and task[state][1] ~= "ticks" and task[state][1] ~= "pick" then
			-- Do task while walking
			doTask(p, task[state])
			state = state + 1
		end
	else
		if ticks > 0 then
			ticks = ticks - 1
		elseif pick > 0 then
			pick = pick - 1
			p.picking_state = true
		elseif task[state][1] == "walk" then
			destination = {x = task[state][2][1], y = task[state][2][2]}
			state = state + 1
		elseif task[state][1] == "mine" then
			p.update_selected_entity(task[state][2])
			p.mining_state = {mining = true, position = task[state][2]}
		else
			-- Do task while standing still
			doTask(p, task[state])
			state = state + 1
		end
	end
end)

script.on_event(defines.events.on_player_mined_item, function()
	if dupevent ~= 1 and task[state] ~= nil and task[state][1] ~= "break" then
		state = state + 1
		-- When mining/picking up something with multiple items, this event
		-- is triggered for each item. But we only want to update state once
		-- so we use dupevent to regulate that.
		dupevent = 1
	end
end)

-- Default Scenario settings
local silo_script = require("silo-script")
local version = 1

script.on_event(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  player.insert{name="iron-plate", count=8}
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
  player.insert{name="burner-mining-drill", count = 1}
  player.insert{name="stone-furnace", count = 1}
  player.force.chart(player.surface, {{player.position.x - 200, player.position.y - 200}, {player.position.x + 200, player.position.y + 200}})
  if (#game.players <= 1) then
    game.show_message_dialog{text = {"msg-intro"}}
  else
    player.print({"msg-intro"})
  end
  silo_script.on_player_created(event)
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  player.insert{name="pistol", count=1}
  player.insert{name="firearm-magazine", count=10}
end)

script.on_event(defines.events.on_gui_click, function(event)
  silo_script.on_gui_click(event)
end)

script.on_init(function()
  global.version = version
  silo_script.on_init()
end)

script.on_event(defines.events.on_rocket_launched, function(event)
  silo_script.on_rocket_launched(event)
end)

script.on_configuration_changed(function(event)
  if global.version ~= version then
    global.version = version
  end
  silo_script.on_configuration_changed(event)
end)

silo_script.add_remote_interface()
silo_script.add_commands()