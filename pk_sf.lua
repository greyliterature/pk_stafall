--@name pk
--@author ```scripture
--@shared

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
    local prop_cham_mat = "models/wireframe"
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
    if player() == owner() then
        enableHud(owner(), true)
        
        local AccountedForPlayers = {}
        --[[
        -- this doesnt work somehow
        hook.add("NetworkEntityCreated", "RetrackNewlyValidPlayers", function(ent)
            if not ent:isPlayer() then return end
            AccountedForPlayers[ent] = nil
        end)
        --]]
        hook.add("PostDrawPlayer", "DevBox", function(ply, flags)
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
            for _, ply in ipairs(find.allPlayers()) do
                --if ply:getSteamID() ~= "76561199851758072" then continue end
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
            for _, ply in ipairs(find.allPlayers()) do
                ply:setMaterial(player_cham_mat) -- have to always set their material, because theres seemingly no way to only set it once on EnterPVS
                ply:setColor(cham_color)
            end
        end)
        hook.add("Removed", "ResetChams", function()
            for _, ply in ipairs(find.allPlayers()) do
                ply:setMaterial("")
                ply:setColor(color_white) 
            end
        end)
        --[[-----------------------------------------
            Prop ESP
        --]]-----------------------------------------
        hook.add("OnEntityCreated", "prop_chams", function(ent)
            if not isValid(ent) then return end
            if ent:getClass() ~= "prop_physics" then return end
            if timer.getTimersLeft() == 0 then return end
            timer.simple(0.1, function()
                if not isValid(ent) then return end
                ent:setMaterial(prop_cham_mat)
                ent:setColor(prop_color)
            end)
        end)
    end
end
