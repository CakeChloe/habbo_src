property pID, pWindowSetId, pWriterIdPlain, pWriterIdBold, pWindowIdPrefix, pWindowID, pModalSpr

on construct me 
  pWriterIdPlain = getUniqueID()
  pWriterIdBold = getUniqueID()
  pWindowIdPrefix = "ig"
  pWindowID = ""
  return(me.ancestor.construct())
end

on deconstruct me 
  if (pID = #modal) then
    return(me.removeModalWindow())
  end if
  tWrapObjRef = me.getWindowWrapper()
  if (tWrapObjRef = 0) then
    return FALSE
  end if
  tWrapObjRef.removeMatchingSets(pWindowSetId)
  if writerExists(pWriterIdPlain) then
    removeWriter(pWriterIdPlain)
  end if
  if writerExists(pWriterIdBold) then
    removeWriter(pWriterIdBold)
  end if
  return(me.ancestor.deconstruct())
end

on setID me, tID 
  pID = tID
end

on addWindows me 
  if (pID = #modal) then
    return(me.createModalWindow())
  end if
  return TRUE
end

on render me 
end

on update me 
end

on getOwnPlayerName me 
  tSession = getObject(#session)
  if (tSession = 0) then
    return FALSE
  end if
  if not tSession.exists(#user_name) then
    return FALSE
  end if
  return(tSession.GET(#user_name))
end

on getOwnPlayerGameIndex me 
  tSession = getObject(#session)
  if (tSession = 0) then
    return FALSE
  end if
  if not tSession.exists("user_game_index") then
    return(-1)
  end if
  tIndex = tSession.GET("user_game_index")
  return(tIndex)
end

on getPlainWriter me 
  if writerExists(pWriterIdPlain) then
    return(getWriter(pWriterIdPlain))
  end if
  tPlainStruct = getStructVariable("struct.font.plain")
  createWriter(pWriterIdPlain, tPlainStruct)
  return(getWriter(pWriterIdPlain))
end

on getBoldWriter me 
  if writerExists(pWriterIdBold) then
    return(getWriter(pWriterIdBold))
  end if
  tBoldStruct = getStructVariable("struct.font.bold")
  tBoldStruct.setaProp(#fontStyle, [#underline])
  createWriter(pWriterIdBold, tBoldStruct)
  return(getWriter(pWriterIdBold))
end

on alignIconImage me, tImage, tWidth, tHeight 
  if tImage.ilk <> #image then
    return FALSE
  end if
  tNewImage = image(tWidth, tHeight, tImage.depth)
  tOffsetX = ((tWidth - tImage.width) / 2)
  tOffsetY = (tHeight - tImage.height)
  tNewImage.copyPixels(tImage, (tImage.rect + rect(tOffsetX, tOffsetY, tOffsetX, tOffsetY)), tImage.rect)
  return(tNewImage)
end

on getHeadImage me, tFigure, tsex, tWidth, tHeight 
  tFigureObj = getObject("Figure_Preview")
  if (tFigureObj = 0) then
    return FALSE
  end if
  if tFigure.ilk <> #propList then
    tParserObj = getObject("Figure_System")
    if (tParserObj = 0) then
      return FALSE
    end if
    tFigure = tParserObj.parseFigure(tFigure, tsex)
  end if
  tImage = tFigureObj.getHumanPartImg(#head, tFigure, 2, "sh")
  if voidp(tHeight) then
    return(tImage)
  else
    return(me.alignIconImage(tImage, tWidth, tHeight))
  end if
end

on getWindowWrapper me 
  return(getObject(#ig_window_wrapper))
end

on getMainThread me 
  return(getObject(me.pMainThreadId))
end

on getIGComponent me, tID 
  tMainThreadRef = me.getMainThread()
  if not objectp(tMainThreadRef) then
    return FALSE
  end if
  return(tMainThreadRef.getIGComponent(tID))
end

on getWindowId me, tParam 
  if voidp(tParam) then
    return(pWindowIdPrefix & "_" & pWindowID)
  else
    return(pWindowIdPrefix & "_" & pWindowID & "_" & tParam)
  end if
end

on createModalWindow me 
  if pModalSpr > 0 then
    return TRUE
  end if
  pModalSpr = reserveSprite(me.getID())
  tsprite = sprite(pModalSpr)
  tsprite.member = member(getmemnum("null"))
  tsprite.blend = 70
  tsprite.rect = rect(0, 0, the stage.rect.width, the stage.rect.height)
  tVisualizer = getVisualizer("Room_visualizer")
  if tVisualizer <> 0 then
    tsprite.locZ = (tVisualizer.getProperty(#locZ) + 10000000)
  else
    tsprite.locZ = -10000000
  end if
  setEventBroker(tsprite.spriteNum, me.getID() & "_spr")
  return TRUE
end

on removeModalWindow me 
  if pModalSpr > 0 then
    releaseSprite(pModalSpr)
    pModalSpr = void()
  end if
  return TRUE
end

on removeMatchingSets me, tWindowSetId, tRender 
  if (tWindowSetId = void()) then
    return FALSE
  end if
  tIdLength = tWindowSetId.length
  i = 1
  repeat while i <= me.count(#pSetIndex)
    tTestString = me.getProp(#pSetIndex, i)
    if (tTestString.getProp(#char, 1, tIdLength) = tWindowSetId) then
      me.removeSet(tTestString, tRender)
      next repeat
    end if
    i = (i + 1)
  end repeat
  return TRUE
end

on eventProcMouseDown me, tEvent, tSprID, tParam, tWndID 
  return TRUE
end
