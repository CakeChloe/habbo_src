property pWriterID, pSongController, pTimeLineUpdateTimer, pRoomActivityUpdateTimer, pConnectionId, pSongChanged, pConfirmedAction, pConfirmedActionParameter, pSoundSetLimit, pSoundSetListPageSize, pSoundSetList, pSoundSetListPage, pSoundSetInventoryList, pHooveredSoundSetTab, pHooveredSampleReady, pSongPlaying, pSongStartTime, pTimeLineSlotLength, pSongLength, pTimeLineViewSlotCount, pPlayHeadPosX, pTimeLineSlotCount, pTimeLineScrollX, pSoundMachineFurniID, pSoundMachineFurniOn, pTimeLineReady, pTimeLineData, pSongData, pSoundSetInsertLocked, pSelectedSoundSet, pSampleHorCount, pSampleVerCount, pSelectedSoundSetSample, pHooveredSoundSet, pHooveredSoundSetSample, pTimeLineCursorX, pTimeLineCursorY, pTimeLineChannelCount, pSampleNameBase, pPlayTime, pInitialProcessTime

on construct me 
  pWriterID = getUniqueID()
  tBold = getStructVariable("struct.font.plain")
  tMetrics = [#font:tBold.getaProp(#font), #fontStyle:tBold.getaProp(#fontStyle), #color:rgb("#B6DCDF")]
  createWriter(pWriterID, tMetrics)
  pTimeLineUpdateTimer = "sound_machine_timeline_timer"
  pRoomActivityUpdateTimer = "sound_machine_room_activity_timer"
  pSampleNameBase = "sound_machine_sample_"
  pConnectionId = getVariableValue("connection.info.id", #info)
  pSampleHorCount = 3
  pSampleVerCount = 3
  pSoundSetLimit = 4
  pSoundSetListPageSize = 3
  pTimeLineChannelCount = 4
  pTimeLineSlotCount = 150
  pTimeLineSlotLength = 2000
  pTimeLineScrollX = 0
  pTimeLineViewSlotCount = 24
  pSongController = "song controller"
  createObject(pSongController, "Song Controller Class")
  me.reset(1)
  registerMessage(#sound_machine_selected, me.getID(), #soundMachineSelected)
  registerMessage(#sound_machine_set_state, me.getID(), #soundMachineSetState)
  registerMessage(#sound_machine_removed, me.getID(), #soundMachineRemoved)
  registerMessage(#sound_machine_created, me.getID(), #soundMachineCreated)
  return TRUE
end

on deconstruct me 
  if writerExists(pWriterID) then
    removeWriter(pWriterID)
  end if
  if timeoutExists(pTimeLineUpdateTimer) then
    removeTimeout(pTimeLineUpdateTimer)
  end if
  if timeoutExists(pRoomActivityUpdateTimer) then
    removeTimeout(pRoomActivityUpdateTimer)
  end if
  unregisterMessage(#sound_machine_selected, me.getID())
  unregisterMessage(#sound_machine_set_state, me.getID())
  unregisterMessage(#sound_machine_removed, me.getID())
  unregisterMessage(#sound_machine_created, me.getID())
  return TRUE
end

on reset me, tInitialReset 
  pSoundMachineFurniOn = 0
  me.closeEdit(tInitialReset)
end

on closeEdit me, tInitialReset 
  pSoundMachineFurniID = 0
  pHooveredSampleReady = 1
  pSelectedSoundSet = 0
  pSelectedSoundSetSample = 0
  pHooveredSoundSet = 0
  pHooveredSoundSetSample = 0
  pHooveredSoundSetTab = 0
  pSoundSetListPage = 1
  pTimeLineCursorX = 0
  pTimeLineCursorY = 0
  pTimeLineScrollX = 0
  pPlayHeadPosX = 0
  pConfirmedAction = ""
  pConfirmedActionParameter = ""
  pSoundSetInsertLocked = 0
  pSongChanged = 0
  pPlayTime = 0
  pInitialProcessTime = 0
  pSongLength = 0
  me.clearTimeLine()
  me.clearSoundSets()
  pSoundSetInventoryList = []
  if not tInitialReset then
    if getConnection(pConnectionId) <> 0 then
      return(getConnection(pConnectionId).send("GET_SOUND_DATA"))
    end if
  end if
  return TRUE
end

on closeSelectAction me 
  pSoundMachineFurniID = 0
end

on confirmAction me, tAction, tParameter 
  pConfirmedAction = tAction
  pConfirmedActionParameter = tParameter
  if (tAction = "eject") then
    tReferences = me.checkSoundSetReferences(tParameter)
    if tReferences then
      return TRUE
    end if
  else
    if (tAction = "close") then
      if pSongChanged then
        return TRUE
      end if
    else
      if (tAction = "clear") then
        return TRUE
      else
        if (tAction = "save") then
          return TRUE
        end if
      end if
    end if
  end if
  me.actionConfirmed()
  return FALSE
end

on actionConfirmed me 
  if (pConfirmedAction = "eject") then
    tRetVal = me.removeSoundSet(pConfirmedActionParameter)
    if tRetVal then
      me.getInterface().renderTimeLine()
    end if
  else
    if (pConfirmedAction = "close") then
      me.getInterface().hideSoundMachine()
    else
      if (pConfirmedAction = "clear") then
        me.clearTimeLine()
        me.getInterface().renderTimeLine()
      else
        if (pConfirmedAction = "save") then
          me.saveSong()
        end if
      end if
    end if
  end if
  pConfirmedAction = ""
  pConfirmedActionParameter = ""
  return TRUE
end

on getConfigurationData me 
  me.stopSong()
  if getConnection(pConnectionId) <> 0 then
    tRetVal = getConnection(pConnectionId).send("GET_SOUND_MACHINE_CONFIGURATION")
    if tRetVal then
      return(getConnection(pConnectionId).send("GET_SOUND_DATA"))
    end if
  end if
  return FALSE
end

on getSoundSetLimit me 
  return(pSoundSetLimit)
end

on getSoundSetListPageSize me 
  return(pSoundSetListPageSize)
end

on getSoundSetID me, tIndex 
  if tIndex < 1 or tIndex > pSoundSetList.count then
    return FALSE
  end if
  if voidp(pSoundSetList.getAt(tIndex)) then
    return FALSE
  end if
  return(pSoundSetList.getAt(tIndex).getAt(#id))
end

on getSoundSetListID me, tIndex 
  tIndex = (tIndex + ((pSoundSetListPage - 1) * pSoundSetListPageSize))
  if tIndex < 1 or tIndex > pSoundSetInventoryList.count then
    return FALSE
  end if
  return(pSoundSetInventoryList.getAt(tIndex).getAt(#id))
end

on getSoundSetHooveredTab me 
  return(pHooveredSoundSetTab)
end

on getSoundListPage me 
  return(pSoundSetListPage)
end

on getSoundListPageCount me 
  return((1 + ((pSoundSetInventoryList.count() - 1) / pSoundSetListPageSize)))
end

on getHooveredSampleReady me 
  return(pHooveredSampleReady)
end

on getPlayTime me 
  if not pSongPlaying then
    return FALSE
  end if
  tTime = (((the milliSeconds + 30) - pSongStartTime) mod (pTimeLineSlotLength * pSongLength))
  if (tTime = 0) then
    tTime = 1
  end if
  return(tTime)
end

on getTimeLineSlotLength me 
  return(pTimeLineSlotLength)
end

on getTimeLineViewSlotCount me 
  return(pTimeLineViewSlotCount)
end

on getPlayHeadPosition me 
  tPlayTime = me.getComponent().getPlayTime()
  tSlotLength = me.getComponent().getTimeLineSlotLength()
  if pSongPlaying then
    tPos = (((tPlayTime / tSlotLength) + pPlayHeadPosX) mod pSongLength)
  else
    tPos = (((tPlayTime / tSlotLength) + pPlayHeadPosX) mod pTimeLineSlotCount)
  end if
  tPos = ((1 + tPos) - pTimeLineScrollX)
  if tPos < 1 or tPos > pTimeLineViewSlotCount then
    return(-(tPos + pTimeLineScrollX))
  end if
  return(tPos)
end

on movePlayHead me, tPos 
  if pSongPlaying then
    return FALSE
  end if
  tPos = (tPos - 1)
  if tPos <> (pPlayHeadPosX - pTimeLineScrollX) then
    if tPos >= 0 and tPos < pTimeLineViewSlotCount then
      pPlayHeadPosX = (tPos + pTimeLineScrollX)
      return TRUE
    else
      if tPos < 0 then
        me.scrollTimeLine(-1)
        if pPlayHeadPosX <> pTimeLineScrollX then
          pPlayHeadPosX = pTimeLineScrollX
          return TRUE
        end if
      else
        me.scrollTimeLine(1)
        if pPlayHeadPosX <> ((pTimeLineScrollX + pTimeLineViewSlotCount) - 1) then
          pPlayHeadPosX = ((pTimeLineScrollX + pTimeLineViewSlotCount) - 1)
          return TRUE
        end if
      end if
    end if
  end if
  return FALSE
end

on scrollTimeLine me, tDX 
  tScrollX = max(0, min((pTimeLineScrollX + tDX), (pTimeLineSlotCount - pTimeLineViewSlotCount)))
  if tScrollX <> pTimeLineScrollX then
    pTimeLineScrollX = tScrollX
    return TRUE
  end if
  return FALSE
end

on scrollTimeLineTo me, tX 
  tScrollX = max(0, min(tX, (pTimeLineSlotCount - pTimeLineViewSlotCount)))
  if tScrollX <> pTimeLineScrollX then
    pTimeLineScrollX = tScrollX
    return TRUE
  end if
  return FALSE
end

on getScrollPossible me, tDX 
  if tDX < 0 then
    if pTimeLineScrollX > 0 then
      return TRUE
    end if
  end if
  if tDX > 0 then
    if pTimeLineScrollX < (pTimeLineSlotCount - pTimeLineViewSlotCount) then
      return TRUE
    end if
  end if
  return FALSE
end

on soundMachineSelected me, tdata 
  tFurniID = tdata.getAt(#id)
  tFurniOn = tdata.getAt(#furniOn)
  tResult = me.getInterface().soundMachineSelected(tFurniOn)
  if tResult then
    pSoundMachineFurniID = tFurniID
    pSoundMachineFurniOn = tFurniOn
  end if
end

on soundMachineSetState me, tdata 
  tFurniID = tdata.getAt(#id)
  tFurniOn = tdata.getAt(#furniOn)
  tIsEditing = 0
  if (pSoundMachineFurniID = tFurniID) then
    tIsEditing = 1
  end if
  pSoundMachineFurniOn = tFurniOn
  pPlayTime = 0
  if tIsEditing then
    me.soundMachineSelected([#id:tFurniID, #furniOn:pSoundMachineFurniOn])
  else
    if tFurniOn then
      if not pSongPlaying then
        if pTimeLineReady then
          me.playSong(0)
        else
          me.processSongData(0)
        end if
      end if
    else
      me.stopSong()
    end if
  end if
end

on soundMachineRemoved me, tFurniID 
  me.clearTimeLine()
  pSoundMachineFurniID = 0
  pSoundMachineFurniOn = 0
  me.stopSong()
  me.getInterface().hideSoundMachine()
end

on soundMachineCreated me, tFurniID 
  me.clearTimeLine()
  if getConnection(pConnectionId) <> 0 then
    return(getConnection(pConnectionId).send("GET_SOUND_DATA"))
  end if
  return FALSE
end

on changeFurniState me 
  tNewState = not pSoundMachineFurniOn
  tObj = getThread(#room).getComponent().getActiveObject(pSoundMachineFurniID)
  if tObj <> 0 then
    call(#changeState, [tObj], tNewState)
  end if
  pSoundMachineFurniID = 0
end

on updateSetList me, tList 
  pSoundSetInventoryList = []
  repeat while tList <= undefined
    tID = getAt(undefined, tList)
    tItem = [#id:tID]
    pSoundSetInventoryList.add(tItem)
  end repeat
  me.changeSetListPage(0)
  me.getInterface().updateSoundSetList()
end

on updateSoundSet me, tIndex, tID, tSampleList 
  if tIndex >= 1 and tIndex <= pSoundSetLimit then
    tSoundSet = [#id:tID]
    tMachineSampleList = []
    repeat while tSampleList <= tID
      tSampleID = getAt(tID, tIndex)
      tMachineSampleList.add([#id:tSampleID, #length:0])
    end repeat
    tSoundSet.setAt(#samples, tMachineSampleList)
    pSoundSetList.setAt(tIndex, tSoundSet)
    tSampleIndex = 1
    repeat while tSampleIndex <= tMachineSampleList.count
      me.getSampleReady(tSampleIndex, tIndex)
      tSampleIndex = (1 + tSampleIndex)
    end repeat
    me.getInterface().updateSoundSetSlots()
  end if
end

on removeSoundSetInsertLock me 
  pSoundSetInsertLocked = 0
end

on changeSetListPage me, tChange 
  tIndex = (pSoundSetListPage + tChange)
  if tIndex < 1 then
    tIndex = me.getSoundListPageCount()
  else
    if tIndex > me.getSoundListPageCount() then
      tIndex = 1
    end if
  end if
  if (tIndex = pSoundSetListPage) then
    return FALSE
  end if
  pSoundSetListPage = tIndex
  return TRUE
end

on checkSoundSetReferences me, tIndex 
  if tIndex < 1 then
    return FALSE
  end if
  if voidp(pSoundSetList.getAt(tIndex)) then
    return FALSE
  end if
  repeat while pTimeLineData <= undefined
    tChannel = getAt(undefined, tIndex)
    tSlot = 1
    repeat while tSlot <= tChannel.count
      if not voidp(tChannel.getAt(tSlot)) then
        tSampleID = tChannel.getAt(tSlot)
        if tSampleID < 0 then
          tSampleID = -tSampleID
        end if
        if (me.getSampleSetNumber(tSampleID) = tIndex) then
          return TRUE
        end if
      end if
      tSlot = (1 + tSlot)
    end repeat
  end repeat
  repeat while pTimeLineData <= undefined
    tChannel = getAt(undefined, tIndex)
    repeat while pTimeLineData <= undefined
      tSample = getAt(undefined, tIndex)
      if not voidp(tSample) then
        tSampleID = tSample.getAt(#id)
        if (me.getSampleSetNumber(tSampleID) = tIndex) then
          return TRUE
        end if
      end if
    end repeat
  end repeat
  return FALSE
end

on getFreeSoundSetCount me 
  tCount = 0
  i = 1
  repeat while i <= pSoundSetList.count
    if (pSoundSetList.getAt(i) = void()) then
      tCount = (tCount + 1)
    end if
    i = (1 + i)
  end repeat
  return(tCount)
end

on loadSoundSet me, tIndex 
  tIndex = (tIndex + ((pSoundSetListPage - 1) * pSoundSetListPageSize))
  if tIndex < 1 or tIndex > pSoundSetInventoryList.count then
    return FALSE
  end if
  if pSoundSetInsertLocked then
    return FALSE
  end if
  tFreeSlot = 0
  i = 1
  repeat while i <= pSoundSetList.count
    if (pSoundSetList.getAt(i) = void()) then
      tFreeSlot = i
    else
      i = (1 + i)
    end if
  end repeat
  if (tFreeSlot = 0) then
    return FALSE
  end if
  tSoundSet = pSoundSetInventoryList.getAt(tIndex)
  tSetID = tSoundSet.getAt(#id)
  if getConnection(pConnectionId) <> 0 then
    pSoundSetInventoryList.deleteAt(tIndex)
    pSoundSetInsertLocked = 1
    return(getConnection(pConnectionId).send("INSERT_SOUND_PACKAGE", [#integer:tSetID, #integer:tFreeSlot]))
  else
    return FALSE
  end if
end

on removeSoundSet me, tIndex 
  if tIndex < 1 then
    return FALSE
  end if
  if voidp(pSoundSetList.getAt(tIndex)) then
    return FALSE
  end if
  repeat while pTimeLineData <= undefined
    tChannel = getAt(undefined, tIndex)
    tSlot = 1
    repeat while tSlot <= tChannel.count
      if not voidp(tChannel.getAt(tSlot)) then
        tSampleID = tChannel.getAt(tSlot)
        if tSampleID < 0 then
          tSampleID = -tSampleID
        end if
        if (me.getSampleSetNumber(tSampleID) = tIndex) then
          pSongChanged = 1
          tChannel.setAt(tSlot, void())
        end if
      end if
      tSlot = (1 + tSlot)
    end repeat
  end repeat
  repeat while pTimeLineData <= undefined
    tChannel = getAt(undefined, tIndex)
    tSlot = 1
    repeat while tSlot <= tChannel.count
      tSample = tChannel.getAt(tSlot)
      if not voidp(tSample) then
        tSampleID = tSample.getAt(#id)
        if (me.getSampleSetNumber(tSampleID) = tIndex) then
          pSongChanged = 1
          tChannel.setAt(tSlot, void())
        end if
      end if
      tSlot = (1 + tSlot)
    end repeat
  end repeat
  if (pSelectedSoundSet = tIndex) then
    pSelectedSoundSet = 0
    pSelectedSoundSetSample = 0
  end if
  tNewSong = me.encodeTimeLineData()
  if tNewSong <> 0 then
    if getConnection(pConnectionId) <> 0 then
      pSoundSetList.setAt(tIndex, void())
      return(getConnection(pConnectionId).send("EJECT_SOUND_PACKAGE", [#integer:tIndex, #string:tNewSong]))
    else
      return TRUE
    end if
  else
    return FALSE
  end if
end

on clearSoundSets me 
  pSoundSetList = []
  i = 1
  repeat while i <= pSoundSetLimit
    pSoundSetList.setAt(i, void())
    i = (1 + i)
  end repeat
  me.getInterface().updateSoundSetSlots()
end

on soundSetEvent me, tSetID, tX, tY, tEvent 
  if tX >= 1 and tX <= pSampleHorCount and tY >= 1 and tY <= pSampleVerCount and tSetID >= 1 and tSetID <= pSoundSetLimit then
    if (tEvent = #mouseDown) then
      tSampleIndex = (tX + ((tY - 1) * pSampleHorCount))
      if not me.getSampleReady(tSampleIndex, tSetID) then
        return FALSE
      end if
      if (pSelectedSoundSet = tSetID) and (pSelectedSoundSetSample = tSampleIndex) then
        pSelectedSoundSet = 0
        pSelectedSoundSetSample = 0
      else
        pSelectedSoundSet = tSetID
        pSelectedSoundSetSample = tSampleIndex
      end if
    else
      if (tEvent = #mouseWithin) then
        tSample = (tX + ((tY - 1) * pSampleHorCount))
        if (pHooveredSoundSet = tSetID) and (pHooveredSoundSetSample = tSample) then
          return FALSE
        end if
        pHooveredSoundSet = tSetID
        pHooveredSoundSetSample = (tX + ((tY - 1) * pSampleHorCount))
        pHooveredSampleReady = me.getSampleReady(pHooveredSoundSetSample, pHooveredSoundSet)
        if pHooveredSampleReady then
          me.playSample(pHooveredSoundSetSample, pHooveredSoundSet)
        end if
      else
        if (tEvent = #mouseLeave) then
          pHooveredSoundSet = 0
          pHooveredSoundSetSample = 0
          pHooveredSampleReady = 1
          me.stopSample()
        end if
      end if
    end if
    return TRUE
  end if
  return FALSE
end

on soundSetTabEvent me, tSetID, tEvent 
  if tSetID >= 1 and tSetID <= pSoundSetLimit then
    if (tEvent = #mouseDown) then
      tConfirm = me.getInterface().confirmAction("eject", tSetID)
      return(not tConfirm)
    else
      if (tEvent = #mouseWithin) then
        if (tSetID = pHooveredSoundSetTab) then
          return FALSE
        end if
        pHooveredSoundSetTab = tSetID
      else
        if (tEvent = #mouseLeave) then
          pHooveredSoundSetTab = 0
        end if
      end if
    end if
    return TRUE
  end if
  return FALSE
end

on timeLineEvent me, tX, tY, tEvent 
  tX = (tX + pTimeLineScrollX)
  if (tEvent = #mouseDown) then
    tInsert = me.insertSample(tX, tY)
    if tInsert then
      pTimeLineCursorX = 0
      pTimeLineCursorY = 0
      return TRUE
    else
      return(me.removeSample(tX, tY))
    end if
  else
    if (tEvent = #mouseWithin) then
      if tX <> pTimeLineCursorX or tY <> pTimeLineCursorY then
        tID = 0
        tSample = me.getSample(pSelectedSoundSetSample, pSelectedSoundSet)
        if tSample <> 0 then
          tID = tSample.getAt(#id)
        end if
        tInsert = me.getCanInsertSample(tX, tY, tID)
        if tInsert and pTimeLineCursorX <> tX or pTimeLineCursorY <> tY then
          pTimeLineCursorX = tX
          pTimeLineCursorY = tY
          return TRUE
        else
          if pTimeLineCursorX <> 0 and pTimeLineCursorY <> 0 then
            pTimeLineCursorX = 0
            pTimeLineCursorY = 0
            return TRUE
          end if
        end if
      end if
    else
      if (tEvent = #mouseLeave) then
        if tX < 1 or tX > pTimeLineSlotCount or tY < 1 or tY > pTimeLineChannelCount then
          pTimeLineCursorX = 0
          pTimeLineCursorY = 0
          return TRUE
        end if
      end if
    end if
  end if
  return FALSE
end

on clearTimeLine me 
  me.stopSong()
  pTimeLineData = []
  pSongData = []
  i = 1
  repeat while i <= pTimeLineChannelCount
    tChannel = []
    j = 1
    repeat while j <= pTimeLineSlotCount
      tChannel.setAt(j, void())
      j = (1 + j)
    end repeat
    pTimeLineData.setAt(i, tChannel)
    pSongData.setAt(i, tChannel.duplicate())
    i = (1 + i)
  end repeat
  pTimeLineReady = 1
  pPlayHeadPosX = 0
  pSongChanged = 1
end

on renderSoundSet me, tIndex, tWd, tHt, tMarginWd, tMarginHt, tNameBase, tSampleNameBase 
  if tIndex < 0 or tIndex > pSoundSetList.count then
    return FALSE
  end if
  if voidp(pSoundSetList.getAt(tIndex)) then
    return FALSE
  end if
  tImg = image(((pSampleHorCount * tWd) + (tMarginWd * (pSampleHorCount - 1))), ((pSampleVerCount * tHt) + (tMarginHt * (pSampleVerCount - 1))), 32)
  tSampleList = pSoundSetList.getAt(tIndex).getAt(#samples)
  if voidp(tSampleList) then
    return FALSE
  end if
  tSample = 1
  repeat while tSample <= tSampleList.count
    tX = (1 + ((tSample - 1) mod pSampleHorCount))
    tY = (1 + ((tSample - 1) / pSampleVerCount))
    if tY > pSampleVerCount then
    else
      ttype = 1
      if (tIndex = pSelectedSoundSet) and (tSample = pSelectedSoundSetSample) then
        ttype = 3
      else
        if (tIndex = pHooveredSoundSet) and (tSample = pHooveredSoundSetSample) then
          ttype = 2
        end if
      end if
      tName = [tNameBase & ttype, tSampleNameBase & tSample]
      tPart = 1
      repeat while tPart <= tName.count
        tmember = getMember(tName.getAt(tPart))
        if tmember <> 0 then
          tSourceImg = tmember.image
          tRect = tSourceImg.rect
          tImgWd = (tRect.getAt(3) - tRect.getAt(1))
          tImgHt = (tRect.getAt(4) - tRect.getAt(2))
          tRect.setAt(1, ((tRect.getAt(1) + ((tX - 1) * (tWd + tMarginWd))) + ((tWd - tImgWd) / 2)))
          tRect.setAt(2, ((tRect.getAt(2) + ((tY - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
          tRect.setAt(3, ((tRect.getAt(3) + ((tX - 1) * (tWd + tMarginWd))) + ((tWd - tImgWd) / 2)))
          tRect.setAt(4, ((tRect.getAt(4) + ((tY - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
          tImg.copyPixels(tSourceImg, tRect, tSourceImg.rect, [#ink:8, #maskImage:tSourceImg.createMatte()])
        end if
        tPart = (1 + tPart)
      end repeat
      tSample = (1 + tSample)
    end if
  end repeat
  return(tImg)
end

on renderTimeLine me, tWd, tHt, tMarginWd, tMarginHt, tNameBaseList, tSampleNameBase, tBgImage 
  tImg = image(((pTimeLineViewSlotCount * tWd) + (tMarginWd * (pTimeLineViewSlotCount - 1))), ((pTimeLineChannelCount * tHt) + (tMarginHt * (pTimeLineChannelCount - 1))), 32)
  tmember = getMember(tBgImage)
  if tmember <> 0 then
    tImg.copyPixels(tmember.image, tImg.rect, tmember.image.rect)
  end if
  tChannel = 1
  repeat while tChannel <= pTimeLineData.count
    tChannelData = pTimeLineData.getAt(tChannel)
    tSlot = max(1, (pTimeLineScrollX - 10))
    repeat while tSlot <= min((pTimeLineScrollX + pTimeLineViewSlotCount), tChannelData.count)
      if not voidp(tChannelData.getAt(tSlot)) then
        tSampleNumber = tChannelData.getAt(tSlot)
        if not me.renderSample(tSampleNumber, (tSlot - pTimeLineScrollX), tChannel, tWd, tHt, tMarginWd, tMarginHt, tNameBaseList, tSampleNameBase, tImg) then
        end if
      end if
      tSlot = (1 + tSlot)
    end repeat
    tChannel = (1 + tChannel)
  end repeat
  if pTimeLineCursorX <> 0 and pTimeLineCursorY <> 0 then
    tSample = me.getSample(pSelectedSoundSetSample, pSelectedSoundSet)
    if tSample <> 0 then
      tCursorX = (pTimeLineCursorX - pTimeLineScrollX)
      tCursorY = pTimeLineCursorY
      if not me.renderSample(tSample.getAt(#id), tCursorX, tCursorY, tWd, tHt, tMarginWd, tMarginHt, tNameBaseList, tSampleNameBase, tImg, 50) then
      end if
    end if
  end if
  return(tImg)
end

on renderSample me, tSampleNumber, tSlot, tChannel, tWd, tHt, tMarginWd, tMarginHt, tNameBaseList, tSampleNameBase, tImg, tBlend 
  tLength = me.getSampleLength(tSampleNumber)
  if tSampleNumber < 0 then
    tBlend = 20
    tSampleNumber = -tSampleNumber
  end if
  tSampleSet = me.getSampleSetNumber(tSampleNumber)
  tSampleIndex = me.getSampleIndex(tSampleNumber)
  tSample = me.getSample(tSampleIndex, tSampleSet)
  if (tSample = 0) then
    return FALSE
  end if
  if voidp(tBlend) then
    tBlend = 100
  end if
  if tSampleSet < 1 or tSampleSet > tNameBaseList.count then
    return FALSE
  end if
  tNameBase = tNameBaseList.getAt(tSampleSet)
  tName = [tNameBase & "1", tSampleNameBase & tSampleIndex]
  tstart = max(1, tSlot)
  tEnd = min(pTimeLineViewSlotCount, ((tSlot + tLength) - 1))
  tPart = 1
  repeat while tPart <= tName.count
    tmember = getMember(tName.getAt(tPart))
    if tmember <> 0 then
      tSourceImg = tmember.image
      tRectOrig = tSourceImg.rect
      tImgWd = (tRectOrig.getAt(3) - tRectOrig.getAt(1))
      tImgHt = (tRectOrig.getAt(4) - tRectOrig.getAt(2))
      tRectOrig.setAt(2, ((tRectOrig.getAt(2) + ((tChannel - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
      tRectOrig.setAt(4, ((tRectOrig.getAt(4) + ((tChannel - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
      tPos = tstart
      repeat while tPos <= tEnd
        tRect = tRectOrig.duplicate()
        tRect.setAt(1, ((tRect.getAt(1) + ((tPos - 1) * (tWd + tMarginWd))) + ((tWd - tImgWd) / 2)))
        tRect.setAt(3, ((tRect.getAt(3) + ((tPos - 1) * (tWd + tMarginWd))) + ((tWd - tImgWd) / 2)))
        tProps = [#ink:8, #maskImage:tSourceImg.createMatte(), #blend:tBlend]
        tImg.copyPixels(tSourceImg, tRect, tSourceImg.rect, tProps)
        tPos = (1 + tPos)
      end repeat
    end if
    tPart = (1 + tPart)
  end repeat
  tName = tNameBase & "sp"
  tmember = getMember(tName)
  if tmember <> 0 then
    tSourceImg = tmember.image
    tRectOrig = tSourceImg.rect
    tImgWd = (tRectOrig.getAt(3) - tRectOrig.getAt(1))
    tImgHt = (tRectOrig.getAt(4) - tRectOrig.getAt(2))
    tRectOrig.setAt(2, ((tRectOrig.getAt(2) + ((tChannel - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
    tRectOrig.setAt(4, ((tRectOrig.getAt(4) + ((tChannel - 1) * (tHt + tMarginHt))) + ((tHt - tImgHt) / 2)))
    tProps = [#ink:8, #maskImage:tSourceImg.createMatte(), #blend:tBlend]
    tPos = max(0, tSlot)
    repeat while tPos <= min(pTimeLineViewSlotCount, ((tSlot + tLength) - 2))
      tRect = tRectOrig.duplicate()
      tRect.setAt(1, ((tRect.getAt(1) + (tPos * (tWd + tMarginWd))) - (tImgWd / 2)))
      tRect.setAt(3, ((tRect.getAt(3) + (tPos * (tWd + tMarginWd))) - (tImgWd / 2)))
      tImg.copyPixels(tSourceImg, tRect, tSourceImg.rect, tProps)
      tPos = (1 + tPos)
    end repeat
  end if
  return TRUE
end

on renderTimeLineBar me, tWd, tHt, tMarginWd, tNameBaseList, tSampleNameBase, tBgImage 
  tImg = image(((pTimeLineViewSlotCount * tWd) + (tMarginWd * (pTimeLineViewSlotCount - 1))), tHt, 32)
  tImgHt = (tImg.getProp(#rect, 4) - tImg.getProp(#rect, 2))
  tWriterObj = getWriter(pWriterID)
  if (tWriterObj = 0) then
    return(tImg)
  end if
  tstart = max(0, (pTimeLineScrollX + 1))
  tEnd = min(((pTimeLineScrollX + pTimeLineViewSlotCount) - 1), pTimeLineSlotCount)
  tSlot = tstart
  repeat while tSlot <= tEnd
    if (((tSlot * pTimeLineSlotLength) mod 10000) = 0) then
      tOffset = rect(((tWd + tMarginWd) * (tSlot - pTimeLineScrollX)), 0, ((tWd + tMarginWd) * (tSlot - pTimeLineScrollX)), 0)
      tSeconds = ((tSlot * pTimeLineSlotLength) / 1000)
      if tSeconds < 60 then
        tStr = getText("sound_machine_time_1")
      else
        tStr = getText("sound_machine_time_2")
      end if
      tMinStr = string((tSeconds / 60))
      if (tSeconds mod 60) <> 0 then
        tSecStr = string((tSeconds mod 60))
      else
        tSecStr = "00"
      end if
      tStr = replaceChunks(tStr, "%min%", tMinStr)
      tStr = replaceChunks(tStr, "%sec%", tSecStr)
      tStampImg = tWriterObj.render(tStr).duplicate()
      tStampImgTrimmed = image(tStampImg.getProp(#rect, 3), tStampImg.getProp(#rect, 4), 32)
      tStampImgTrimmed.copyPixels(tStampImg, tStampImg.rect, tStampImg.rect, [#ink:8, #maskImage:tStampImg.createMatte()])
      tStampImg = tStampImgTrimmed.trimWhiteSpace()
      tOffset.setAt(1, (tOffset.getAt(1) - ((tStampImg.getProp(#rect, 3) - tStampImg.getProp(#rect, 1)) / 2)))
      tOffset.setAt(3, tOffset.getAt(1))
      tOffset.setAt(2, ((tImgHt - (tStampImg.getProp(#rect, 4) - tStampImg.getProp(#rect, 2))) / 2))
      tOffset.setAt(4, tOffset.getAt(2))
      tImg.copyPixels(tStampImg, (tStampImg.rect + tOffset), tStampImg.rect, [#ink:8, #maskImage:tStampImg.createMatte()])
    end if
    tSlot = (1 + tSlot)
  end repeat
  return(tImg)
end

on playSample me, tSampleIndex, tSoundSet 
  if pSongPlaying then
    return TRUE
  end if
  tSample = me.getSample(tSampleIndex, tSoundSet)
  if tSample <> 0 then
    tReady = 1
    tSampleName = me.getSampleName(tSample.getAt(#id))
    if objectExists(pSongController) then
      tReady = getObject(pSongController).startSamplePreview(tSampleName)
    end if
    return(tReady)
  end if
  return FALSE
end

on stopSample me 
  if objectExists(pSongController) then
    return(getObject(pSongController).stopSamplePreview())
  end if
  return FALSE
end

on getSampleReady me, tSampleIndex, tSoundSet 
  tSample = me.getSample(tSampleIndex, tSoundSet)
  if tSample <> 0 then
    if (tSample.getAt(#length) = 0) then
      tReady = 0
      tLength = me.getSampleLength(tSample.getAt(#id))
      if tLength then
        tSample.setAt(#length, tLength)
        tReady = 1
      end if
      return(tReady)
    else
      return TRUE
    end if
  end if
  return FALSE
end

on getSampleLength me, tSampleID 
  if tSampleID < 0 then
    return TRUE
  end if
  tLength = 0
  tSampleName = me.getSampleName(tSampleID)
  if objectExists(pSongController) then
    tSongController = getObject(pSongController)
    tReady = tSongController.getSampleLoadingStatus(tSampleName)
    if not tReady then
      tDelim = the itemDelimiter
      the itemDelimiter = "_"
      tSampleno = tSampleName.getProp(#item, 4)
      tSamplesPerSEt = 9
      tParentNo = integer(((tSampleno / tSamplesPerSEt) + 1))
      tParentId = "sound_set_" & tParentNo
      the itemDelimiter = tDelim
      tSongController.preloadSounds([[#sound:tSampleName, #parent:tParentId]])
    else
      tLength = tSongController.getSampleLength(tSampleName)
      tLength = ((tLength + (pTimeLineSlotLength - 1)) / pTimeLineSlotLength)
    end if
  end if
  return(tLength)
end

on getSample me, tSampleIndex, tSampleSet 
  if tSampleSet >= 1 and tSampleSet <= pSoundSetLimit then
    if not voidp(pSoundSetList.getAt(tSampleSet)) then
      if pSoundSetList.getAt(tSampleSet).getAt(#samples).count >= tSampleIndex then
        return(pSoundSetList.getAt(tSampleSet).getAt(#samples).getAt(tSampleIndex))
      end if
    end if
  end if
  return FALSE
end

on getSampleName me, tSampleID 
  tName = pSampleNameBase & tSampleID
  return(tName)
end

on insertSample me, tSlot, tChannel 
  tID = 0
  tSample = me.getSample(pSelectedSoundSetSample, pSelectedSoundSet)
  if tSample <> 0 then
    tID = tSample.getAt(#id)
  else
    return FALSE
  end if
  tInsert = me.getCanInsertSample(tSlot, tChannel, tID)
  if tInsert then
    pSongChanged = 1
    pTimeLineData.getAt(tChannel).setAt(tSlot, tID)
    me.stopSong()
    return TRUE
  end if
  return FALSE
end

on removeSample me, tSlot, tChannel 
  if tChannel >= 1 and tChannel <= pTimeLineData.count then
    if tSlot >= 1 and tSlot <= pTimeLineData.getAt(tChannel).count then
      if not voidp(pTimeLineData.getAt(tChannel).getAt(tSlot)) then
        if pTimeLineData.getAt(tChannel).getAt(tSlot) < 0 then
          return FALSE
        end if
      else
        i = (tSlot - 1)
        repeat while i >= 1
          if not voidp(pTimeLineData.getAt(tChannel).getAt(i)) then
            tSampleID = pTimeLineData.getAt(tChannel).getAt(i)
            if tSampleID >= 0 then
              tSampleLength = me.getSampleLength(tSampleID)
              if tSampleLength <> 0 then
                if (i + (tSampleLength - 1)) >= tSlot then
                  tSlot = i
                else
                  return FALSE
                end if
              end if
            end if
          end if
          i = (255 + i)
        end repeat
      end if
      pSongChanged = 1
      me.stopSong()
      pTimeLineData.getAt(tChannel).setAt(tSlot, void())
      return TRUE
    end if
  end if
  return FALSE
end

on getSampleSetNumber me, tSampleID 
  tSamplePos = me.resolveSamplePosition(tSampleID)
  if tSamplePos <> 0 then
    return(tSamplePos.getAt(#soundset))
  end if
  return FALSE
end

on getSampleIndex me, tSampleID 
  tSamplePos = me.resolveSamplePosition(tSampleID)
  if tSamplePos <> 0 then
    return(tSamplePos.getAt(#sample))
  end if
  return FALSE
end

on getCanInsertSample me, tX, tY, tID 
  tLength = me.getSampleLength(tID)
  if tLength <> 0 then
    if tX >= 1 and (tX + (tLength - 1)) <= pTimeLineSlotCount and tY >= 1 and tY <= pTimeLineData.count then
      tChannel = pTimeLineData.getAt(tY)
      i = tX
      repeat while i <= ((tX + tLength) - 1)
        if not voidp(tChannel.getAt(i)) then
          return FALSE
        end if
        i = (1 + i)
      end repeat
      i = (tX - 1)
      repeat while i >= 1
        if not voidp(tChannel.getAt(i)) then
          tNumber = tChannel.getAt(i)
          if (i + (me.getSampleLength(tNumber) - 1)) >= tX then
            return FALSE
          else
            return TRUE
          end if
        end if
        i = (255 + i)
      end repeat
      return TRUE
    end if
  end if
  return FALSE
end

on playSong me, tEditor 
  if pSongPlaying then
    return TRUE
  end if
  pSongLength = me.resolveSongLength()
  if (pSongLength = 0) then
    return FALSE
  end if
  if tEditor then
    if pPlayHeadPosX > pSongLength then
      pPlayHeadPosX = 0
      me.getInterface().updatePlayHead()
    end if
    tPosition = (pTimeLineSlotLength * pPlayHeadPosX)
  else
    tPosition = pPlayTime
  end if
  tSongData = [#offset:0, #sounds:[]]
  tChannel = 1
  repeat while tChannel <= pTimeLineData.count
    tChannelData = pTimeLineData.getAt(tChannel)
    tEmpty = 1
    i = 1
    repeat while i <= pSongLength
      if not voidp(tChannelData.getAt(i)) then
        tEmpty = 0
      else
        i = (1 + i)
      end if
    end repeat
    if not tEmpty then
      tSlot = 1
      repeat while tSlot <= pSongLength
        if not voidp(tChannelData.getAt(tSlot)) then
          tSampleID = tChannelData.getAt(tSlot)
          tSampleLength = me.getSampleLength(tSampleID)
          if tSampleLength <> 0 and tSampleID >= 0 then
            tCount = 0
            repeat while (tChannelData.getAt(tSlot) = tSampleID)
              tCount = (tCount + 1)
              tSlot = (tSlot + tSampleLength)
              if tSlot > pSongLength then
              else
              end if
            end repeat
            tSampleName = me.getSampleName(tSampleID)
            tSampleData = [#name:tSampleName, #loops:tCount, #channel:tChannel]
            tSongData.getAt(#sounds).setAt((tSongData.getAt(#sounds).count + 1), tSampleData)
          else
            tSampleName = me.getSampleName(0)
            tSampleData = [#name:tSampleName, #loops:1, #channel:tChannel]
            tSongData.getAt(#sounds).setAt((tSongData.getAt(#sounds).count + 1), tSampleData)
            tSlot = (tSlot + 1)
          end if
          next repeat
        end if
        tCount = 0
        repeat while voidp(tChannelData.getAt(tSlot))
          tCount = (tCount + 1)
          tSlot = (tSlot + 1)
          if tSlot > pSongLength then
          else
          end if
        end repeat
        tSampleName = me.getSampleName(0)
        tSampleData = [#name:tSampleName, #loops:tCount, #channel:tChannel]
        tSongData.getAt(#sounds).setAt((tSongData.getAt(#sounds).count + 1), tSampleData)
      end repeat
    end if
    tChannel = (1 + tChannel)
  end repeat
  tReady = 0
  if objectExists(pSongController) then
    tSongData.setAt(#offset, tPosition)
    tReady = getObject(pSongController).playSong(tSongData)
    if tReady then
      pSongPlaying = 1
      pSongStartTime = the milliSeconds
      me.getInterface().updatePlayButton()
    end if
  end if
  return(tReady)
end

on stopSong me 
  if pSongPlaying then
    tPlayTime = me.getComponent().getPlayTime()
    tSlotLength = me.getComponent().getTimeLineSlotLength()
    tPos = (((tPlayTime / tSlotLength) + pPlayHeadPosX) mod pSongLength)
    pPlayHeadPosX = tPos
    pSongPlaying = 0
    pSongLength = 0
    me.getInterface().updatePlayHead()
    me.getInterface().updatePlayButton()
  end if
  pSongStartTime = 0
  if objectExists(pSongController) then
    getObject(pSongController).stopSong()
  end if
  return TRUE
end

on saveSong me, tdata 
  tNewSong = me.encodeTimeLineData()
  if tNewSong <> 0 then
    if getConnection(pConnectionId) <> 0 then
      return(getConnection(pConnectionId).send("SAVE_SOUND_MACHINE_CONFIGURATION", [#string:tNewSong]))
    else
      return TRUE
    end if
  else
    return FALSE
  end if
end

on parseSongData me, tdata, tPlayTime 
  me.clearTimeLine()
  pSongChanged = 0
  i = 1
  repeat while i <= tdata.count
    tChannel = tdata.getAt(i)
    if i <= pSongData.count then
      tSongChannel = pSongData.getAt(i)
      tSlot = 1
      repeat while tChannel <= tPlayTime
        tSample = getAt(tPlayTime, tdata)
        tID = tSample.getAt(#id)
        tLength = tSample.getAt(#length)
        if tSlot <= tSongChannel.count then
          pSongData.getAt(i).setAt(tSlot, tSample.duplicate())
        end if
        tSlot = (tSlot + tLength)
      end repeat
    end if
    i = (1 + i)
  end repeat
  me.processSongData(tPlayTime)
  return TRUE
end

on processSongData me, tPlayTime 
  i = 1
  repeat while i <= pTimeLineData.count
    j = 1
    repeat while j <= pTimeLineData.getAt(i).count
      if pTimeLineData.getAt(i).getAt(j) < 0 then
        pTimeLineData.getAt(i).setAt(j, void())
      end if
      j = (1 + j)
    end repeat
    i = (1 + i)
  end repeat
  tReady = 1
  i = 1
  repeat while i <= min(pSongData.count, pTimeLineData.count)
    tSongChannel = pSongData.getAt(i)
    tTimeLineChannel = pTimeLineData.getAt(i)
    j = 1
    repeat while j <= tSongChannel.count
      tSample = tSongChannel.getAt(j)
      if not voidp(tSample) then
        tID = tSample.getAt(#id)
        tLength = tSample.getAt(#length)
        tSampleLength = me.getSampleLength(tID)
        tWasReady = 1
        if (tSampleLength = 0) then
          tSampleLength = 1
          tID = -tID
          tReady = 0
          tWasReady = 0
        end if
        if tID <> 0 then
          tRepeats = (tLength / tSampleLength)
          k = 1
          repeat while k <= tRepeats
            if me.getCanInsertSample((j + ((k - 1) * tSampleLength)), i, tID) then
              tTimeLineChannel.setAt((j + ((k - 1) * tSampleLength)), tID)
            end if
            k = (1 + k)
          end repeat
        end if
        if tWasReady then
          tSongChannel.setAt(j, void())
        end if
      end if
      j = (1 + j)
    end repeat
    i = (1 + i)
  end repeat
  pTimeLineReady = tReady
  if not pTimeLineReady then
    if not timeoutExists(pTimeLineUpdateTimer) then
      createTimeout(pTimeLineUpdateTimer, 500, #processSongData, me.getID(), void(), 1)
    end if
  end if
  me.getInterface().renderTimeLine()
  tSongLength = me.resolveSongLength()
  if not voidp(tPlayTime) then
    if tSongLength then
      pPlayTime = (tPlayTime mod ((tSongLength * pTimeLineSlotLength) / 100))
      pPlayTime = (pPlayTime * 100)
    else
      pPlayTime = 0
    end if
    pInitialProcessTime = the milliSeconds
  end if
  if pTimeLineReady then
    tIsEditing = 0
    if pSoundMachineFurniID <> 0 then
      tIsEditing = 1
    end if
    pPlayTime = ((pPlayTime + (the milliSeconds - pInitialProcessTime)) mod (tSongLength * pTimeLineSlotLength))
    pInitialProcessTime = 0
    if not tIsEditing and pSoundMachineFurniOn then
      pSongPlaying = 0
      me.playSong(0)
    end if
  end if
  return(tReady)
end

on resolveSamplePosition me, tSampleID 
  i = 1
  repeat while i <= pSoundSetList.count
    tSoundSet = pSoundSetList.getAt(i)
    if not voidp(tSoundSet) then
      tSampleList = tSoundSet.getAt(#samples)
      j = 1
      repeat while j <= tSampleList.count
        tSample = tSampleList.getAt(j)
        if (tSample.getAt(#id) = tSampleID) then
          return([#sample:j, #soundset:i])
        end if
        j = (1 + j)
      end repeat
    end if
    i = (1 + i)
  end repeat
  return FALSE
end

on encodeTimeLineData me 
  tStr = ""
  tSongLength = me.resolveSongLength()
  if tSongLength > 0 then
    i = 1
    repeat while i <= pTimeLineData.count
      tChannel = pTimeLineData.getAt(i)
      tStr = tStr & i & ":"
      j = 1
      tChannelData = []
      repeat while j <= tSongLength
        if voidp(tChannel.getAt(j)) then
          tSample = [#id:0, #length:1]
          j = (j + 1)
        else
          tSampleID = tChannel.getAt(j)
          tSampleLength = me.getSampleLength(tSampleID)
          if tSampleID < 0 then
            tSampleID = -tSampleID
          end if
          if (tSampleLength = 0) then
            tSample = [#id:0, #length:1]
          else
            tSample = [#id:tSampleID, #length:tSampleLength]
          end if
          j = (j + tSample.getAt(#length))
        end if
        tChannelData.setAt((tChannelData.count + 1), tSample)
      end repeat
      j = 1
      repeat while j < tChannelData.count
        if (tChannelData.getAt(j).getAt(#id) = tChannelData.getAt((j + 1)).getAt(#id)) then
          tChannelData.getAt(j).setAt(#length, (tChannelData.getAt(j).getAt(#length) + tChannelData.getAt((j + 1)).getAt(#length)))
          tChannelData.deleteAt((j + 1))
          next repeat
        end if
        j = (j + 1)
      end repeat
      tChannelStr = ""
      repeat while tChannelData <= undefined
        tSample = getAt(undefined, undefined)
        if tChannelStr <> "" then
          tChannelStr = tChannelStr & ";"
        end if
        tChannelStr = tChannelStr & tSample.getAt(#id) & "," & tSample.getAt(#length)
      end repeat
      tStr = tStr & tChannelStr & ":"
      i = (1 + i)
    end repeat
  end if
  return(tStr)
end

on resolveSongLength me 
  tLength = 0
  tChannel = 1
  repeat while tChannel <= pTimeLineData.count
    tChannelData = pTimeLineData.getAt(tChannel)
    tSlot = 1
    repeat while tSlot <= tChannelData.count
      if not voidp(tChannelData.getAt(tSlot)) then
        tSampleID = tChannelData.getAt(tSlot)
        tSampleLength = me.getSampleLength(tSampleID)
        if tSampleLength <> 0 and tSampleID >= 0 then
          repeat while (tChannelData.getAt(tSlot) = tSampleID)
            tSlot = (tSlot + tSampleLength)
            if (tSlot - 1) > tLength then
              tLength = (tSlot - 1)
            end if
            if tSlot > tChannelData.count then
            else
            end if
          end repeat
          exit repeat
        end if
        tSlot = (tSlot + 1)
        if tSampleID < 0 then
          if (tSlot - 1) > tLength then
            tLength = (tSlot - 1)
          end if
        end if
        next repeat
      end if
      repeat while voidp(tChannelData.getAt(tSlot))
        tSlot = (tSlot + 1)
        if tSlot > tChannelData.count then
          next repeat
        end if
      end repeat
    end repeat
    tChannel = (1 + tChannel)
  end repeat
  return(tLength)
end

on roomActivityUpdate me, tInitialUpdate 
  tUpdate = me.getInterface().getEditorWindowExists()
  if tUpdate then
    if not tInitialUpdate then
      getConnection(pConnectionId).send("MOVE", [#short:1000, #short:1000])
    end if
    if not timeoutExists(pRoomActivityUpdateTimer) then
      createTimeout(pRoomActivityUpdateTimer, (30 * 1000), #roomActivityUpdate, me.getID(), void(), 1)
    end if
  end if
end
