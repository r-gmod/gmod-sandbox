TOOL.Category = "Render"
TOOL.Name = "#tool.shadow.name"
TOOL.Command = nil
TOOL.ConfigName = nil

if CLIENT then
	language.Add("tool.shadow.name", "Toggle Shadow")
	language.Add("tool.shadow.desc", "Toggle the render-to-texture shadow of the entity you're looking at.")
	language.Add("tool.shadow.0", "Left click to disable a shadow, right click to enable one. Reload to disable shadows of constrained objects.")

end

local function SetShadow(Player, Entity, Data)
	if not SERVER then return end
	if Data.Shadow != nil then
		if Entity:IsValid() then Entity:DrawShadow(Data.Shadow) end
	end
	duplicator.StoreEntityModifier(Entity, "shadow", Data)
end
duplicator.RegisterEntityModifier("shadow", SetShadow)

function TOOL:LeftClick(trace)
	if trace.Entity:IsValid() then
		SetShadow(self:GetOwner(), trace.Entity, {Shadow = false})
		return true
	end
end

function TOOL:RightClick(trace)
	if trace.Entity:IsValid() then
		SetShadow(self:GetOwner(), trace.Entity, {Shadow = true})
		return true
	end
end

function TOOL:Reload(trace)
	if trace.Entity:IsValid() then
		local CE = constraint.GetAllConstrainedEntities(trace.Entity)
		for _, ent in pairs(CE) do
			SetShadow(self:GetOwner(), ent, {Shadow = false})
		end
		return true
	end
end
