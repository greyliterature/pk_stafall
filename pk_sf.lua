--@name shared pk esp
--@shared

--[[-----------------------------------------
    Tracking table
--]]-----------------------------------------
local players = {}

if CLIENT then
    --[[-----------------------------------------
        Settings
    --]]-----------------------------------------
    --
    --[[--]]--
    -- colors
    -- players
    local nick_color = Color(170, 0, 0)
    local box_color = Color(128, 255, 0)
    local cham_color = Color(0, 170, 0)
    -- props
    local prop_color = Color(0, 170, 0, 170)
    --[[--]]--
    -- fonts
    local nick_font = "TargetIDSmall"
    --
    --[[--]]--
    -- chams
    -- players
    local player_cham_mat = "debug/debugportals"
    -- props
    local prop_cham_mat = "models/debug/debugwhite"
    --
    --[[--]]--
    -- fps saving things
    local min_dot = 0.95
    local max_players_in_dot = 5
    local min_strict_dot = 0.999
    
    --[[-----------------------------------------
        Player ESP
    --]]-----------------------------------------
    local color_white = Color(255,255,255)
    local ang_zero = Angle(0, 0, 0)
    --[[
    -- this doesnt work somehow
    hook.add("NetworkEntityCreated", "RetrackNewlyValidPlayers", function(ent)
        if not ent:isPlayer() then return end
        AccountedForPlayers[ent] = nil
    end)
    --]]
    local function RunThings()
        hook.add("PostDrawPlayer", "DevBox", function(ply, flags)
            if not players[ply] then return end
            local m = Matrix()
            render.pushMatrix(m)
            render.setColor(box_color)
            local mins, maxs = ply:obbMins(), ply:obbMaxs()
            render.draw3DWireframeBox(ply:getPos(), ang_zero, mins, maxs, true)
            render.draw3DWireframeBox(ply:getPos(), ang_zero, mins, maxs, false) -- another one to fix Z write issues
            render.popMatrix()
        end)
      hook.add("DrawHUD", "Nicks", function()
            local playersindot = 0 
            for ply, _ in pairs(players) do
                if ply == player() then continue end
                local DistToTarg = (ply:getPos() - player():getShootPos()):getNormalized()
                local dot = player():getAimVector():dot(DistToTarg)
                if dot > min_dot then
                    playersindot = playersindot + 1  
                end
                if playersindot > max_players_in_dot then 
                    if dot < min_strict_dot then
                        continue
                    end
                end 
                local toscreen = (ply:getPos()):toScreen()
                local nick = ply:getName()
                if #nick > 15 then 
                    nick = string.sub(nick, 1, 15) .. "..."
                end 
                render.setFont(nick_font)
                render.setColor(nick_color)
                render.drawSimpleText(toscreen.x, toscreen.y, nick, TEXT_ALIGN.CENTER) 
            end
        end)
        
        hook.add("Think", "Chams", function()
            if render.isHUDActive() ~= true then return end
            for ply, _ in pairs(players) do
                ply:setMaterial(player_cham_mat) -- have to always set their material, because theres seemingly no way to only set it once on EnterPVS
                ply:setColor(cham_color)
            end
        end)
        
        hook.add("Removed", "ResetChams", function()
            for _, ent in ipairs(find.all()) do
                ent:setMaterial("")
                ent:setColor(color_white)
            end
        end)
        
        hook.add("HUDDisconnected", "ResetChams", function(ent, ply)
            for _, ent in ipairs(find.all()) do
                if not isValid(ent) then continue end
                ent:setMaterial("")
                ent:setColor(color_white)
            end
        end)
        --[[-----------------------------------------
            Prop ESP
        --]]-----------------------------------------
        hook.add("OnEntityCreated", "prop_chams", function(ent)
            if not isValid(ent) then return end
            if ent:getClass() ~= "prop_physics" then return end
            if ent:getOwner() and not players[ent:getOwner()] then return end
            if timer.getTimersLeft() == 0 then return end
            timer.simple(0, function()
                if not isValid(ent) then return end
                ent:setMaterial(prop_cham_mat)
                ent:setColor(prop_color)
            end)
        end)
        --[[
        hook.add("HUDConnected", "AddPlayerToTrack", function(ent, ply)
            if ply == player() then printHud("HI TEST AAA") end
            players[ply] = true
        end)
        --]]
        --printHud("hi test", table.count(players))
    end

    if player() == owner() then
        enableHud(owner(), true)
        RunThings()
    end
    net.receive("UpdateTrackingTable", function()
        local numkeys = net.readUInt(32)
        players = {}
        for i = 1, numkeys do
            players[net.readEntity()] = true
        end
        for _, ply in ipairs(find.allPlayers()) do
            if not players[ply] then
                ply:setMaterial("")
                ply:setColor(color_white)
            end 
        end
    end)
    
    hook.add("HUDConnected", "RunThings", function(ent, ply)
        if ply == player() then
            printHud(table.count(players))
            RunThings() 
        end
    end)
elseif SERVER then 
    local hud = prop.createComponent(chip():getPos(), Angle(0,0,0), "starfall_hud", "models/hunter/blocks/cube1x1x1.mdl", true)
    hud:linkComponent(chip())
    hook.add("HudConnected", "AddPlayerToTrack", function(ent, ply)
        players[ply] = true
        local numkeys = table.count(players)
        for ply, _ in pairs(players) do 
            net.start("UpdateTrackingTable")
            net.writeUInt(numkeys, 32)
            for plyy, _ in pairs(players) do
                net.writeEntity(plyy)
            end
            net.send(ply)
        end
    end)
    hook.add("HUDDisconnected", "RemovePlayerToTrack", function(ent, ply)
        players[ply] = nil
        local numkeys = table.count(players)
        for ply, _ in pairs(players) do 
            net.start("UpdateTrackingTable")
            net.writeUInt(numkeys, 32)
            for plyy, _ in pairs(players) do
                net.writeEntity(plyy)
            end
            net.send(ply)
        end
    end)
end
