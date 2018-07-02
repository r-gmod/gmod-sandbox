TOOL.Category	= "Constraints"
TOOL.Name		= "#Constraint - Smart"
TOOL.Command	= nil
TOOL.ConfigName = ""
TOOL.TimeBetweenConstraints = 0.1

TOOL.ClientConVar["radius"] = 512
TOOL.ClientConVar["weld"] = 1
TOOL.ClientConVar["nocollide"] = 1
TOOL.ClientConVar["cmax"] = 3
TOOL.ClientConVar["freeze"] = 1
TOOL.ClientConVar["unfreeze"] = 1

TOOL.SelectedProps = {}
TOOL.Working = false
TOOL.ConstraintedPropsTotal = 0
TOOL.ConstraintedPropsTotalFix = 0

cleanup.Register("smart_constraints")

if(CLIENT) then
	language.Add("Tool_smart_constraint_name", "Smart Constraint")
	language.Add("Tool_smart_constraint_desc", "Constraint Props Easily")
	language.Add("Tool_smart_constraint_0", "Left click (+Use/+Shift) selects/deselects props. Right click smart constraints props.")
	language.Add("Undone_smart_constraint", "Undone Smart Constraint")

	language.Add("Cleanup_smart_constraints", "Smart Constraints")
	language.Add("Cleaned_smart_constraints", "Cleaned up all Smart Constraints")
end

function TOOL:ClearSelectedProps()
	if(table.Count(self.SelectedProps) > 0) then
		for k, v in pairs(self.SelectedProps) do
			if(v.ent:IsValid()) then
				v.ent:SetColor(v.r, v.g, v.b, v.a)
			end
		end
		self.SelectedProps = {}
		return true
	else
		return false
	end
end

function TOOL:DoConstraint(Weld, Nocollide, Ent1, Ent2)
	if(!Ent1:IsValid() or !Ent2:IsValid()) then return end
	if(Weld == 1) then
		local WeldConstraint = constraint.Weld(Ent1, Ent2, 0, 0, 0)
		if(WeldConstraint) then
			undo.AddEntity(WeldConstraint)
			self:GetOwner():AddCleanup("smart_constraints", WeldConstraint)
		end
		--Error("Weld Created...\n")
	end
	if(Nocollide == 1) then
		local NocollideConstraint = constraint.NoCollide(Ent1, Ent2, 0, 0)
		if(NocollideConstraint) then
			undo.AddEntity(NocollideConstraint)
			self:GetOwner():AddCleanup("smart_constraints", NocollideConstraint)
		end
		--Error("NoCollide Created...\n")
	end

	-- if(Weld == 1 and Nocollide == 1) then
		-- self:GetOwner():PrintMessage(HUD_PRINTCENTER, "Welds/Nocollides Placed: "..self.ConstraintedPropsTotalFix)
	-- elseif(Weld == 1) then
		-- self:GetOwner():PrintMessage(HUD_PRINTCENTER, "Welds Placed: "..self.ConstraintedPropsTotalFix)
	-- elseif(Nocollide == 1) then
		-- self:GetOwner():PrintMessage(HUD_PRINTCENTER, "Nocollides Placed: "..self.ConstraintedPropsTotalFix)
	-- end
	self.ConstraintedPropsTotalFix = self.ConstraintedPropsTotalFix + 1
end

function TOOL:FreezeEntTable(Table)
	for k,v in pairs(Table) do
		if(!v.ent:IsValid()) then break end
		local PhysObj = v.ent:GetPhysicsObject()
		if(PhysObj:IsMoveable()) then
			PhysObj:EnableMotion(false)
			PhysObj:Wake()
		end
	end
end

function TOOL:UnfreezeEntTable(Table)
	for k,v in pairs(Table) do
		if(!v.ent:IsValid()) then break end
		local PhysObj = v.ent:GetPhysicsObject()
		if(!PhysObj:IsMoveable()) then
			PhysObj:EnableMotion(true)
			PhysObj:Wake()
		end
	end
end

function TOOL:Finish(Table, Unfreeze)
	if(Unfreeze == 1) then
		self:UnfreezeEntTable(Table)
	end
	self.Working = false
	undo.SetPlayer(self:GetOwner())
	undo.Finish()
	self:ClearSelectedProps()
	self:GetOwner():PrintMessage(HUD_PRINTTALK, "Smart Constraint: Finished. Total Constraints: "..self.ConstraintedPropsTotalFix)
end

function TOOL:CheckFinish(Table, Weld, Nocollide, Unfreeze)
	local ConstraintDone = nil
	if(Weld == 1 or Nocollide == 1) then
		if(self.ConstraintedPropsTotal == self.ConstraintedPropsTotalFix) then
			ConstraintDone = true
		else
			ConstraintDone = false
		end
	end

	if(ConstraintDone == nil or ConstraintDone == true) then
		self:Finish(Table, Unfreeze)
	else
		timer.Simple(1, self.CheckFinish, self, Table, Weld, Nocollide, Unfreeze)
	end
end

--Based on a function by tad2020
function TOOL:SmartGetAllEntities(Entity, MainEntTable, MainConstraintTable)
	local MainEntTable = MainEntTable or {}
	local MainConstraintTable = MainConstraintTable or {}
	if(!Entity:IsValid()) then return end
	if(!table.HasValue(MainEntTable, Entity)) then
		table.insert(MainEntTable, Entity)
	end
	if(!constraint.HasConstraints(Entity)) then return MainEntTable end
	for k, Constraint in pairs(Entity.Constraints) do
		if(!table.HasValue(MainConstraintTable, Constraint)) then
			table.insert(MainConstraintTable, Constraint)
			if(Constraint["Ent"] and Constraint["Ent"]:IsValid()) then
				self:SmartGetAllEntities(Constraint["Ent"].Entity, MainEntTable, MainConstraintTable)
			else
				for i=1, 6 do
					if(Constraint["Ent"..i] and Constraint["Ent"..i]:IsValid()) then
						self:SmartGetAllEntities(Constraint["Ent"..i].Entity, MainEntTable, MainConstraintTable)
					end
				end
			end
		end
	end
	--return MainEntTable, MainConstraintTable
	return MainEntTable
end

function TOOL:SmartConstraint(MainEntTable, Weld, Nocollide, MaxConstraints, Freeze, Unfreeze)
	self:GetOwner():PrintMessage(HUD_PRINTTALK, "Smart Constraint: Working...")
	if(Freeze == 1) then
		self:FreezeEntTable(MainEntTable)
	end
	if(Weld == 1 or Nocollide == 1) then
		undo.Create("smart_constraint")
		local LastConstraintTime = 1
		local ConstraintProps = {}
		for k0,v0 in pairs(MainEntTable) do
			ConstraintProps[k0] = {}
		end
		--Based on a function by Dunk
		for k1,v1 in pairs(MainEntTable) do
			for x=1, MaxConstraints do
				local ClosestDistance = 99999999
				local ClosestProp = false
				for k2,v2 in pairs(MainEntTable) do
					if(k1 ~= k2) then
						local Check = false
						for k3,v3 in pairs(ConstraintProps[k1]) do
							if(v3 == k2) then
								Check = true
								break
							end
						end
						if(!Check) then
							if(!v1.ent:IsValid() or !v2.ent:IsValid()) then break end
							local CurrentDistance = (v1.ent:GetPos() - v2.ent:GetPos()):Length()
							if(CurrentDistance < ClosestDistance) then
								ClosestDistance = CurrentDistance
								ClosestProp = k2
							end
						end
					end
				end
				if(ClosestProp ~= false) then
					if(!v1.ent:IsValid() or !MainEntTable[ClosestProp].ent:IsValid()) then break end
					local Ent1 = v1.ent
					local Ent2 = MainEntTable[ClosestProp].ent
					timer.Simple(LastConstraintTime, self.DoConstraint, self, Weld, Nocollide, Ent1, Ent2)
					LastConstraintTime = LastConstraintTime + self.TimeBetweenConstraints
					self.ConstraintedPropsTotal = self.ConstraintedPropsTotal + 1
					table.insert(ConstraintProps[k1], ClosestProp)
					table.insert(ConstraintProps[ClosestProp], k1)
				else
					break
				end
			end
		end
		timer.Simple(1, self.CheckFinish, self, MainEntTable, Weld, Nocollide, Unfreeze)
	else
		self:Finish(MainEntTable, Unfreeze)
	end
end

function TOOL:SelectEnt(ent)
	local Prop = {}
	Prop.ent = ent
	Prop.r, Prop.g, Prop.b, Prop.a = ent:GetColor()
	table.insert(self.SelectedProps, Prop)
	ent:SetColor(255, 0, 0, 255)
end

function TOOL:UnSelectEnt(ent)
	for k, Prop in pairs(self.SelectedProps) do
		if(Prop.ent == ent) then
			Prop.ent:SetColor(Prop.r, Prop.g, Prop.b, Prop.a)
			table.remove(self.SelectedProps, k)
		end
	end
end

function TOOL:CheckEnt(ent)
	local FoundIt = false
	if(table.Count(self.SelectedProps) == 0) then
		return false
	end
	for k, Prop in pairs(self.SelectedProps) do
		if(Prop.ent == ent) then
			FoundIt = true
		end
	end
	if(FoundIt == true) then
		return true
	else
		return false
	end
end

--Based on a function by Conna
function TOOL:IsPropOwner(ply, ent)
	for k, v in pairs(g_SBoxObjects) do
		for b, j in pairs(v) do
			for _, e in pairs(j) do
				if(e == ent) then
					if(k == ply:UniqueID()) then
						return true
					end
				end
			end
		end
	end

	for k, v in pairs(GAMEMODE.CameraList) do
		for b, j in pairs(v) do
			if(j == ent) then
				if(k == ply:UniqueID()) then
					return true
				end
			end
		end
	end
	return false
end

function TOOL:LeftClick(tr)
	local ply = self:GetOwner()
	if(!tr.Entity or !tr.Entity:IsValid() or tr.Entity:IsPlayer() or tr.Entity:IsWorld() or self.Working) then return false end
	if(CLIENT) then return true end
	local ent = tr.Entity

	if(ply:KeyDown(IN_USE)) then
		local SelectedProps = 0
		local Radius = math.Clamp(self:GetClientNumber("radius"), 64, 1024)
		for k,v in pairs(ents.FindInSphere(tr.HitPos, Radius)) do
			if(v:IsValid() and !self:CheckEnt(v) and self:IsPropOwner(ply, v) == true) then
				self:SelectEnt(v)
				SelectedProps = SelectedProps + 1
			end
		end
		self:GetOwner():PrintMessage(HUD_PRINTTALK, "Smart Constraint: "..SelectedProps.." props were selected.")
	elseif(ply:KeyDown(IN_SPEED)) then
		local SelectedProps = 0
		local SmartTable = self:SmartGetAllEntities(ent)
		for k,v in pairs(SmartTable) do
			if(v:IsValid() and !self:CheckEnt(v)) then
				self:SelectEnt(v)
				SelectedProps = SelectedProps + 1
			end
		end
		self:GetOwner():PrintMessage(HUD_PRINTTALK, "Smart Constraint: "..SelectedProps.." props were selected.")
	elseif(self:CheckEnt(ent)) then
		self:UnSelectEnt(ent)
	else
		self:SelectEnt(ent)
	end

	return true
end

function TOOL:RightClick(tr)
	if(CLIENT) then return true end
	local ent = tr.Entity

	local weld	= self:GetClientNumber("weld")
	local nocollide	= self:GetClientNumber("nocollide")
	local freeze	= self:GetClientNumber("freeze")
	local unfreeze	= self:GetClientNumber("unfreeze")
	local cmax	= math.Clamp(self:GetClientNumber("cmax"), 1, 10)
	if(weld == 0 and nocollide == 0 and unfreeze == 0 or table.Count(self.SelectedProps) <= 1 or self.Working) then return false end
	self.Working = true
	self.ConstraintedPropsTotal = 0
	self.ConstraintedPropsTotalFix = 0
	self:SmartConstraint(self.SelectedProps, weld, nocollide, cmax, freeze, unfreeze)
	return true
end

function TOOL:Reload(tr)
	if(CLIENT) then return true end
	if(self.Working) then return false end
	self:ClearSelectedProps()
end

-- function TOOL:Holster()
	-- if(CLIENT) then return true end
	-- self:ClearSelectedProps()
-- end

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Text = "Smart Constraint by Spacetech"})
	CPanel:AddControl("Slider", {Label = "Auto Select Radius:", Type = "integer", Min = "64", Max = "1024", Command = "smart_constraint_radius"})
    CPanel:AddControl("CheckBox", {Label = "Weld", Command = "smart_constraint_weld"})
    CPanel:AddControl("CheckBox", {Label = "Nocollide", Command = "smart_constraint_nocollide"})
    CPanel:AddControl("Slider", {Label = "Max Welds/Nocollides Per Prop:", Type = "integer", Min = "1", Max = "10", Command = "smart_constraint_cmax"})
	CPanel:AddControl("CheckBox", {Label = "Freeze (Before Starting)", Command = "smart_constraint_freeze"})
    CPanel:AddControl("CheckBox", {Label = "Unfreeze", Command = "smart_constraint_unfreeze"})
end
