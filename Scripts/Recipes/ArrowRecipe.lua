include("Scripts/Core/Common.lua")
include("Scripts/Recipes/Recipe.lua")
include("Scripts/Recipes/DefaultRecipe.lua")

-------------------------------------------------------------------------------
ArrowRecipe = DefaultRecipe.Subclass("ArrowRecipe")

-------------------------------------------------------------------------------
-- Spawn a result item by name in the appropriate position and state
function ArrowRecipe:SpawnResultItem( craftAction, objName, spawnpos )
	local obj = Eternus.GameObjectSystem:NKCreateNetworkedGameObject( objName, true, false)
	if obj then
		obj:NKSetPosition(spawnpos, false)
		obj:NKSetAbsoluteScale(1.0, false)

		obj:NKGetNet():NKReference(true)

		if obj:NKGetPlaceable() then
			if obj:NKGetPlaceable():NKIsResource() then
				obj:NKPlaceInWorld(false, false)
				obj:NKGetPhysics():NKActivate()
			else
				local rot = quat.new(0.0,0.0,1.0,0.0)
				if craftAction.station then
					rot  = craftAction.stationObj:NKGetOrientation()
				end
				obj:NKSetOrientation(rot)
				--obj:NKCalculateCellID()
				obj:NKPlaceInWorld(true, false)
                obj:NKModifyStackCount( self.m_results["Arrow"] )
			end
			
			obj:NKGetInstance():OnCraftComplete()
		else
			-- No placeable, character time
			local rot = quat.new(0.0,0.0,1.0,0.0)
			if craftAction.station then
				rot  = craftAction.stationObj:NKGetOrientation()
			end
			obj:NKSetOrientation(rot)
			--obj:NKCalculateCellID() -- Characters don't get saved
			obj:NKPlaceInWorld(false, false, false)
            obj:NKModifyStackCount( self.m_results["Arrow"] )
		end
	end

	return obj
end

if Eternus.IsServer then
	-------------------------------------------------------------------------------
	-- End a craft action with the provided player
	function ArrowRecipe:EndCrafting( craftAction, player )
		if not self:IsCraftActionStillValid( craftAction, player ) then
			return false
		end

		local placementPos = player:GetCurrentCraftingLocation() + vec3.new(0.0, 1.0, 0.0)
		local spawnPlacementPos = vec3.new(0.0, 1.0, 0.0)

		-- Remove objects that are part of the recipe
	    for key, value in pairs( craftAction.removals ) do
	    	key:NKGetInstance():ModifyStackSize(-value.stackCount)

	    	if not craftAction.station then
	    		placementPos = key:NKGetPosition() + vec3.new(0.0, 1.0, 0.0)
	    	end
	    end

		-- Do durability damage to unconsumed objects that are part
		-- of the recipie
	    for key,value in pairs( craftAction.durabilityHits ) do
	    	key:NKGetInstance():ModifyHitPoints(-self.m_unconsumedDamage)
	    end

		-- If there's a station involved, get the spawn location and offsets from it.
		local failChance = 0.0
		if craftAction.station then
			failChance = craftAction.stationObj:NKGetInstance().FailChance
			
			if craftAction.station.offsetOverride ~= nil then
				placementPos = craftAction.stationObj:NKGetPosition() + craftAction.station.offsetOverride
			else
				local attachPoint = craftAction.stationObj:NKGetAttachPoint("craft")
				placementPos = attachPoint.m_position:mul_quat(craftAction.stationObj:NKGetWorldOrientation()) + craftAction.stationObj:NKGetWorldPosition()
			end
				
			if craftAction.station.spawnOffsetOverride ~= nil then
				spawnPlacementPos = craftAction.station.spawnOffsetOverride
			end
	    end

   		Eternus.PhysicsWorld:NKResetWorldHitObject()

	    if craftAction.energyCost ~= 0.0 then
			player:_ModifyEnergy(-craftAction.energyCost)
			player:RaiseClientEvent("ClientEvent_PlayObjectSound", { soundName = "SeedlingNeuriaLoss", loop = false, offset = vec3.new(0.0, 0.0, 0.0), minDist = 15.0, maxDist = 135.0 })
		end

   		for key, value in pairs(self.m_results) do
			-- Spawn all the resulting items
            -- Nuked this loop so it spawns the object once.
            -- We then copy it to a new object with spawn
			--for i = 1, value, 1 do
				local obj = self:SpawnResultItem( craftAction, key, placementPos )
				if obj then
					placementPos = placementPos + spawnPlacementPos -- vec3.new(0.0, 2.0, 0.0)
					-- For data metric system
                    -- Use Item spawn command instead of other, to get an item spawned with stack size.. lol
                    player:SpawnCommand(obj:NKGetName(), self.m_results["Arrow"], placementPos)
					player:OnSuccessfulCraft( obj )
                    -- Delete old one after
                    obj:NKDeleteMe()
				end
			--end
		end

		-- If we have failed results and the fail chance is not 0...
		if self.m_failedResults and failChance > 0.0 then
		
			-- Roll the dice to see if we have a mistake.
			local randVal = Eternus.Random:NKGetDouble(0.0, 1.0)
			if (randVal <= failChance) then --Generate the mistake
				for key,value in pairs(self.m_failedResults) do
					-- Always offset the mistake
					local obj = self:SpawnResultItem( craftAction, key, placementPos + vec3.new(0.0, 1.0, 0.0) )
					if obj then
						placementPos = placementPos + spawnPlacementPos 
						-- For data metric system
                        -- Use Item spawn command instead of other, to get an item spawned with stack size.. lol
                        player:SpawnCommand(obj:NKGetName(), self.m_results["Arrow"], placementPos)
						player:OnFailureCraft( obj )
                        -- Delete old one after
                        obj:NKDeleteMe()
					end
				end
			end
		end

		if craftAction.station ~= nil then
	    	craftAction.stationObj:NKGetInstance():RaiseEvent("Event_CraftingEnd")
	    end

		return true
    end
end

return ArrowRecipe
