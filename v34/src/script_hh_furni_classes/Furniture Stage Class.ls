property pDoFlashing, pSleep, pFlashCount, pNumber

on select me 
  return FALSE
end

on setState me, tNewState 
  tNewState = integer(tNewState)
  if tNewState < -1 then
    tNewState = -1
  end if
  if (tNewState = -1) then
    me.setFloor(0)
    pDoFlashing = 1
    pFlashCount = 0
    pSleep = 0
  else
    callAncestor(#setState, [me], 1)
    me.setFloor(1)
    me.setNumber(tNewState)
    pDoFlashing = 0
    pNumber = tNewState
  end if
  return TRUE
end

on update me 
  if not pDoFlashing then
    return TRUE
  end if
  if pSleep > 0 then
    pSleep = (pSleep - 1)
    return TRUE
  end if
  pSleep = 10
  if ((pFlashCount mod 2) = 0) then
    me.setNumber(pNumber)
  else
    me.setNumber(-1)
  end if
  pFlashCount = (pFlashCount + 1)
  if pFlashCount > 8 then
    pDoFlashing = 0
    callAncestor(#setState, [me], 0)
    pNumber = -1
  end if
  return TRUE
end

on setFloor me, tOn 
  tLayerData = me.getProp(#pLayerDataList, "e")
  if tLayerData.ilk <> #list then
    return FALSE
  end if
  tStateData = tLayerData.getAt(2)
  if tStateData.ilk <> #propList then
    return FALSE
  end if
  if tOn then
    tFrame = 1
  else
    tFrame = 0
  end if
  tStateData.setaProp(#frames, [tFrame])
  tLayerData = me.getProp(#pLayerDataList, "a")
  if tLayerData.ilk <> #list then
    return FALSE
  end if
  tStateData = tLayerData.getAt(2)
  if tStateData.ilk <> #propList then
    return FALSE
  end if
  if tOn then
    tFrame = 1
  else
    tFrame = 0
  end if
  tStateData.setaProp(#frames, [tFrame])
  callAncestor(#setState, [me], (me.pState - 1))
end

on setNumber me, tNumber 
  if not integerp(tNumber) then
    return FALSE
  end if
  tFirstDigit = (tNumber / 10)
  tSecondDigit = (tNumber mod 10)
  if tFirstDigit > 9 then
    tFirstDigit = 9
    tSecondDigit = 9
  end if
  if (tFirstDigit = 0) then
    tFirstDigit = 11
  end if
  if tNumber < 0 then
    tFirstDigit = 11
    tSecondDigit = 11
  end if
  tLayerData = me.pLayerDataList.getaProp("c")
  if tLayerData.ilk <> #list then
    return FALSE
  end if
  tStateData = tLayerData.getAt(2)
  if tStateData.ilk <> #propList then
    return FALSE
  end if
  tStateData.setaProp(#frames, [tFirstDigit])
  tLayerData = me.getProp(#pLayerDataList, "d")
  if tLayerData.ilk <> #list then
    return FALSE
  end if
  tStateData = tLayerData.getAt(2)
  if tStateData.ilk <> #propList then
    return FALSE
  end if
  tStateData.setaProp(#frames, [tSecondDigit])
  callAncestor(#setState, [me], (me.pState - 1))
end
