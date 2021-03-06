on render me 
  tService = me.getIGComponent("LevelList")
  if (tService = 0) then
    return FALSE
  end if
  tItemRef = tService.getSelectedLevel()
  if (tItemRef = 0) then
    return FALSE
  end if
  tWndObj = getWindow(me.getWindowId())
  if (tWndObj = 0) then
    return FALSE
  end if
  tWndObj.unmerge()
  tWndObj.merge("ig_choose_teams_bb.window")
  tWndObj = getWindow(me.getWindowId("spec"))
  if (tWndObj = 0) then
    return FALSE
  end if
  tWndObj.unmerge()
  if (tItemRef.getProperty(#allow_powerups) = 1) then
    tWndObj.merge("ig_choose_powerups.window")
    me.renderProperty(#bb_pups, tItemRef.getProperty(#bb_pups))
  end if
  tWrapObjRef = me.getWindowWrapper()
  if (tWrapObjRef = 0) then
    return FALSE
  end if
  tWrapObjRef.render()
  me.ancestor.render()
  return TRUE
end

on renderProperty me, tKey, tValue 
  if (tKey = #bb_pups) then
    return(me.renderBBPowerups(tValue))
  end if
  return(me.ancestor.renderProperty(tKey, tValue))
end

on renderBBPowerups me, tPupList 
  if (tPupList = 0) then
    return(error(me, "Invalid powerup list for BB game", #render))
  end if
  tWndObj = getWindow(me.getWindowId("spec"))
  if (tWndObj = 0) then
    return FALSE
  end if
  pPupItemList = tPupList
  i = 1
  repeat while i <= 8
    tElement = tWndObj.getElement("ig_icon_powerup_" & i)
    if (tElement = 0) then
      return FALSE
    end if
    if (tPupList.findPos(i) = 0) then
      tMemNum = getmemnum("ig_bb_icon_pwrup_" & i & "_1")
      if tMemNum <> 0 then
        tElement.setProperty(#image, member(tMemNum).image)
      end if
    else
      tMemNum = getmemnum("ig_bb_icon_pwrup_" & i & "_0")
      if tMemNum <> 0 then
        tElement.setProperty(#image, member(tMemNum).image)
      end if
    end if
    i = (1 + i)
  end repeat
  return TRUE
end

on eventProcMouseDown me, tEvent, tSprID, tParam, tWndID, tIntParam 
  tService = me.getIGComponent("LevelList")
  if (tService = 0) then
    return FALSE
  end if
  if (tSprID = "ig_icon_powerup") then
    return(tService.setProperty(#bb_pups, tIntParam))
  end if
  return FALSE
end

on eventProcMouseHover me, tEvent, tSprID, tParam, tWndID 
  if not tSprID contains "ig_icon_powerup" then
    return FALSE
  end if
  tObject = me.getMainThread().getInterface().getTooltipManager()
  if (tObject = 0) then
    return FALSE
  end if
  tIndex = integer(tSprID.getProp(#char, tSprID.length))
  if not integerp(tIndex) then
    return FALSE
  end if
  return(tObject.handleEvent(#mouseEnter, tSprID, tWndID, "bb_powerup_desc_" & tIndex))
end
