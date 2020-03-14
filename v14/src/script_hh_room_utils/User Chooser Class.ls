property pWndID, pObjList, pWriterObj, pListHeight

on construct me 
  pWndID = "Chooser."
  pObjMode = #user
  pObjList = [:]
  tMetrics = getStructVariable("struct.font.plain")
  tMetrics.setaProp(#lineHeight, 14)
  createWriter(me.getID() && "Writer", tMetrics)
  pWriterObj = getWriter(me.getID() && "Writer")
  if not createWindow(pWndID, "habbo_system.window", 5, 345) then
    return FALSE
  end if
  tWndObj = getWindow(pWndID)
  if not tWndObj.merge("chooser.window") then
    return(tWndObj.close())
  end if
  tWndObj.registerClient(me.getID())
  tWndObj.registerProcedure(#eventProcChooser, me.getID(), #mouseUp)
  registerMessage(#leaveRoom, me.getID(), #clear)
  registerMessage(#changeRoom, me.getID(), #clear)
  registerMessage(#enterRoom, me.getID(), #update)
  registerMessage(#create_user, me.getID(), #update)
  registerMessage(#remove_user, me.getID(), #update)
  return(me.update())
end

on deconstruct me 
  if windowExists(pWndID) then
    removeWindow(pWndID)
  end if
  pWriterObj = void()
  removeWriter(me.getID() && "Writer")
  pObjList = [:]
  unregisterMessage(#leaveRoom, me.getID())
  unregisterMessage(#changeRoom, me.getID())
  unregisterMessage(#enterRoom, me.getID())
  unregisterMessage(#create_user, me.getID())
  unregisterMessage(#remove_user, me.getID())
  return TRUE
end

on setMode me, tMode 
  if (tMode = #user) then
    pObjMode = #user
  else
    if (tMode = #Active) then
      pObjMode = #Active
    else
      if (tMode = #item) then
        pObjMode = #item
      else
        return(error(me, "Unsupported obj type:" && tMode, #setMode, #minor))
      end if
    end if
  end if
  return(me.update())
end

on update me 
  if not threadExists(#room) then
    return(removeObject(me.getID()))
  end if
  if not windowExists(pWndID) then
    return(removeObject(me.getID()))
  end if
  pObjList = [:]
  pObjList.sort()
  tObjList = getThread(#room).getComponent().getUserObject(#list)
  repeat while tObjList <= 1
    tObj = getAt(1, count(tObjList))
    pObjList.setaProp(tObj.getName(), tObj.getID())
  end repeat
  tObjStr = ""
  i = 1
  repeat while i <= pObjList.count
    tObjStr = tObjStr && pObjList.getPropAt(i) & "\r"
    i = (1 + i)
  end repeat
  tImg = pWriterObj.render(tObjStr)
  tElem = getWindow(pWndID).getElement("list")
  tElem.feedImage(tImg)
  pListHeight = tImg.height
  return TRUE
end

on clear me 
  pObjList = [:]
  pListHeight = 0
  getWindow(pWndID).getElement("list").feedImage(image(1, 1, 8))
  return TRUE
end

on eventProcChooser me, tEvent, tSprID, tParam 
  if (tSprID = "close") then
    return(removeObject(me.getID()))
  else
    if (tSprID = "list") then
      tCount = count(pObjList)
      if (tCount = 0) then
        return FALSE
      end if
      tLineNum = ((tParam.locV / (pListHeight / tCount)) + 1)
      if tLineNum < 1 then
        tLineNum = 1
      end if
      if tLineNum > tCount then
        tLineNum = tCount
      end if
      if not threadExists(#room) then
        return(removeObject(me.getID()))
      end if
      tObjID = pObjList.getAt(tLineNum)
      getThread(#room).getInterface().eventProcUserObj(#mouseUp, tObjID)
      getThread(#room).getInterface().getArrowHiliter().show(tObjID, 1)
    end if
  end if
end
