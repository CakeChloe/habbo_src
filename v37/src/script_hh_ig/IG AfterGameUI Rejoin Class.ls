property pUpdateCounter, pAnimFrame, pCurrentLayout, pEndTime

on update me 
  pUpdateCounter = (pUpdateCounter + 1)
  if pUpdateCounter < 4 then
    return TRUE
  end if
  pUpdateCounter = 0
  tTimeLeft = me.getTimeLeft()
  if tTimeLeft <= 0 then
    return TRUE
  end if
  tWndObj = getWindow(me.getWindowId("top"))
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("ig_info_status")
  if (tElem = 0) then
    return FALSE
  end if
  tElem.setText(replaceChunks(getText("ig_info_game_start_in_x"), "\\x", me.getFormatTime()))
  tElem = tWndObj.getElement("ig_icon_getready")
  if (tElem = 0) then
    return FALSE
  end if
  pAnimFrame = (pAnimFrame + 1)
  if pAnimFrame > 5 then
    pAnimFrame = 0
  end if
  tMemNum = getmemnum("ig_icon_loading_" & pAnimFrame)
  if (tMemNum = 0) then
    return FALSE
  end if
  tElem.setProperty(#image, member(tMemNum).image)
end

on addWindows me 
  me.pWindowID = "a"
  tService = me.getIGComponent("GameList")
  if (tService = 0) then
    return FALSE
  end if
  tGameRef = tService.getJoinedGame()
  if (tGameRef = 0) then
    return FALSE
  end if
  tTeamMaxSize = tGameRef.getTeamMaxSize()
  tTeamCount = tGameRef.getTeamCount()
  tWrapObjRef = me.getWindowWrapper()
  if (tWrapObjRef = 0) then
    return FALSE
  end if
  tWrapObjRef.addOneWindow(me.getWindowId("top"), void(), me.pWindowSetId, [#spaceBottom:2])
  tScrollStartOffset = -100
  tTeamIndex = 1
  repeat while tTeamIndex <= tTeamCount
    tWrapObjRef.addOneWindow(me.getWindowId(tTeamIndex), "ig_ag_join_plrs_" & tTeamMaxSize & ".window", me.pWindowSetId, [#scrollFromLocX:tScrollStartOffset, #spaceBottom:2])
    me.setTeamColorBackground(me.getWindowId(tTeamIndex), tTeamIndex)
    tScrollStartOffset = (tScrollStartOffset - 50)
    tTeamIndex = (1 + tTeamIndex)
  end repeat
  tWrapObjRef.addOneWindow(me.getWindowId("btn"), "ig_ag_leave_game.window", me.pWindowSetId)
  tWrapObjRef.moveTo(4, 10)
  return TRUE
end

on render me 
  tService = me.getIGComponent("GameList")
  if (tService = 0) then
    return FALSE
  end if
  tGameRef = tService.getJoinedGame()
  if (tGameRef = 0) then
    return FALSE
  end if
  if me.getTimeLeft() > 0 then
    tLayout = "ig_ag_game_starting.window"
  else
    tLayout = "ig_ag_waiting_players.window"
  end if
  if tLayout <> pCurrentLayout then
    pCurrentLayout = tLayout
    tWndObj = getWindow(me.getWindowId("top"))
    if (tWndObj = 0) then
      return FALSE
    end if
    tWndObj.unmerge()
    tWndObj.merge(pCurrentLayout)
    tWrapObjRef = me.getWindowWrapper()
    if (tWrapObjRef = 0) then
      return FALSE
    end if
    tWrapObjRef.render()
  end if
  tTeams = tGameRef.getAllTeamData()
  if not listp(tTeams) then
    return FALSE
  end if
  tTeamMaxSize = tGameRef.getTeamMaxSize()
  tTeamCount = tTeams.count
  tOwnTeamIndex = tGameRef.getOwnPlayerTeam()
  tTeamIndex = 1
  repeat while tTeamIndex <= tTeamCount
    tWndID = me.getWindowId(tTeamIndex)
    tTeam = tTeams.getAt(tTeamIndex)
    tTeamPlayers = tTeam.getaProp(#players)
    tPlayerPos = 1
    repeat while tPlayerPos <= tTeamPlayers.count
      tPlayer = tTeamPlayers.getAt(tPlayerPos)
      me.setScoreWindowPlayer(tWndID, tPlayerPos, tPlayer)
      tPlayerPos = (1 + tPlayerPos)
    end repeat
    tPlayerPos = (tTeamPlayers.count + 1)
    repeat while tPlayerPos <= tTeamMaxSize
      me.setScoreWindowPlayer(tWndID, tPlayerPos, 0, 0)
      tPlayerPos = (1 + tPlayerPos)
    end repeat
    me.setJoinButtonState(tTeamIndex, tTeamIndex <> tOwnTeamIndex and tTeamPlayers.count < tTeamMaxSize)
    tTeamIndex = (1 + tTeamIndex)
  end repeat
end

on displayPlayerLeft me, tTeamId, tPlayerPos 
  me.setPlayerFlags(me.getWindowId(tTeamId), tPlayerPos, tTeamId)
  tWndObj = getWindow(me.getWindowId(tTeamId))
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("ig_icon_player_" & tPlayerPos)
  if (tElem = 0) then
    return FALSE
  end if
  tElem.show()
  tMemNum = getmemnum("ig_icon_gameleft")
  if (tMemNum = 0) then
    return FALSE
  end if
  tImage = member(tMemNum).image
  tElem.feedImage(tImage)
  return TRUE
end

on displayTimeLeft me, tTime 
  pEndTime = ((tTime * 1000) + the milliSeconds)
  me.render()
  return TRUE
end

on setScoreWindowPlayer me, tWndID, tPlayerPos, tPlayerInfo, tPlayerActive 
  if tPlayerInfo <> 0 then
    tOwnPlayer = (tPlayerInfo.getaProp(#name) = me.getOwnPlayerName())
  end if
  tWndObj = getWindow(tWndID)
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("ig_icon_player_" & tPlayerPos)
  if (tElem = 0) then
    return FALSE
  end if
  if (tPlayerInfo = 0) then
    tElem.hide()
  else
    tElem.show()
    if not tPlayerInfo.getaProp(#disconnected) then
      tImage = me.getHeadImage(tPlayerInfo.getaProp(#figure), tPlayerInfo.getaProp(#sex), 18, 18)
    else
      tMemNum = getmemnum("ig_icon_gameleft")
      if tMemNum > 0 then
        tImage = member(tMemNum).image
      end if
    end if
    if tImage <> 0 then
      tElem.feedImage(tImage)
    end if
  end if
  tElem = tWndObj.getElement("ig_name_player_" & tPlayerPos)
  if (tElem = 0) then
    return FALSE
  end if
  if (tPlayerInfo = 0) then
    tElem.setText("---")
  else
    tElem.setText(tPlayerInfo.getaProp(#name))
    if tOwnPlayer then
      tFontStruct = getStructVariable("struct.font.bold")
    else
      tFontStruct = getStructVariable("struct.font.plain")
    end if
    tElem.setFont(tFontStruct)
  end if
  return TRUE
end

on setJoinButtonState me, tTeamIndex, tstate 
  tWndObj = getWindow(me.getWindowId(tTeamIndex))
  if (tWndObj = 0) then
    return FALSE
  end if
  tElem = tWndObj.getElement("join.button")
  if (tElem = 0) then
    return FALSE
  end if
  tElem.setProperty(#blend, (20 + (tstate * 80)))
  if tstate then
    tElem.setProperty(#cursor, "cursor.finger")
  else
    tElem.setProperty(#cursor, 0)
  end if
  return TRUE
end

on getFormatTime me 
  tTimeLeft = integer(((pEndTime - the milliSeconds) / 1000))
  if tTimeLeft < 0 then
    return("0:00")
  end if
  tMinutes = (tTimeLeft / 60)
  tSeconds = (tTimeLeft mod 60)
  if tSeconds < 10 then
    tSeconds = "0" & tSeconds
  end if
  return(tMinutes & ":" & tSeconds)
end

on getTimeLeft me 
  tTimeLeft = ((pEndTime - the milliSeconds) / 1000)
  if tTimeLeft < 0 then
    return FALSE
  end if
  return(tTimeLeft)
end
