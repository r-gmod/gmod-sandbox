
TOOL.Category = "Render"
TOOL.Name = "#tool.rb655_easy_inspector.name"

TOOL.ClientConVar[ "noglow" ] = "0"
TOOL.ClientConVar[ "lp" ] = "1"
TOOL.ClientConVar[ "names" ] = "1"
TOOL.ClientConVar[ "dir" ] = "1"
TOOL.ClientConVar[ "hook" ] = "0"
TOOL.ClientConVar[ "units" ] = "0"

TOOL.Information = {
	{ name = "info", stage = 1 },
	{ name = "left" },
	{ name = "right" },
	{ name = "right_use", icon2 = "gui/e.png" },
	{ name = "reload" },
	{ name = "reload_use", icon2 = "gui/e.png" }
}

if ( CLIENT ) then
	language.Add( "tool.rb655_easy_inspector.1", "See information in the context menu" )
	language.Add( "tool.rb655_easy_inspector.left", "Select an object" )
	language.Add( "tool.rb655_easy_inspector.right", "Select next mode" )
	language.Add( "tool.rb655_easy_inspector.right_use", "Select previous mode" )
	language.Add( "tool.rb655_easy_inspector.reload", "Select yourself" )
	language.Add( "tool.rb655_easy_inspector.reload_use", "Select your view model" )
end

local mat_wireframe = Material( "models/wireframe" )

local function ConvertToUnit( units, speed )
	local unit = GetConVarNumber( "rb655_easy_inspector_units" )
	if ( unit == 1 ) then // Kilometres
		if ( speed ) then return units * 1.905 / 100000 * 3600 end
		return units * 1.905 / 100000
	elseif ( unit == 2 ) then // Meters
		return units * 1.905 / 100
	elseif ( unit == 3 ) then // Centimetres
		return units * 1.905
	elseif ( unit == 4 ) then // Miles
		if ( speed ) then return units * ( 1 / 16 ) / 5280 * 3600 end
		return units * ( 1 / 16 ) / 5280
	elseif ( unit == 5 ) then // Inches
		return units * 0.75
	elseif ( unit == 6 ) then // Foot
		return units * ( 1 / 16 )
	end

	return units
end

local InfoFuncs = { {
		name = "Attachments",
		check = function( ent )
			if ( !ent:GetAttachments() or #ent:GetAttachments() < 1 ) then
				return "Entity doesn't have any attachments!"
			end
		end,
		func = function( ent, labels, dirs )

			local points = {}
			for id, t in pairs( ent:GetAttachments() or {} ) do
				local angpos = ent:GetAttachment( t.id )

				local pos = angpos.Pos:ToScreen()

				if ( dirs ) then
					cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( angpos.Pos, angpos.Pos + angpos.Ang:Forward() * 8, Color( 64, 178, 255 ), false )
					cam.End3D()
				end

				draw.RoundedBox( 0, pos.x - 3, pos.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, pos.x - 2, pos.y - 2, 4, 4, Color( 0, 0, 0 ) )

				local offset = 0
				for id, p in pairs( points or {} ) do
					if ( p.x == pos.x && p.y == pos.y ) then
						offset = offset + 10
					end
				end

				if ( labels ) then
					draw.SimpleText( t.name .. " (" ..  t.id .. ")", "rb655_attachment", pos.x, pos.y - 16 + offset, color_white, 1, 0 )
				end

				table.insert( points, pos )

			end
		end
	}, {
		name = "Bones",
		check = function( ent )
			if ( !ent:GetBoneCount() or ent:GetBoneCount() < 1 ) then
				return "Entity doesn't have any bones!"
			end
		end,
		func = function( ent, labels, dirs )

			local points = {}
			for i = 0, ent:GetBoneCount() - 1 do

				local pos = ent:GetBonePosition( i )
				if ( pos == ent:GetPos() && ent:GetBoneMatrix( i ) ) then
					pos = ent:GetBoneMatrix( i ):GetTranslation()
				end

				if ( ent:GetBoneName( i ) == "__INVALIDBONE__" ) then continue end

				if ( dirs && ent:GetBoneMatrix( i ) ) then

					cam.Start3D( EyePos(), EyeAngles() )
					for id, bone in pairs( ent:GetChildBones( i ) ) do

						local pos2 = ent:GetBonePosition( bone )
						if ( pos2 == ent:GetPos() && ent:GetBoneMatrix( bone ) ) then
							pos2 = ent:GetBoneMatrix( bone ):GetTranslation()
						end

						render.DrawLine( pos, pos2, Color( 255, 178, 64 ), false )

					end
					cam.End3D()
				end

				pos = pos:ToScreen()

				draw.RoundedBox( 0, pos.x - 3, pos.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, pos.x - 2, pos.y - 2, 4, 4, Color( 0, 0, 0 ) )

				local offset = 0
				for id, p in pairs( points or {} ) do
					if ( p.x == pos.x && p.y == pos.y ) then
						offset = offset + 10
					end
				end

				if ( labels ) then
					draw.SimpleText( ent:GetBoneName( i ) .. " (" ..  i .. ")", "rb655_attachment", pos.x, pos.y - 16 + offset, color_white, 1, 0  )
				end

				table.insert( points, pos )

			end
		end
	}, {
		name = "Physics Box",
		check = function( ent )
			if ( !ent.InspectorMeshes ) then
				return "Entity doesn't have any physics objects! Or we failed to get it."
			end
		end,
		// This is a hacky one..
		func = function( ent, labels, dirs )

			if ( ent.InspectorMeshes && !ent.InspectorMesh ) then
				local gMesh = {}
				local gMeshIDs = {}
				local i = 0
				for id, tab in pairs( ent.InspectorMeshes ) do
					for _, b in pairs( tab ) do
						gMesh[ i ] = Mesh()
						gMesh[ i ]:BuildFromTriangles( b )
						gMeshIDs[ i ] = id
						i = i + 1
					end
				end

				ent.InspectorMesh = gMesh
				ent.InspectorMeshIDs = gMeshIDs
			end

			if ( !ent.InspectorMesh ) then return end

			cam.Start3D( EyePos(), EyeAngles() )

			mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
			render.SetMaterial( mat_wireframe )
			for i, mesh in pairs( ent.InspectorMesh ) do
				local matrix = Matrix()
				local bonemat = ent:GetBoneMatrix( ent:TranslatePhysBoneToBone( ent.InspectorMeshIDs && ent.InspectorMeshIDs[i] or 0) )
				if ( bonemat && !ent:IsNPC() && !ent:IsPlayer() ) then matrix:SetAngles( bonemat:GetAngles() ) else matrix:SetAngles( ent:GetAngles() ) end
				if ( bonemat && !ent:IsNPC() && !ent:IsPlayer() ) then matrix:SetTranslation( bonemat:GetTranslation() ) else matrix:SetTranslation( ent:GetPos() ) end

				cam.PushModelMatrix( matrix )

				mesh:Draw()

				cam.PopModelMatrix()
			end

			cam.End3D()

		end
	}, {
		name = "Hit Groups",
		check = function( ent )
			if ( !ent:GetHitBoxGroupCount() ) then
				return "Entity doesn't have any hit groups!"
			end
		end,
		func = function( ent, labels, dirs )

			cam.Start3D( EyePos(), EyeAngles() )
			for i = 0, ent:GetHitBoxGroupCount() - 1 do
				for j = 0, ent:GetHitBoxCount( i ) - 1 do
					local bone = ent:GetHitBoxBone( j, i )
					if ( !bone || bone < 0 ) then continue end

					local mins, maxs = ent:GetHitBoxBounds( j, i )
					local scale = 1
					local pos, ang = ent:GetBonePosition( bone )

					if ( ent:GetBoneMatrix( bone ) ) then
						scale = ent:GetBoneMatrix( bone ):GetScale()
						ang = ent:GetBoneMatrix( bone ):GetAngles()
					end

					mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
					render.SetMaterial( mat_wireframe )
					render.DrawBox( pos, ang, mins * scale, maxs * scale )
				end
			end
			cam.End3D()

		end
	}, {
		name = "Orientated Bounding Box",
		func = function( ent, labels, dirs )
			local pos = ent:GetPos()
			cam.Start3D( EyePos(), EyeAngles() )
				mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
				render.SetMaterial( mat_wireframe )
				local ang = ent:GetAngles() if ( ent:IsPlayer() ) then ang.p = 0 end
				render.DrawBox( ent:GetPos(), ang, ent:OBBMins(), ent:OBBMaxs() )
			cam.End3D()

			if ( !labels ) then return end

			local pos = ent:GetPos()
			local ang = ent:GetAngles() if ( ent:IsPlayer() ) then ang.p = 0 end

			local p = LocalToWorld( ent:OBBMins(), ang, pos, ang ):ToScreen()
			local min = ent:OBBMins()
			draw.SimpleText( Format( "Mins ( %i, %i, %i )", min.x, min.y, min.z ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = LocalToWorld( ent:OBBCenter(), ang, pos, ang ):ToScreen() //ent:LocalToWorld( ent:OBBCenter() ):ToScreen()
			local cen = ent:OBBCenter()
			draw.SimpleText( Format( "Center ( %i, %i, %i )", cen.x, cen.y, cen.z ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = LocalToWorld( ent:OBBMaxs(), ang, pos, ang ):ToScreen() // ent:LocalToWorld( ent:OBBMaxs() ):ToScreen()
			local max = ent:OBBMaxs()
			draw.SimpleText( Format( "Maxs ( %i, %i, %i )", max.x, max.y, max.z ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Render Bounds",
		func = function( ent, labels, dirs )
			local min, max = ent:GetRenderBounds()
			cam.Start3D( EyePos(), EyeAngles() )
				mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
				render.SetMaterial( mat_wireframe )
				render.DrawBox( ent:GetPos(), ent:GetAngles(), min, max )
			cam.End3D()

			if ( !labels ) then return end

			local p = ent:LocalToWorld( min ):ToScreen()
			draw.SimpleText( Format( "Mins ( %i, %i, %i )", min.x, min.y, min.z ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( ( min + max ) / 2 ):ToScreen()
			draw.SimpleText( Format( "Center ( %i, %i, %i )", ( min.x + max.x ) / 2, ( min.y + max.y ) / 2, ( min.z + max.z ) / 2 ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( max ):ToScreen()
			draw.SimpleText( Format( "Maxs ( %i, %i, %i )", max.x, max.y, max.z ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Collision Bounds",
		func = function( ent, labels, dirs )
			local min, max = ent:GetCollisionBounds()
			cam.Start3D( EyePos(), EyeAngles() )
				mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
				render.SetMaterial( mat_wireframe )
				render.DrawBox( ent:GetPos(), ent:GetAngles(), min, max )
			cam.End3D()

			if ( !labels ) then return end

			local p = ent:LocalToWorld( min ):ToScreen()
			draw.SimpleText( Format( "Mins ( %i, %i, %i )", min.x, min.y, min.z ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( ( min + max ) / 2 ):ToScreen()
			draw.SimpleText( Format( "Center ( %i, %i, %i )", ( min.x + max.x ) / 2, ( min.y + max.y ) / 2, ( min.z + max.z ) / 2 ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( max ):ToScreen()
			draw.SimpleText( Format( "Maxs ( %i, %i, %i )", max.x, max.y, max.z ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Model Bounds",
		func = function( ent, labels, dirs )
			local min, max = ent:GetModelBounds()
			cam.Start3D( EyePos(), EyeAngles() )
				mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
				render.SetMaterial( mat_wireframe )
				render.DrawBox( ent:GetPos(), ent:GetAngles(), min, max )
			cam.End3D()

			if ( !labels ) then return end

			local p = ent:LocalToWorld( min ):ToScreen()
			draw.SimpleText( Format( "Mins ( %i, %i, %i )", min.x, min.y, min.z ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( ( min + max ) / 2 ):ToScreen()
			draw.SimpleText( Format( "Center ( %i, %i, %i )", ( min.x + max.x ) / 2, ( min.y + max.y ) / 2, ( min.z + max.z ) / 2 ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( max ):ToScreen()
			draw.SimpleText( Format( "Maxs ( %i, %i, %i )", max.x, max.y, max.z ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Model Render Bounds",
		func = function( ent, labels, dirs )
			local min, max = ent:GetModelRenderBounds()
			cam.Start3D( EyePos(), EyeAngles() )
				mat_wireframe:SetVector( "$color", Vector( 1, 1, 1 ) )
				render.SetMaterial( mat_wireframe )
				render.DrawBox( ent:GetPos(), ent:GetAngles(), min, max )
			cam.End3D()

			if ( !labels ) then return end

			local p = ent:LocalToWorld( min ):ToScreen()
			draw.SimpleText( Format( "Mins ( %i, %i, %i )", min.x, min.y, min.z ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( ( min + max ) / 2 ):ToScreen()
			draw.SimpleText( Format( "Center ( %i, %i, %i )", ( min.x + max.x ) / 2, ( min.y + max.y ) / 2, ( min.z + max.z ) / 2 ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ent:LocalToWorld( max ):ToScreen()
			draw.SimpleText( Format( "Maxs ( %i, %i, %i )", max.x, max.y, max.z ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Velocity",
		func = function( ent, labels, dirs )

			local vel = ent:GetVelocity()
			local pos = ent:GetPos()
			if ( pos == vector_origin ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

			cam.Start3D( EyePos(), EyeAngles() )
				local mul = 4
				render.DrawLine( pos, pos + Vector( vel.x / mul, 0, 0 ), Color( 255, 0, 0 ), false )
				render.DrawLine( pos, pos + Vector( 0, vel.y / mul, 0 ), Color( 0, 255, 0 ), false )
				render.DrawLine( pos, pos + Vector( 0, 0, vel.z / mul ), Color( 0, 128, 255 ), false )
				render.DrawLine( pos, pos + vel / mul, Color( 255, 255, 255 ), false )
			cam.End3D()

			if ( !labels ) then return end

			local p = ( pos + Vector( vel.x / mul, 0, 0 ) ):ToScreen()
			draw.SimpleText( math.floor( ConvertToUnit( vel.x, true ) ), "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ( pos + Vector( 0, vel.y / mul, 0 ) ):ToScreen()
			draw.SimpleText( math.floor( ConvertToUnit( vel.y, true ) ), "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ( pos + Vector( 0, 0, vel.z / mul ) ):ToScreen()
			draw.SimpleText( math.floor( ConvertToUnit( vel.z, true ) ), "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ( pos + vel / mul ):ToScreen()
			draw.SimpleText( math.floor( ConvertToUnit( vel:Length(), true ) ), "rb655_attachment", p.x, p.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "Directions",
		func = function( ent, labels, dirs )

			local ang = ent:GetAngles()
			local pos = ent:GetPos()
			if ( pos == vector_origin ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

			cam.Start3D( EyePos(), EyeAngles() )
				local mul = 1
				render.DrawLine( pos, pos + ang:Forward() * 50, Color( 255, 0, 0 ), false )
				render.DrawLine( pos, pos + ang:Right() * 50, Color( 0, 255, 0 ), false )
				render.DrawLine( pos, pos + ang:Up() * 50, Color( 0, 128, 255 ), false )
			cam.End3D()

			if ( !labels ) then return end

			local p = ( pos + ang:Forward() * 51 ):ToScreen()
			draw.SimpleText( "Forward", "rb655_attachment", p.x, p.y, Color( 255, 0, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ( pos + ang:Right() * 51 ):ToScreen()
			draw.SimpleText( "Right", "rb655_attachment", p.x, p.y, Color( 0, 255, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			local p = ( pos + ang:Up() * 51 ):ToScreen()
			draw.SimpleText( "Up", "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	}, {
		name = "World To Local",
		world = true,
		func = function( ent, labels, dirs )

			local tr = LocalPlayer():GetEyeTrace()
			local pos = Entity( 0 ) == ent && vector_origin or ent:GetPos()
			if ( pos == vector_origin && Entity( 0 ) != ent ) then pos = ent:LocalToWorld( ent:OBBCenter() ) end

			local pos1 = Entity( 0 ) == ent && Entity( 0 ):GetNWVector( "LocalPos2" ) or ent:LocalToWorld( ent:GetNWVector( "LocalPos" ) )
			local pos2 = tr.HitPos
			local pos3 = Entity( 0 ) == ent && vector_origin or ent:GetPos()

			local dir = Entity( 0 ) == ent && Entity( 0 ):GetNWVector( "LocalDir2" ) or ent:GetNWVector( "LocalDir" )

			cam.Start3D( EyePos(), EyeAngles() )
				render.DrawLine( pos, pos1, Color( 255, 255, 255 ), false )
				render.DrawLine( pos, pos2, Color( 255, 128, 0 ), false )
				render.DrawLine( pos1, pos2, Color( 0, 128, 255 ), false )
			cam.End3D()

			if ( labels ) then
				local p1 = pos1:ToScreen()
				draw.SimpleText( "Hit Pos", "rb655_attachment", p1.x, p1.y, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( math.floor( ConvertToUnit( pos1:Distance( pos3 ) ) ), "rb655_attachment", p1.x, p1.y + 10, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				local p2 = pos2:ToScreen()
				draw.SimpleText( "Aim Pos", "rb655_attachment", p2.x, p2.y, Color( 255, 128, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( math.floor( ConvertToUnit( pos2:Distance( pos3 ) ) ), "rb655_attachment", p2.x, p2.y + 10, Color( 255, 128, 0 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				local p = {
					x = ( p1.x + p2.x ) / 2,
					y = ( p1.y + p2.y ) / 2
				}
				draw.SimpleText( "Distance", "rb655_attachment", p.x, p.y, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( math.floor( ConvertToUnit( pos1:Distance( pos2 ) ) ), "rb655_attachment", p.x, p.y + 10, Color( 0, 128, 255 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			end

			if ( dirs ) then
				cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( pos2, pos2 + tr.HitNormal * 8, Color( 255, 128, 0 ), false )
					render.DrawLine( pos1, pos1 + dir * 8, Color( 255, 255, 255 ), false )
				cam.End3D()
			end

		end
	}, {
		name = "Sequence",
		func = function( ent, labels, dirs )

			local seqinfo = ent:GetSequenceInfo( ent:GetSequence() )

			cam.Start3D( EyePos(), EyeAngles() )
				local ang = ent:GetAngles()
				if ( ent:IsPlayer() ) then ang.p = 0 end
				render.DrawWireframeBox( ent:GetPos(), ang, seqinfo.bbmin, seqinfo.bbmax, Color( 255, 255, 255 ), true )
			cam.End3D()

			local textpos = ( ent:GetPos() + Vector( 0, 0, seqinfo.bbmax.z + 10 ) ):ToScreen()

			if ( textpos.visible ) then
				draw.SimpleText( seqinfo.label, "rb655_attachment", textpos.x, textpos.y - 20, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
				draw.SimpleText( seqinfo.activity .. ": " .. seqinfo.activityname, "rb655_attachment", textpos.x, textpos.y - 4, Color( 255, 255, 255 ), TEXT_ALIGN_CENTER )
			end

		end
	}
}

// Top fucking seecreet, don't fucking tell anyone, fuck.
if ( RB_VEHICLE_UPGRADE ) then
	table.insert( InfoFuncs, {
		name = "Vehicle Stuff",
		check = function( ent )
			if ( !ent:IsVehicle() ) then
				return "Entity is not a vehicle!"
			elseif ( !GetVehicleConfig( ent, "lights" ) && !GetVehicleConfig( ent, "seats" ) && !GetVehicleConfig( ent, "attachments" ) && !GetVehicleConfig( ent, "exhausts" ) ) then
				return "Entity doesn't have any vehicle stuff!"
			end
		end,
		func = function( ent, labels, dirs )

			for id, t in pairs( GetVehicleConfig( ent, "lights" ) or {} ) do
				local att = ent:GetAttachment( ent:LookupAttachment( t.att or "" ) )
				local pos, ang = LocalToWorld( t.pos or Vector( 0, 0, 0 ), t.ang or Angle( 0, 0, 0 ), att && att.Pos or ent:GetPos(), att && att.Ang or ent:GetAngles() )

				local posScreen = pos:ToScreen()
				draw.RoundedBox( 0, posScreen.x - 3, posScreen.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, posScreen.x - 2, posScreen.y - 2, 4, 4, Color( 0, 0, 0 ) )

				if ( labels ) then
					local add = t.type
					if ( t.createlight ) then add = add .. ", lamp" end
					draw.SimpleText( "Light ( " .. add .. " )", "rb655_attachment", posScreen.x, posScreen.y + 4, color_white, 1, 0 )
				end

				if ( dirs ) then
					cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( pos, pos + ang:Forward() * 8, Color( 64, 178, 255 ), false )
					cam.End3D()
				end
			end

			for id, t in pairs( GetVehicleConfig( ent, "seats" ) or {} ) do
				local pos = ent:LocalToWorld( t.pos or Vector( 0, 0, 0 ) )
				local ang = ent:LocalToWorldAngles( ( t.ang or Angle( 0, 0, 0 ) ) + Angle( 0, 90, 0 ) )

				local posScreen = pos:ToScreen()
				draw.RoundedBox( 0, posScreen.x - 3, posScreen.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, posScreen.x - 2, posScreen.y - 2, 4, 4, Color( 0, 0, 0 ) )

				if ( labels ) then
					draw.SimpleText( "Seat ( " .. id .. " )", "rb655_attachment", posScreen.x, posScreen.y + 4, color_white, 1, 0 )
				end

				if ( dirs ) then
					cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( pos, pos + ang:Forward() * 8, Color( 64, 178, 255 ), false )
					cam.End3D()
				end
			end

			for id, t in pairs( GetVehicleConfig( ent, "attachments" ) or {} ) do
				local pos = ent:LocalToWorld( t.pos or Vector( 0, 0, 0 ) )
				local ang = ent:LocalToWorldAngles( t.ang or Angle( 0, 0, 0 ) )

				local posScreen = pos:ToScreen()
				draw.RoundedBox( 0, posScreen.x - 3, posScreen.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, posScreen.x - 2, posScreen.y - 2, 4, 4, Color( 0, 0, 0 ) )

				if ( labels ) then
					draw.SimpleText( "Attachment ( " .. t.model .. " )", "rb655_attachment", posScreen.x, posScreen.y + 4, color_white, 1, 0 )
				end

				if ( dirs ) then
					cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( pos, pos + ang:Forward() * 8, Color( 64, 178, 255 ), false )
					cam.End3D()
				end
			end

			for id, t in pairs( GetVehicleConfig( ent, "exhausts" ) or {} ) do
				local pos = ent:LocalToWorld( t.pos or Vector( 0, 0, 0 ) )
				local ang = ent:LocalToWorldAngles( ( t.ang or Angle( 0, 0, 0 ) ) - Angle( 0, 90, 0 ) )

				local posScreen = pos:ToScreen()
				draw.RoundedBox( 0, posScreen.x - 3, posScreen.y - 3, 6, 6, Color( 255, 255, 255 ) )
				draw.RoundedBox( 0, posScreen.x - 2, posScreen.y - 2, 4, 4, Color( 0, 0, 0 ) )

				if ( labels ) then
					draw.SimpleText( "Exhaust ( " .. id .. " )", "rb655_attachment", posScreen.x, posScreen.y + 4, color_white, 1, 0 )
				end

				if ( dirs ) then
					cam.Start3D( EyePos(), EyeAngles() )
					render.DrawLine( pos, pos + ang:Forward() * 8, Color( 64, 178, 255 ), false )
					cam.End3D()
				end
			end
		end
	} )
end

function TOOL:NextSelecetedFunc( num )
	local cur = self:GetWeapon():GetNWInt( "rb655_inspector_func", 1 )
	if ( cur + num > #InfoFuncs ) then cur = 0 end
	if ( cur + num < 1 ) then cur = #InfoFuncs + 1 end
	self:GetWeapon():SetNWInt( "rb655_inspector_func", cur + num )
end

function TOOL:GetSelectedFunc()
	return self:GetWeapon():GetNWInt( "rb655_inspector_func", 1 )
end

function TOOL:GetSelectedEntity()
	return self:GetWeapon():GetNWEntity( "rb655_attachments_entity" )
end

function TOOL:GetStage()
	if ( !IsValid( self:GetSelectedEntity() ) ) then return 0 end
	return 1
end

if ( SERVER ) then
	util.AddNetworkString( "rb655_inspector_genericinfo" )
	util.AddNetworkString( "rb655_inspector_physicsinfo" )
	util.AddNetworkString( "rb655_inspector_reqinfo" )

	net.Receive( "rb655_inspector_reqinfo", function( len, ply )
		local ent = net.ReadEntity()

		if ( !IsValid( ent:GetPhysicsObject() ) ) then return end

		local data = { data = {}, model = ent:GetModel(), class = ent:GetClass(), entid = ent:EntIndex() }
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			data.data[ i ] = ent:GetPhysicsObjectNum( i ):GetMeshConvexes() or {}
		end

		data = util.TableToJSON( data )

		local compressed_data = util.Compress( data )
		if ( !compressed_data ) then compressed_data = data end

		local len = string.len( compressed_data )
		local send_size = 60000
		local parts = math.ceil( len / send_size )

		local start = 0
		for i = 1, parts do

			local endbyte = math.min( start + send_size, len )
			local size = endbyte - start

			net.Start( "rb655_inspector_physicsinfo" )
				net.WriteBool( i == parts )

				net.WriteUInt( size, 16 )
				net.WriteData( compressed_data:sub( start + 1, endbyte + 1 ), size )
			net.Send( ply )

			start = endbyte
		end

	end )
else
	local gMeshCache = {}

	net.Receive( "rb655_inspector_genericinfo", function()
		local ent = net.ReadEntity()
		if ( !IsValid( ent ) ) then return end

		ent.InspectorMapID = net.ReadInt( 32 )
		ent.InspectorName = net.ReadString()
		ent.InspectorMass = net.ReadInt( 32 )
		ent.InspectorMat = net.ReadString()

		local mdl = ent:GetClass() .. "_" .. ent:GetModel()
		if ( !gMeshCache[ mdl ] ) then
			net.Start( "rb655_inspector_reqinfo" )
				net.WriteEntity( ent )
			net.SendToServer()
		else
			ent.InspectorMeshes = gMeshCache[ mdl ]
		end
	end )

	local buffer = ""
	net.Receive( "rb655_inspector_physicsinfo", function()

		local done = net.ReadBool()

		local len = net.ReadUInt( 16 )
		local data = net.ReadData( len )

		buffer = buffer .. data

		if ( !done ) then return end

		local uncompressed = util.Decompress( buffer )

		if ( !uncompressed ) then // We send the uncompressed data if we failed to compress it
			print( "Easy Entity Inspector: Failed to decompress the buffer!" )
			uncompressed = buffer
		end

		buffer = ""

		local data = util.JSONToTable( uncompressed )
		if ( !data ) then print( "Easy Entity Inspector: Failed to JSON to table!" ) return end

		local mdl = data.class .. "_" .. data.model

		if ( !gMeshCache[ mdl ] ) then gMeshCache[ mdl ] = {} end

		gMeshCache[ mdl ] = data.data

		if ( !IsValid( Entity( data.entid ) ) ) then return end

		Entity( data.entid ).InspectorMeshes = gMeshCache[ mdl ]

	end )
end

// Send some serverside info to the client
function TOOL:SendEntityInfo( ent )
	if ( !IsValid( ent ) || CLIENT ) then return end

	// Save the set values for later use
	ent.InspectorMapID = ent.MapCreationID && ent:MapCreationID() or -1
	ent.InspectorName = ent.GetName && ent:GetName() or ""
	ent.InspectorMass = IsValid( ent:GetPhysicsObject() ) && ent:GetPhysicsObject():GetMass() or 0
	ent.InspectorMat = IsValid( ent:GetPhysicsObject() ) && ent:GetPhysicsObject():GetMaterial() or ""

	net.Start( "rb655_inspector_genericinfo" )
		net.WriteEntity( ent )
		net.WriteInt( ent.InspectorMapID, 32 )
		net.WriteString( ent.InspectorName )
		net.WriteInt( ent.InspectorMass, 32 )
		net.WriteString( ent.InspectorMat )
	net.Send( self:GetOwner() )
end

function TOOL:SetSelectedEntity( ent, tr )
	if ( IsValid( ent ) and ent:GetClass() == "prop_effect" ) then ent = ent.AttachedEntity end
	if ( !IsValid( ent ) ) then ent = NULL end

	if ( tr && IsValid( ent ) ) then
		ent:SetNWVector( "LocalPos", ent:WorldToLocal( tr.HitPos ) )
		ent:SetNWVector( "LocalDir", tr.HitNormal )
	end

	if ( tr ) then
		Entity( 0 ):SetNWVector( "LocalPos2", tr.HitPos )
		Entity( 0 ):SetNWVector( "LocalDir2", tr.HitNormal )
	end

	if ( self:GetSelectedEntity() == ent ) then return end

	self:SendEntityInfo( ent )

	self:GetWeapon():SetNWEntity( "rb655_attachments_entity", ent )
end

function TOOL:LeftClick( tr )
	if ( SERVER ) then self:SetSelectedEntity( tr.Entity, tr ) end
	return true
end

function TOOL:RightClick( tr )
	if ( SERVER ) then
		if ( self:GetOwner():KeyDown( IN_USE ) ) then self:NextSelecetedFunc( -1 ) else

		self:NextSelecetedFunc( 1 ) end
	end
	self:GetWeapon():EmitSound( "weapons/pistol/pistol_empty.wav", 100, math.random( 50, 150 ) ) -- YOOOOY
	return false
end

function TOOL:Think()
	local ent = self:GetSelectedEntity()

	if ( CLIENT || !IsValid( ent ) ) then return end

	local InspectorMapID = ent.MapCreationID && ent:MapCreationID() or -1
	local InspectorName = ent.GetName && ent:GetName() or ""
	local InspectorMass = IsValid( ent:GetPhysicsObject() ) && ent:GetPhysicsObject():GetMass() or 0
	local InspectorMat = IsValid( ent:GetPhysicsObject() ) && ent:GetPhysicsObject():GetMaterial() or ""

	if ( ent.InspectorMapID != InspectorMapID || ent.InspectorName != InspectorName || ent.InspectorMass != InspectorMass || ent.InspectorMat != InspectorMat ) then
		self:SendEntityInfo( ent ) // Updaet eet!
	end
end

function TOOL:Reload( tr )
	if ( self:GetOwner():KeyDown( IN_USE ) ) then self:SetSelectedEntity( self:GetOwner():GetViewModel() ) return true end
	if ( SERVER ) then self:SetSelectedEntity( self:GetOwner() ) end
	return true
end

if ( SERVER ) then return end

language.Add( "tool.rb655_easy_inspector.name", "Entity Inspector" )
language.Add( "tool.rb655_easy_inspector.desc", "Shows all available information about selected entity" )

language.Add( "tool.rb655_easy_inspector.noglow", "Don't render glow/halo around models" )
language.Add( "tool.rb655_easy_inspector.lp", "Don't render on yourself in first person" )
language.Add( "tool.rb655_easy_inspector.names", "Show labels ( where applicable )" )
language.Add( "tool.rb655_easy_inspector.dir", "Show directions ( where applicable )" )
language.Add( "tool.rb655_easy_inspector.hook", "Render when tool is holstered" )
language.Add( "tool.rb655_easy_inspector.units", "Units ( Speed units )" )

language.Add( "unit.units", "Units ( units/s )" )
language.Add( "unit.km", "Kilometres ( km/h )" )
language.Add( "unit.meter", "Meters ( m/s )" )
language.Add( "unit.cm", "Centimetres ( cm/s )" )
language.Add( "unit.miles", "Miles ( mp/h )" )
language.Add( "unit.inch", "Inches ( inch/s )" )
language.Add( "unit.foot", "Feet ( foot/s )" )

local function TextField( panel, func, tooltip, noent )
	local text = vgui.Create( "DTextEntry", panel )
	text:SetTall( 20 )
	if ( tooltip ) then text:SetTooltip( tooltip ) end
	function text:Think()
		if ( self.icon ) then self.icon:SetPos( self:GetWide() - 17, 2 ) end
		if ( self:IsEditing() ) then return end
		local tool = LocalPlayer().GetTool && LocalPlayer():GetTool( "rb655_easy_inspector" )
		if ( !tool || !tool.GetSelectedEntity ) then return end
		local ent = tool:GetSelectedEntity()
		if ( IsValid( ent ) || noent ) then func( self, ent ) else self:SetValue( "" ) end
	end

	local icon = vgui.Create( "DImageButton", text )
	icon:SetIcon( "icon16/page.png" )
	icon:SetTooltip( "Copy to clipboard" )
	icon:SetSize( 16, 16 )
	function icon:DoClick()
		SetClipboardText( text:GetValue() )
	end
	text.icon = icon

	panel:AddItem( text )

	return text
end

list.Set( "RB_EI_UNITS", "#unit.units", { rb655_easy_inspector_units = 0 } )
list.Set( "RB_EI_UNITS", "#unit.km", { rb655_easy_inspector_units = 1 } )
list.Set( "RB_EI_UNITS", "#unit.meter", { rb655_easy_inspector_units = 2 } )
list.Set( "RB_EI_UNITS", "#unit.cm", { rb655_easy_inspector_units = 3 } )
list.Set( "RB_EI_UNITS", "#unit.miles", { rb655_easy_inspector_units = 4 } )
list.Set( "RB_EI_UNITS", "#unit.inch", { rb655_easy_inspector_units = 5 } )
list.Set( "RB_EI_UNITS", "#unit.foot", { rb655_easy_inspector_units = 6 } )

function TOOL.BuildCPanel( panel, ent )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.noglow", Command = "rb655_easy_inspector_noglow" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.lp", Command = "rb655_easy_inspector_lp" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.names", Command = "rb655_easy_inspector_names" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.dir", Command = "rb655_easy_inspector_dir" } )
	panel:AddControl( "Checkbox", { Label = "#tool.rb655_easy_inspector.hook", Command = "rb655_easy_inspector_hook" } )

	panel:AddControl( "ComboBox", { Label = "#tool.rb655_easy_inspector.units", Options = list.Get( "RB_EI_UNITS" ) } )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( "[" .. game.GetWorld():EntIndex() .. " | -1] " .. game.GetWorld():GetClass() ) return end
		self:SetValue( "[" .. ent:EntIndex() .. " | " .. (ent.InspectorMapID or -1) .. "] " .. ent:GetClass() )
	end, "[EntIndex | MapCreationID] Entity class", true )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( game.GetWorld():GetModel() ) return end
		self:SetValue( ent:GetModel() )
	end, "Entity model", true )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then self:SetValue( LocalPlayer():GetEyeTrace().HitTexture ) return end
		self:SetValue( ent:GetMaterial() )
	end, "Entity material\nOr hit texture", true )

	TextField( panel, function( self, ent )
		local pos = ent:GetPos()
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity position" )

	TextField( panel, function( self, ent )
		local ang = ent:GetAngles()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Entity angles" )

	TextField( panel, function( self, ent )
		local c = ent:GetColor()
		self:SetValue( "Color( " .. c.r  .. ", " .. c.g .. ", " .. c.b .. ", " .. c.a .. " )" )
	end, "Entity color" )

	TextField( panel, function( self, ent )
		local pos = !IsValid( ent ) && Entity( 0 ):GetNWVector( "LocalPos2" ) or ent:GetNWVector( "LocalPos" )
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity:WorldToLocal result of last clicked position on the entity", true )

	TextField( panel, function( self, ent )
		local ang = !IsValid( ent ) && Entity( 0 ):GetNWVector( "LocalDir2" ):Angle() or ent:GetNWVector( "LocalDir" ):Angle()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Hit direction of last clicked position on the entity", true )

	TextField( panel, function( self, ent )
		local pos = LocalPlayer():GetEyeTrace().HitPos
		if ( IsValid( ent ) ) then pos = ent:WorldToLocal( pos ) end
		self:SetValue( "Vector( " .. math.floor( pos.x * 100 ) / 100 .. ", " .. math.floor( pos.y * 100 ) / 100 .. ", " .. math.floor( pos.z * 100 ) / 100 .. " )" )
	end, "Entity:WorldToLocal result of position you are looking at\nOr simply aim position", true )

	TextField( panel, function( self, ent )
		local ang = LocalPlayer():GetEyeTrace().HitNormal:Angle()
		self:SetValue( "Angle( " .. math.floor( ang.p * 100 ) / 100 .. ", " .. math.floor( ang.y * 100 ) / 100 .. ", " .. math.floor( ang.r * 100 ) / 100 .. " )" )
	end, "Direction of position you are looking at", true )

	TextField( panel, function( self, ent )
		if ( !ent:GetSkin() ) then self:SetValue( "" ) return end
		self:SetValue( "ent:SetSkin( " .. ent:GetSkin() .. " )" )
	end, "Entity skin" )

	TextField( panel, function( self, ent )
		self:SetValue( ent.InspectorMass or "" )
	end, "Entity mass" )

	TextField( panel, function( self, ent )
		self:SetValue( ent.InspectorName or "" )
	end, "Entity target name" )

	TextField( panel, function( self, ent )
		if ( !IsValid( ent ) ) then
			local tr = LocalPlayer():GetEyeTrace()
			self:SetValue( util.GetSurfacePropName( tr.SurfaceProps ) .. " ( " .. tr.SurfaceProps .. ", " .. tr.MatType .. " )" )
		return end
		self:SetValue( ent.InspectorMat or "" )
	end, "Entity physical material\nOr physical material of whatever you are looking at ( Surface property ID, Material Type )", true )

	local lastUpdate = 0
	TextField( panel, function( self, ent )
		if ( lastUpdate > CurTime() ) then return end
		lastUpdate = CurTime() + 1

		if ( !IsValid( ent ) || !ent:GetBodyGroups() ) then self:SetHeight( 20 ) self:SetValue( "" ) return end

		local str = ""
		local num = 0

		for i, t in pairs( ent:GetBodyGroups() ) do
			if ( t.num < 2 ) then continue end
			if ( str != "" ) then str = str .. "\n" end

			num = num + 1

			str = Format( "%s%s ( %s ) - %s ( %s )", str, t.name, t.id, ent:GetBodygroup( t.id ), ent:GetBodygroupCount( t.id ) - 1 )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) // Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity bodygroups: name ( id ) - value ( max value )", true )

	local lastUpdate2 = 0
	TextField( panel, function( self, ent )
		if ( lastUpdate2 > CurTime() ) then return end
		lastUpdate2 = CurTime() + .1

		if ( !IsValid( ent ) || !ent:GetNumPoseParameters() || ent:GetNumPoseParameters() < 1 ) then self:SetHeight( 20 ) self:SetValue( "" ) return end

		local str = ""

		for i = 0, ent:GetNumPoseParameters() - 1 do
			local name = ent:GetPoseParameterName( i )
			local min, max = ent:GetPoseParameterRange( i )

			if ( str != "" ) then str = str .. "\n" end
			str = str .. Format( "%s: %s ( %s, %s )", name, math.floor( ent:GetPoseParameter( name ) * 1000 ) / 1000, math.floor( min * 1000 ) / 1000, math.floor( max * 1000 ) / 1000 )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) // Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity poseparameters - name: value ( min, max )", true )

	local lastUpdate3 = 0
	TextField( panel, function( self, ent )
		if ( lastUpdate3 > CurTime() ) then return end
		lastUpdate3 = CurTime() + 10

		if ( !IsValid( ent ) ) then ent = Entity( 0 ) end

		local str = ""

		for k, v in pairs( ent:GetMaterials() ) do
			if ( str != "" ) then str = str .. "\n" end
			str = str .. Format( "[%s] %s", k, v )
		end

		self:SetValue( str )
		self:SetMultiline( true )

		surface.SetFont( self:GetFont() )
		local w, h = surface.GetTextSize( "a" ) // Get height of 1 character
		self:SetHeight( math.max( ( h + 1 ) * #string.Explode( "\n", str ) + 3, 20 ) )
	end, "Entity sub materials - [id] path", true )

end

surface.CreateFont( "rb655_inspector_menu", {
	size = 36,
	font = "Verdana",
	antialias = true
} )

function TOOL:DrawToolScreen( sw, sh )
	local w = 10
	local h = 10
	local lineH = 0

	-- Anybody, a better way?
	for id, t in pairs( InfoFuncs ) do
		surface.SetFont( "rb655_inspector_menu" )
		local tw, th = surface.GetTextSize( t.name )
		w = math.max( tw + 10, w )
		h = h + th
		lineH = th
	end

	local x = 0
	local y = ( sh - h ) / 2 + math.cos( self:GetSelectedFunc() / #InfoFuncs * math.pi ) * ( h - sh ) / 2

	draw.RoundedBox( 4, 0, 0, sw, sh, Color( 0, 0, 0, 255 ) )

	for id, t in pairs( InfoFuncs ) do
		if ( id == self:GetSelectedFunc() ) then
			local clr = HSVToColor( 0, 0, 0.4 + math.sin( CurTime() * 4 ) * 0.1 )
			draw.RoundedBox( 0, 0, y + 5 + ( id - 1 ) * lineH, sw, lineH, clr )

			local a = surface.GetTextSize( t.name )
			if ( a > ( sw - 10 ) ) then
				x = -a + math.fmod( CurTime() * sw, sw + a )
			end
		else
			x = 0
		end
		draw.SimpleText( t.name, "rb655_inspector_menu", x + 5, y + 5 + ( id - 1 ) * lineH, Color( 255, 255, 255 ) )
	end
end

hook.Add( "HUDPaint", "rb655_easy_inspector", function()
	if ( GetConVarNumber( "rb655_easy_inspector_hook" ) < 1 || !LocalPlayer().GetTool ) then return end

	local wep = LocalPlayer():GetTool( "rb655_easy_inspector" )
	if ( !wep ) then return end
	wep:DrawHUD( true )
end )

surface.CreateFont( "rb655_attachment", {
	size = ScreenScale( 6 ),
	font = "Verdana",
	outline = true,
	antialias = true
} )

function TOOL:DrawHUD( b )

	/* THE HALO */
	local ent = self:GetSelectedEntity()

	if ( IsValid( ent ) && LocalPlayer():ShouldDrawLocalPlayer() && ent:GetClass() == "viewmodel" ) then ent = LocalPlayer():GetActiveWeapon() end

	if ( !IsValid( ent ) ) then

		/* THE WORLD FUNCS, These only work when we do not have an entity selected and only with world flag */
		if ( !InfoFuncs[ self:GetSelectedFunc() ].world ) then return end

		/*if ( InfoFuncs[ self:GetSelectedFunc() ].check ) then
			local check = InfoFuncs[ self:GetSelectedFunc() ].check()
			if ( check ) then
				local pos = ent:LocalToWorld( ent:OBBCenter() ):ToScreen()

				//if ( !tobool( self:GetClientNumber( "names" ) ) ) then return end

				draw.SimpleText( check, "rb655_attachment", pos.x, pos.y, Color( 255, 100, 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

				return
			end
		end*/
		InfoFuncs[ self:GetSelectedFunc() ].func( Entity( 0 ), tobool( self:GetClientNumber( "names" ) ), tobool( self:GetClientNumber( "dir" ) ) )

	return end

	if ( !tobool( self:GetClientNumber( "noglow" ) ) ) then
		local t = {}

		if ( IsValid( ent ) ) then table.insert( t, ent ) end

		if ( IsValid( ent ) && ent.GetActiveWeapon ) then table.insert( t, ent:GetActiveWeapon() ) end

		halo.Add( t, HSVToColor( ( CurTime() * 3 ) % 360, math.abs( math.sin( CurTime() / 2 ) ), 1 ), 2, 2, 1 )
	end

	/* THE ENTITY FUNCS */
	if ( !LocalPlayer():ShouldDrawLocalPlayer() && ent == LocalPlayer() && tobool( self:GetClientNumber( "lp" ) ) ) then return end

	if ( InfoFuncs[ self:GetSelectedFunc() ].check ) then
		local check = InfoFuncs[ self:GetSelectedFunc() ].check( ent )
		if ( check ) then
			local pos = ent:LocalToWorld( ent:OBBCenter() ):ToScreen()

			//if ( !tobool( self:GetClientNumber( "names" ) ) ) then return end

			draw.SimpleText( check, "rb655_attachment", pos.x, pos.y, Color( 255, 100, 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			return
		end
	end

	InfoFuncs[ self:GetSelectedFunc() ].func( ent, tobool( self:GetClientNumber( "names" ) ), tobool( self:GetClientNumber( "dir" ) ) )

end
