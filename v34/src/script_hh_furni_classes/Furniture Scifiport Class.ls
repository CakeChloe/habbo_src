on prepare me, tdata 
  tValue = integer(tdata.getAt(#stuffdata))
  if (tValue = 0) then
    me.setOff()
    me.pChanges = 0
  else
    me.setOn()
    me.pChanges = 1
  end if
  return TRUE
end

on updateStuffdata me, tValue 
  tValue = integer(tValue)
  if (tValue = 0) then
    me.setOff()
  else
    me.setOn()
  end if
  me.pChanges = 1
end

on update me 
  if not me.pChanges then
    return()
  end if
  if me.count(#pSprList) < 4 then
    return()
  end if
  return(me.updateScifiPort())
end

on updateScifiPort me 
  if me.count(#pSprList) < 4 then
    return FALSE
  end if
  tGateSp1 = me.getProp(#pSprList, 3)
  tGateSp2 = me.getProp(#pSprList, 4)
  if me.pActive then
    tGateSp1.visible = 0
    tGateSp2.visible = 0
  else
    tGateSp1.visible = 1
    tGateSp2.visible = 1
  end if
  me.pChanges = 0
  return TRUE
end

on setOn me 
  me.pActive = 1
end

on setOff me 
  me.pActive = 0
end

on select me 
  if the doubleClick then
    getThread(#room).getComponent().getRoomConnection().send("USEFURNITURE", [#integer:integer(me.getID()), #integer:0])
  end if
  return TRUE
end
