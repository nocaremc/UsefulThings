-- UsefullThings

include("Scripts/Core/Common.lua")

-------------------------------------------------------------------------------
if UsefullThings == nil then
	UsefullThings = EternusEngine.ModScriptClass.Subclass("UsefullThings")
end

-------------------------------------------------------------------------------
function UsefullThings:Constructor(  )

end

 -------------------------------------------------------------------------------
 -- Called once from C++ at engine initialization time
function UsefullThings:Initialize()
    Eternus.CraftingSystem:ParseRecipeFile("Data/Crafting/recipes.txt")
end

-------------------------------------------------------------------------------
-- Called from C++ when the current game enters 
function UsefullThings:Enter()
end

-------------------------------------------------------------------------------
-- Called from C++ when the game leaves it current mode
function UsefullThings:Leave()
end

-------------------------------------------------------------------------------
-- Called from C++ every update tick
function UsefullThings:Process(dt)
end

function UsefullThings:TestCommandFunction(args)
end

EntityFramework:RegisterModScript(UsefullThings)