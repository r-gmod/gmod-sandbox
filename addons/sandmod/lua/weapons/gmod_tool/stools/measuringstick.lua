TOOL.Category		= "Construction"
TOOL.Name			= "#tool.measuringstick.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "unit" ] = "u"

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then
	language.Add( "tool.measuringstick.name", "Measuring Stick" )
	language.Add( "tool.measuringstick.desc", "Measure the distance between two points" )
	language.Add( "tool.measuringstick.0", "Left-Click: Select first point. Right-Click: Measure from object to world." )
	language.Add( "tool.measuringstick.1", "Click on the second point." )
end

-- totally stole this from wiremod :'>
local lengths = {
	["u"]   = 1 / 0.75,
	["mm"]  = 25.4,
	["cm"]  = 2.54,
	["dm"]  = 0.254,
	["m"]   = 0.0254,
	["km"]  = 0.0000254,
	["in"]  = 1,
	["ft"]  = 1 / 12,
	["yd"]  = 1 / 36,
	["mi"]  = 1 / 63360,
	["nmi"] = 127 / 9260000
}

local lenstring = {
	["u"]   = "units",
	["mm"]  = "millimeters",
	["cm"]  = "centimeters",
	["dm"]  = "decimeters",
	["m"]   = "meters",
	["km"]  = "kilometers",
	["in"]  = "inches",
	["ft"]  = "feet",
	["yd"]  = "yards",
	["mi"]  = "miles",
	["nmi"] = "nautical miles"
}

function TOOL:LeftClick( trace )
	if ( trace.Entity:IsValid() and trace.Entity:IsPlayer() ) then return end
	if CLIENT then return true end
	
	local iNum = self:NumObjects()
	
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, nil, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 0 ) then
		local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
		local length = ( WPos1 - WPos2):Length()
		
		// Clear the objects so we're ready to go again
		self:ClearObjects()

		local unit = self:GetClientInfo("unit")
		if lengths[unit] then
			length = length * 0.75 * lengths[unit]
		end
		
		message = string.format("Distance: %.3f %s", length, lenstring[unit])

		local ply = self:GetOwner()
		
		ply:PrintMessage(3, message)
		
	else
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:RightClick( trace )
	if CLIENT then return true end
	
	local iNum = self:NumObjects()

	self:SetObject( 1, trace.Entity, trace.HitPos, nil, trace.PhysicsBone, trace.HitNormal )

	local tr = {}
	tr.start = trace.HitPos
	tr.endpos = tr.start + (trace.HitNormal * 16384)
	tr.filter = {}
	tr.filter[1] = self:GetOwner()
	if (trace.Entity:IsValid()) then
		tr.filter[2] = trace.Entity
	end
	
	local tr = util.TraceLine( tr )
		
	if ( !tr.Hit ) then
		self:ClearObjects()
		return
	end
	
	self:SetObject( 2, tr.Entity, tr.HitPos, nil, tr.PhysicsBone, tr.HitNormal )
	
	local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
	local Ent1, Ent2 = self:GetEnt(1),	 self:GetEnt(2)
	local length = ( WPos1 - WPos2):Length()

	// Clear the objects so we're ready to go again
	self:ClearObjects()

	local unit = self:GetClientInfo("unit")
	if lengths[unit] then
		length = length * 0.75 * lengths[unit]
	end

	message = string.format("Distance from %s to %s: %.3f %s", Ent1:GetClass(), Ent2:GetClass(), length, lenstring[unit])
	local ply = self:GetOwner()
	ply:PrintMessage(3, message)
	
	// Clear the objects so we're ready to go again
	self:ClearObjects()
	
	return true
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl( "Header", { Text = "#tool.measuringstick.name", Description	= "#tool.measuringstick.desc" }  )
	CPanel:AddControl( "ComboBox", {
		Label = "Units",
		MenuButton = 0,
		Options = {
				["source units"] = { measuringstick_unit = "u" },
				["millimeters"] = { measuringstick_unit = "mm" },
				["centimeters"] = { measuringstick_unit = "cm" },
				["decimeters"] = { measuringstick_unit = "dm" },
				["meters"] = { measuringstick_unit = "m" },
				["kilometers"] = { measuringstick_unit = "km" },
				["inches"] = { measuringstick_unit = "in" },
				["feet"] = { measuringstick_unit = "ft" },
				["yards"] = { measuringstick_unit = "yd" },
				["miles"] = { measuringstick_unit = "mi" },
				["nautical miles"] = { measuringstick_unit = "nmi" }
			}
	})
end

local function OverrideCanTool(pl, rt, toolmode)
	-- We don't want any addons denying use of this tool. Even when using
	-- PropDefender, people should be able to use this tool on other people's
	-- stuff.
	if toolmode == "measuringstick" then
		return true
	end
end
hook.Add( "CanTool", "measuringstick_CanTool", OverrideCanTool );