
TOOL.Category		= "Constraints"
TOOL.Name			= "Physics Constraint"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar["forcelimit"] = "0"

if CLIENT then
	
	// Add our tooltips!
    language.Add("tool.physcons.name", TOOL.Name)
    language.Add("tool.physcons.desc", "Realistically weld multiple Props.")
    language.Add("tool.physcons.0", "Primary: Select a Prop. Secondary: Weld Selection. Reload: Clear Selection.")
	language.Add("Undone_physcons", "Undone Physics Constraint")
	
end


// Our TOOL specific variables.
TOOL.GoConstrain = 0
TOOL.PCEntLib = { }
TOOL.NextThink = 0

function TOOL:Think( )

	// If we don't think enough, we'll get confused (and slow down)!

	if CLIENT then return end
	if self.GoConstrain == 0 then return end
	if (CurTime() < self.NextThink) then return end
	local Count = 0
	for k, v in pairs(self.PCEntLib) do
		
		// 50 Props should be sufficent. We'll break the loop after 50 props and wait 66ms.
		if (Count >= 50) then self.NextThink = CurTime() + 0.066; return true end
		Count = Count + 1
		
		local Ent1 = v.Ent
		if (IsValid(Ent1)) then
			
			for k2, v2 in pairs(self.PCEntLib) do
			
				local Ent2 = v2.Ent
				if (!IsValid(Ent2)) then self.PCEntLib[k2] = nil
				elseif (Ent1 != Ent2) then
					
					// This was actually rather easy.
					local L1 = Ent1:NearestPoint(Ent2:LocalToWorld(Ent2:GetPhysicsObject():GetMassCenter()))
					local L2 = Ent2:NearestPoint(L1)
					
					// If we're close enough, we'll weld!
					if (L1:Distance(L2) < 4) then
						
						local constraint = constraint.Weld(Ent1, Ent2, v.Bone, v2.Bone, self:GetClientNumber("forcelimit", 0), true)
						undo.AddEntity(constraint)
						
					end
					
				end
				
			end
				
			// We're finished with this prop, de-select and remove.
			Ent1:SetColor(v.Colour.r, v.Colour.g, v.Colour.b, v.Colour.a)
			Ent1:SetMaterial(v.Mat)
			self.PCEntLib[k] = nil
				
		else self.PCEntLib[k] = nil
			
		end
			
	end
	undo.SetPlayer(self:GetOwner())
	undo.SetCustomUndoText("Undone Physics Constraint")
	undo.Finish()
	self.PCEntLib = { }
	self.GoConstrain = 0
	
end

function TOOL:LeftClick( trace )

	// Fail Safes

	if CLIENT then return true end
	if (IsValid(trace.Entity)) and (trace.Entity:IsPlayer()) then return end
	if (SERVER && !util.IsValidPhysicsObject(trace.Entity, trace.PhysicsBone)) then return false end
	if (trace.Entity:IsWorld()) then return false end
	
	local EntIndex = trace.Entity:EntIndex()
	
	// If we haven't already got the Prop, then please add a new entry!
	
	if not (self.PCEntLib[EntIndex]) then
		
		local colour = Color(0, 0, 0, 0)
		colour.r, colour.g, colour.b, colour.a = trace.Entity:GetColor()
		
		Msg(trace.Entity:GetMaterial())
		self.PCEntLib[EntIndex] = {Ent = trace.Entity, Colour = colour, Mat = trace.Entity:GetMaterial(), Bone = trace.PhysicsBone}
		trace.Entity:SetColor(Color(33, 115, 145, 200))
		trace.Entity:SetRenderMode(RENDERMODE_TRANSALPHA)
		trace.Entity:SetMaterial("models/debug/debugwhite")
		
	else // Otherwise, remove it!
	
		local colour = self.PCEntLib[EntIndex].Colour
		trace.Entity:SetColor(colour.r, colour.g, colour.b, colour.a)
		trace.Entity:SetMaterial(self.PCEntLib[EntIndex].Mat)
		self.PCEntLib[EntIndex] = nil
		
	end

	return true
	
end

function TOOL:RightClick( )
	
	// Begin Constraining!!
	
	if CLIENT then return true end
	if (table.Count(self.PCEntLib) < 2) then return end
	undo.Create("Physics Constraint")
	self.GoConstrain = 1

	return true
	
end

function TOOL:Reload()

	if CLIENT then return false end
	if (table.Count(self.PCEntLib) < 1) then return end
	
	// Clear our Library
	for k, v in pairs(self.PCEntLib) do
	
		local Ent = v.Ent
		if (IsValid(Ent)) then
			
			Ent:SetColor(v.Colour.r, v.Colour.g, v.Colour.b, v.Colour.a)
			Ent:SetRenderMode(RENDERMODE_TRANSALPHA)
			Ent:SetMaterial(v.Mat)
			
		end
		
	end
	
	self.PCEntLib = { }
	
	return true
	
end

function TOOL.BuildCPanel( panel )
	
	panel:AddControl("Slider", {Label = "Force Weld", Command = "physcons_forcelimit", Type = "Integer", Min = "0", Max = "10000"})

end