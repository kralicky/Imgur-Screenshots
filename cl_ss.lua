-- Create a Client-ID for your account: https://api.imgur.com/oauth2/addclient
local CLIENT_ID = ""

local capturing = false
local inprogress = false
local fr
function StartCapturing()
	if fr then
		return
	end
	fr = vgui.Create( "DFrame" )
	fr:MakePopup()
	fr:SetPos( 0, 0 )
	fr:SetSize( ScrW(), ScrH() )
	fr:SetDraggable( false )
	fr:SetTitle( " " )
	fr:ShowCloseButton( false )
	function fr:Paint()
	end
	function fr:OnClose()
		self:Remove()
		fr = nil
	end
	function fr:Think()
		fr:SetCursor( "crosshair" )
	end
	capturing = true
end
function CaptureImage( startpos, endpos )
	local v1x = math.min( startpos.x, endpos.x )
	local v1y = math.min( startpos.y, endpos.y )
	local v2x = math.max( startpos.x, endpos.x )
	local v2y = math.max( startpos.y, endpos.y )
	local distx = v2x - v1x
	local disty = v2y - v1y
	local capture = {
		format = "jpeg",
		h = disty,
		w = distx,
		quality = 90,
		x = v1x,
		y = v1y
	}
	if capture.h <= 5 or capture.w <= 5 then
		chat.AddText( Color( 255, 0, 0 ), "Upload failed - Image must be greater than 5x5 px" )
		inprogress = false			
		return
	end
	local data = util.Base64Encode( render.Capture( capture ) )
	local params = {
		[ "image" ] = data,
		[ "type" ] = "base64"
	}
	local tab = {
		[ "failed" ] = 
			function()
				print( "Upload failed!" )
			end,
		[ "success" ] =
			function( status, response, headers )
				local res = util.JSONToTable( response )
				chat.AddText( Color( 0, 255, 0 ), "Upload success - URL Copied to clipboard" )
				inprogress = false
				SetClipboardText( res.data.link )
				surface.PlaySound( "garrysmod/content_downloaded.wav" )
			end,
		[ "method" ] =
			"post",
		[ "url" ] =
			"https://api.imgur.com/3/upload",
		[ "parameters" ] =
			params,
		[ "headers" ] =
			{ 
				[ "Authorization" ] = "Client-ID " .. CLIENT_ID 
			}
	}
	HTTP( tab )
	chat.AddText( color_white, "Starting image upload (" .. distx .. "x" .. disty .. ")" )
end
local cappin
local startpos
local endpos
hook.Add( "Think", "CheckMouseClicks", function()
	if input.IsKeyDown( KEY_4 ) then
		if input.IsKeyDown( KEY_LSHIFT ) and input.IsKeyDown( KEY_LALT ) then
			if inprogress == false then
				inprogress = true
				if not capturing then
					StartCapturing()
				else
					inprogress = false
				end
			end
		end
	elseif input.IsKeyDown( KEY_3 ) then	
		if input.IsKeyDown( KEY_LSHIFT ) and input.IsKeyDown( KEY_LALT ) then
			if inprogress == false then
				inprogress = true
				CaptureImage( Vector( 0, 0 ), Vector( ScrW(), ScrH() ) )
			end
		end
	end
	if not capturing then
		return
	end
	if input.IsMouseDown( MOUSE_LEFT ) and not cappin then
		cappin = true
		local p, p2 = input.GetCursorPos()
		startpos = { x = p, y = p2 }
	elseif not input.IsMouseDown( MOUSE_LEFT ) and cappin then
		cappin = false
		local p, p2 = input.GetCursorPos()
		endpos = { x = p, y = p2 }
		capturing = false
		fr:Close()
		timer.Simple( 0.1, function()
			CaptureImage( startpos, endpos )
			startpos = nil			
		end )
	end
end )
function math.n( num )
	return -num
end
function surface.DrawVectorRect( pos1, pos2 )
	local pos1x = pos1.x
	local pos1y = pos1.y
	local pos2x = pos2.x
	local pos2y = pos2.y
	local distx
	local disty		
	if pos1x - pos2x < 0 then
		distx = pos2x - pos1x 
	else
		distx = math.n( pos1x - pos2x )
	end
	if pos1y - pos2y < 0 then
		disty = pos2y - pos1y
	else
		disty = math.n( pos1y - pos2y )
	end		
	if disty < 0 and distx < 0 then
		pos1x, pos1y = input.GetCursorPos()
		distx, disty = math.abs( distx ), math.abs( disty )
	elseif distx < 0 and disty > 0 then
		pos1x = input.GetCursorPos()
		distx = math.abs( distx )
	elseif disty < 0 and distx > 0 then
		_, pos1y = input.GetCursorPos()
		disty = math.abs( disty )
	end			
	return surface.DrawRect( pos1x, pos1y, distx, disty )
end
function surface.DrawOutlinedVectorRect( pos1, pos2 )
	local pos1x = pos1.x
	local pos1y = pos1.y
	local pos2x = pos2.x
	local pos2y = pos2.y
	local distx
	local disty		
	if pos1x - pos2x < 0 then
		distx = pos2x - pos1x 
	else
		distx = math.n( pos1x - pos2x )
	end
	if pos1y - pos2y < 0 then
		disty = pos2y - pos1y
	else
		disty = math.n( pos1y - pos2y )
	end		
	if disty < 0 and distx < 0 then
		pos1x, pos1y = input.GetCursorPos()
		distx, disty = math.abs( distx ), math.abs( disty )
	elseif distx < 0 and disty > 0 then
		pos1x = input.GetCursorPos()
		distx = math.abs( distx )
	elseif disty < 0 and distx > 0 then
		_, pos1y = input.GetCursorPos()
		disty = math.abs( disty )
	end			
	return surface.DrawOutlinedRect( pos1x, pos1y, distx, disty )
end
hook.Add( "HUDPaint", "DrawCap", function()
	if capturing then
		if startpos then
			local px, py = input.GetCursorPos()
			surface.SetDrawColor( 0, 0, 0, 220 )
			surface.DrawOutlinedVectorRect( Vector( startpos.x, startpos.y ), Vector( px, py ) )			
			surface.SetDrawColor( 255, 255, 255, 45 )
			surface.DrawVectorRect( Vector( startpos.x, startpos.y ), Vector( px, py ) )
		end
	end
end )