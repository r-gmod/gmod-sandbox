if SERVER then
	util.AddNetworkString( "ZeagaPlayerAttendance" )
	hook.Add( "PlayerInitialSpawn", "ZeagaPlayerJoin", function( ply )
		net.Start( "ZeagaPlayerAttendance" ) -- We send the team/name and not the entity because it may not yet exist on the clients.
			net.WriteBool( true )
			net.WriteUInt( ply:Team( ), 10 )
			net.WriteString( ply:Name( ) )
		net.Broadcast( )
	end )
	hook.Add( "PlayerDisconnected", "ZeagaPlayerLeave", function( ply )
		net.Start( "ZeagaPlayerAttendance" )
			net.WriteBool( false )
			net.WriteUInt( ply:Team( ), 10 )
			net.WriteString( ply:Name( ) )
		net.Broadcast( )
	end )
end

if CLIENT then
	local TYPE_SPAWN 		= 1
	local TYPE_DISCONNECT	= 2

	local tblAttendenceSounds = {
		[TYPE_SPAWN] = {
			"garrysmod/save_load1.wav",
			"garrysmod/save_load4.wav",
		},
		[TYPE_DISCONNECT] = {
			"garrysmod/save_load2.wav",
			"garrysmod/save_load3.wav",
		}
	}
	net.Receive( "ZeagaPlayerAttendance", function( length )
		local bArriving = net.ReadBool 	 ()
		local iTeamId	= net.ReadUInt	 ( 10 )
		local strName	= net.ReadString ()

		local iEventType = bArriving and TYPE_SPAWN or TYPE_DISCONNECT

		if bArriving then
			chat.AddText (
				team.GetColor( iTeamId ),
				strName,
				Color( 255, 255, 255 ),
				" has spawned in the server!"
			)
		else
			chat.AddText (
				team.GetColor( iTeamId ),
				strName,
				Color( 255, 255, 255 ),
				" has left the server!"
			)
		end

		local tblSounds = tblAttendenceSounds [iEventType]
		surface.PlaySound (tblSounds [math.random (1, #tblSounds)])

	end )
end
