property pBottomBarId, pCarriedPowerupType, pCarriedPowerupId, pUpdateCounter, pCarriedPowerupTimeToLive

on construct me 
  pUpdateCounter = 0
  pCarriedPowerupId = 0
  pCarriedPowerupType = 0
  pCarriedPowerupTimeToLive = 0
  pBottomBarId = "RoomBarID"
  registerMessage(#roomReady, me.getID(), #replaceRoomBar)
  return TRUE
end

on deconstruct me 
  unregisterMessage(#roomReady, me.getID())
  removeWindow(pBottomBarId)
  return TRUE
end

on Refresh me, tTopic, tdata 
  if (tTopic = #bb_event_1) then
    if (pCarriedPowerupType = 0) then
      return TRUE
    end if
    if (tdata.getAt(#id) = pCarriedPowerupId) then
      return(me.clearBottomBarPowerup())
    end if
  else
    if (tTopic = #bb_event_3) then
      tGameSystem = me.getGameSystem()
      if (tGameSystem = 0) then
        return FALSE
      end if
      if tGameSystem.getSpectatorModeFlag() then
        return TRUE
      end if
      if tdata.getAt(#playerId) <> me.getOwnGameIndex() then
        return TRUE
      end if
      pCarriedPowerupId = tdata.getAt(#powerupid)
      pCarriedPowerupType = tdata.getAt(#powerupType)
      pCarriedPowerupTimeToLive = tGameSystem.getGameObjectProperty(pCarriedPowerupId, #timetolive)
      receiveUpdate(me.getID())
      me.setActivateButton(pCarriedPowerupType)
    else
      if (tTopic = #bb_event_5) then
        tGameSystem = me.getGameSystem()
        if (tGameSystem = 0) then
          return FALSE
        end if
        if me.getGameSystem().getSpectatorModeFlag() then
          return TRUE
        end if
        if tdata.getAt(#playerId) <> me.getOwnGameIndex() then
          return TRUE
        end if
        return(me.clearBottomBarPowerup())
      else
        if (tTopic = #gameend) then
          return(me.clearBottomBarPowerup())
        else
          if (tTopic = #setfxicon) then
            return(me.setfxicon(tdata))
          else
            if (tTopic = #setmusicicon) then
              return(me.setmusicicon(tdata))
            end if
          end if
        end if
      end if
    end if
  end if
  return TRUE
end

on update me 
  pUpdateCounter = (pUpdateCounter + 1)
  if pUpdateCounter < 2 then
    return TRUE
  end if
  pUpdateCounter = 0
  if pCarriedPowerupTimeToLive > 0 then
    me.animatePowerupTimer()
  end if
end

on animatePowerupTimer me 
  tObjectTimeToLive = me.getGameSystem().getGameObjectProperty(pCarriedPowerupId, #timetolive)
  if (tObjectTimeToLive = pCarriedPowerupTimeToLive) then
    return TRUE
  end if
  pCarriedPowerupTimeToLive = tObjectTimeToLive
  me.updatePowerupTimer(pCarriedPowerupTimeToLive)
end

on clearBottomBarPowerup me 
  removeUpdate(me.getID())
  pCarriedPowerupType = 0
  pCarriedPowerupTimeToLive = 0
  me.setActivateButton(0)
  me.updatePowerupTimer(-1)
  return TRUE
end

on activateButtonPressed me 
  if (pCarriedPowerupType = 0) then
    return TRUE
  end if
  tGameSystem = me.getGameSystem()
  if (tGameSystem = 0) then
    return FALSE
  end if
  tGameSystem.sendGameEventMessage([#integer:4, #integer:pCarriedPowerupId])
  return(me.clearBottomBarPowerup())
end

on setActivateButton me, tstate 
  if me.getGameSystem().getSpectatorModeFlag() then
    return TRUE
  end if
  tWndObj = getWindow(pBottomBarId)
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("bb2_button_powerup")
  if (tElem = 0) then
    return FALSE
  end if
  tsprite = tElem.getProperty(#sprite)
  if (tstate = 6) then
    tTeamId = me.getGameSystem().getGameObjectProperty(me.getOwnGameIndex(), #teamId)
    tMemNum = getmemnum("bb2_button_pwrup_" & tstate & "_" & (tTeamId + 1))
  else
    tMemNum = getmemnum("bb2_button_pwrup_" & tstate)
  end if
  if tMemNum <= 0 then
    return(error(me, "Unable to locate image for powerup button:" && tstate, #setActivateButton))
  end if
  if tsprite.ilk <> #sprite then
    return(error(me, "Unable to locate sprite for powerup button", #setActivateButton))
  end if
  tElem.feedImage(member(tMemNum).image)
  if tstate > 0 then
    tsprite.setcursor("cursor.finger")
  else
    tsprite.setcursor(0)
  end if
  return TRUE
end

on updatePowerupTimer me, tstate 
  tWndObj = getWindow(pBottomBarId)
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("bb2_image_powerup_timer")
  if (tElem = 0) then
    return FALSE
  end if
  tsprite = tElem.getProperty(#sprite)
  if tsprite.ilk <> #sprite then
    return(error(me, "Unable to locate sprite for powerup timer", #updatePowerupTimer))
  end if
  if tstate > 11 then
    tstate = 11
  end if
  if (tstate = 5) then
    me.sendGameSystemEvent(#soundeffect, "5sec-powerup-activation-v1")
  end if
  tMemNum = getmemnum("bb2_timer_pwrup_" & tstate)
  return(tsprite.setMember(member(tMemNum)))
end

on setfxicon me, tstate 
  tWndObj = getWindow(pBottomBarId)
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("gs_int_fx_image")
  if (tElem = 0) then
    return FALSE
  end if
  if tstate then
    tMemName = "bb2_soundon"
  else
    tMemName = "bb2_soundoff"
  end if
  tmember = member(getmemnum(tMemName))
  if (tmember.type = #bitmap) then
    tElem.setProperty(#image, tmember.image)
  end if
  return TRUE
end

on setmusicicon me, tstate 
  tWndObj = getWindow(pBottomBarId)
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("gs_int_music_image")
  if (tElem = 0) then
    return FALSE
  end if
  if tstate then
    tMemName = "bb2_musicon"
  else
    tMemName = "bb2_musicoff"
  end if
  tmember = member(getmemnum(tMemName))
  if (tmember.type = #bitmap) then
    tElem.setProperty(#image, tmember.image)
  end if
  return TRUE
end

on replaceRoomBar me 
  if me.getGameSystem().getSpectatorModeFlag() then
    return TRUE
  end if
  removeWindow(pBottomBarId)
  createWindow(pBottomBarId, "empty.window", 0, 483)
  tWndObj = getWindow(pBottomBarId)
  if (tWndObj = 0) then
    return FALSE
  end if
  tWndObj.lock(1)
  tWndObj.unmerge()
  tLayout = "bb2_ui.window"
  if not tWndObj.merge(tLayout) then
    return FALSE
  end if
  if objectExists("Figure_Preview") then
    getObject("Figure_Preview").createHumanPartPreview(pBottomBarId, "bb2_avatar_face", #head)
  end if
  tWndObj.registerClient(me.getID())
  tWndObj.registerProcedure(#eventProcRoomBar, me.getID(), #mouseUp)
  tWndObj.registerProcedure(#eventProcRoomBar, me.getID(), #keyDown)
  tWndObj.registerProcedure(#eventProcRoomBar, me.getID(), #mouseEnter)
  tWndObj.registerProcedure(#eventProcRoomBar, me.getID(), #mouseLeave)
  me.setActivateButton(0)
  me.setfxicon(getSoundState())
  me.setmusicicon(getSoundState())
  tElem = tWndObj.getElement("chat_field")
  if (tElem = 0) then
    return FALSE
  end if
  updateStage()
  tElem.setEdit(1)
  return(tElem.setFocus(1))
  return TRUE
end

on eventProcRoomBar me, tEvent, tSprID, tParam 
  if (tEvent = #mouseUp) then
    if (tSprID = "bb2_button_powerup") then
      return(me.activateButtonPressed())
    else
      if (tSprID = "gs_int_fx_image") then
        return(me.sendGameSystemEvent(#setfx))
      else
        if (tSprID = "gs_int_music_image") then
          return(me.sendGameSystemEvent(#setmusic))
        end if
      end if
    end if
  end if
  if (tEvent = #keyDown) then
    if (the key = "\t") or (the keyCode = 125) then
      return(me.activateButtonPressed())
    end if
  end if
  tRoomInt = getObject("RoomBarProgram")
  if (tRoomInt = 0) then
    return FALSE
  end if
  return(tRoomInt.eventProcRoomBar(tEvent, tSprID, tParam))
end

on getOwnGameIndex me 
  tSession = getObject(#session)
  if not tSession.exists("user_game_index") then
    return FALSE
  end if
  return(tSession.GET("user_game_index"))
end
