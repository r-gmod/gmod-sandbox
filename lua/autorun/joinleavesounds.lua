if SERVER then
	util.AddNetworkString( "ZeagaPlayerJoin" )
	hook.Add( "PlayerInitialSpawn", "ZeagaPlayerJoin", function( ply )
		net.Start( "ZeagaPlayerJoin" ) -- We send the team/name and not the entity because it may not yet exist on the clients.
			net.WriteUInt( ply:Team( ), 4 )
			net.WriteString( ply:Name( ) )
		net.Broadcast( )
	end )
	util.AddNetworkString( "ZeagaPlayerLeave" )
	hook.Add( "PlayerDisconnected", "ZeagaPlayerLeave", function( ply )
		net.Start( "ZeagaPlayerLeave" )
			net.WriteUInt( ply:Team( ), 4 )
			net.WriteString( ply:Name( ) )
		net.Broadcast( )
	end )
end

if CLIENT then
	local joinSounds = {
		"garrysmod/save_load1.wav",
		"garrysmod/save_load4.wav",
	}
	net.Receive( "ZeagaPlayerJoin", function( length )
		chat.AddText( team.GetColor( net.ReadUInt( 4 ) ),net.ReadString( ), Color( 255, 255, 255 ), " has spawned in the server!" )
		surface.PlaySound( table.Random( joinSounds ) )
	end )
	local leaveSounds = {
		"garrysmod/save_load2.wav",
		"garrysmod/save_load3.wav",
	}
	net.Receive( "ZeagaPlayerLeave", function( length )
		chat.AddText( team.GetColor( net.ReadUInt( 4 ) ), net.ReadString( ), Color( 255, 255, 255 ), " has left the server!" )
		surface.PlaySound( table.Random( leaveSounds ) )
	end )
end
