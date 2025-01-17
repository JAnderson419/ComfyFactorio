-- Biters and Spitters gain additional health / resistance -- mewmew
-- Use global.biter_health_boost to modify their health.
-- 1 = vanilla health, 2 = 200% vanilla health
-- do not use values below 1

local function clean_table()
	local units_to_delete = {}
	
	--Mark all health boost entries for deletion
	for key, health in pairs(global.biter_health_boost_units) do
		units_to_delete[key] = true
	end
	
	--Remove valid health boost entries from deletion
	for _, surface in pairs(game.surfaces) do
		for _, unit in pairs(surface.find_entities_filtered({type = "unit"})) do
			units_to_delete[unit.unit_number] = nil
		end
	end
	
	--Remove abandoned health boost entries
	for key, _ in pairs(units_to_delete) do
		global.biter_health_boost_units[key] = nil
	end
end

local function on_entity_damaged(event)
	if not event.entity.valid then return end
	if event.entity.force.index ~= 2 then return end
	if event.entity.type ~= "unit" then return end

	--Create new health pool
	if not global.biter_health_boost_units[event.entity.unit_number] then
		global.biter_health_boost_units[event.entity.unit_number] = {
			math.floor(event.entity.prototype.max_health * global.biter_health_boost),
			math.round(1 / global.biter_health_boost, 5),
		}
		
		--Perform a table cleanup every 5000 boosts
		global.biter_health_boost_count = global.biter_health_boost_count + 1
		if global.biter_health_boost_count % 5000 == 0 then clean_table() end
	end
	
	--Reduce health pool
	global.biter_health_boost_units[event.entity.unit_number][1] = global.biter_health_boost_units[event.entity.unit_number][1] - event.final_damage_amount
	
	--Set entity health relative to health pool
	event.entity.health = global.biter_health_boost_units[event.entity.unit_number][1] * global.biter_health_boost_units[event.entity.unit_number][2]
	
	--Proceed to kill entity if health is 0
	if event.entity.health > 0 then return end
		
	--Remove health pool
	global.biter_health_boost_units[event.entity.unit_number] = nil
	
	if event.cause then
		if event.cause.valid then
			event.entity.die(event.cause.force, event.cause)
			return
		end
	end
	event.entity.die(event.entity.force)
end

local function on_init()
	global.biter_health_boost = 1
	global.biter_health_boost_units = {}
	global.biter_health_boost_count = 0
end

local event = require 'utils.event'
event.on_init(on_init)
event.add(defines.events.on_entity_damaged, on_entity_damaged)