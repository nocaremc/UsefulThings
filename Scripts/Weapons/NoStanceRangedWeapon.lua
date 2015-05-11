include("Scripts/Core/Common.lua")
include("Scripts/Objects/Equipable.lua")
include("Scripts/Objects/Weapons/RangedWeapon.lua")
-------------------------------------------------------------------------------
NoStanceRangedWeapon = RangedWeapon.Subclass("NoStanceRangedWeapon")

NoStanceRangedWeapon.ForceModifier = 1
NoStanceRangedWeapon.DamageModifier = 1
-- Mixins

NKRegisterEvent("ServerEvent_Aim",
	{
		player = "gameobject"
	}
)

NKRegisterEvent("ServerEvent_Shoot",
	{
	}
)

NKRegisterEvent("ClientEvent_TransitionStance",
	{
		transitionID = "int"
	}
)

-------------------------------------------------------------------------------
function NoStanceRangedWeapon:ClientEvent_TransitionStance(args)
    return
end
function NoStanceRangedWeapon:PrimaryAction(args)

	-- Check that we aren't in stance. Easy shortcut :P
	if not args.player:InSlingshotHoldingStance() then
		local ammoObj = nil
		local ammoSlot = nil
		for i=1,4 do
			local beltObj = args.player.m_inventoryContainers[2]:GetItemAt(i)
			if (beltObj ~= nil and beltObj.m_item) then
				local ammoInstance = beltObj.m_item:NKGetInstance()
				if (ammoInstance and ammoInstance.m_ammoType == self.m_ammoUsed) then
					ammoObj = ammoInstance
					ammoSlot = i
				end
			end
		end
		
		-- make sure ammo was found
		-- ### TODO ### add weapons that don't use ammo
		if (ammoObj == nil) then
			-- add return to default state here!
			return false -- couldn't find any usable ammo, return false to cancel the default action
		end
		
		local offset = vec3.new(0, 0, 0.9)
		local facingRot = GLM.Angle(args.direction * vec3.new(1, 0, 1), NKMath.Right)
		local temp = offset:mul_quat(facingRot) 
		
	
		local projectile = ammoObj:CreateProjectile()
		local projectileData = ammoObj:GetProjectileData()
		
		projectile:NKSetPosition(args.positionW + temp)
		projectile:NKSetOrientation(GLM.Angle(args.direction, NKMath.Right))

		projectile:NKPlaceInWorld(false, false)
		projectile:NKSetShouldRender(true, true)
		local throwablePayload = 
		{
			damage = projectileData.m_damage * self.m_damageModfier,
			strikeThreshold = projectileData.m_strikeThreshold,
			source = args.player,
		}
		projectile:Fire(throwablePayload, args.direction, projectileData.m_force * self.m_forceModfier)
		
		ammoObj:RemoveAfterThrow(args.player)
		
		-- take durability damage (for self and ammo)
		self:ModifyHitPoints(-ammoObj.m_correctDurabilityDamage-self.m_correctDurabilityDamage)
		
		return
	end
	
	if not args.targetObj then
		self:AffectMaterial(args)
		return
	end

	-- Can this tool break the object?
	if self:CanToolAffectObject(args.targetObj) then
		-- If our hand item broke, remove it from our hand
		if self:AffectObject(args) then
			args.player:RemoveHandItem(-1)
		end
	end

end

-------------------------------------------------------------------------------
EntityFramework:RegisterGameObject(NoStanceRangedWeapon)