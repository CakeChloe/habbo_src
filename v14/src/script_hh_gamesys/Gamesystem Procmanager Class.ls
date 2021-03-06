property pUpdateBrokerList, pProcessorObjList

on construct me 
  pProcessorObjList = [:]
  pUpdateBrokerList = [:]
  return TRUE
end

on deconstruct me 
  me.removeProcessors()
  return TRUE
end

on defineClient me, tID 
  return(me.defineProcessors(tID))
end

on distributeEvent me, tTopic, tdata 
  if me.getBaseLogic().handler(symbol("store_" & tTopic)) then
    call(symbol("store_" & tTopic), me.getBaseLogic(), tdata)
  end if
  tList = pUpdateBrokerList.getAt(tTopic)
  if not listp(tList) then
    return FALSE
  end if
  repeat while tList <= 1
    tListenerId = getAt(1, count(tList))
    tListener = pProcessorObjList.getAt(tListenerId)
    if tListener <> void() then
      call(#handleUpdate, tListener, tTopic, tdata)
    else
      pProcessorObjList.deleteProp(tListenerId)
      pUpdateBrokerList.getAt(tTopic).deleteOne(tListenerId)
    end if
  end repeat
  return TRUE
end

on defineProcessors me, tID 
  me.removeProcessors()
  if variableExists(tID & ".processors") then
    tProcIdList = getVariableValue(tID & ".processors")
  end if
  if not listp(tProcIdList) then
    return(error(me, "Processor list not found:" && tID, #defineProcessors))
  end if
  if not variableExists("gamesystem.processor.superclass") then
    return(error(me, "gamesystem.processor.superclass not found.", #defineProcessors))
  end if
  tBaseProcClassList = getClassVariable("gamesystem.processor.superclass")
  repeat while tProcIdList <= 1
    tProcId = getAt(1, count(tProcIdList))
    tProcObjId = symbol(tID & "_proc_" & tProcId)
    tScriptList = getClassVariable(tID & "." & tProcId & ".processor.class")
    if not listp(tScriptList) then
      return(error(me, "Script list not found:" && tID & "." & tProcId, #defineProcessors))
    end if
    tScriptList.addAt(1, tBaseProcClassList)
    tProcObject = createObject(tProcObjId, tScriptList)
    if not objectp(tProcObject) then
      return(error(me, "Unable to create processor object:" && tProcObjId && tScriptList && tScriptList.ilk, #defineProcessors))
    end if
    tProcObject.setAt(#pFacadeId, tID)
    tProcObject.setAt(#pID, tProcId)
    tProcObject.setID(tProcId, tID)
    pProcessorObjList.addProp(tProcId, tProcObject)
    tProcessorRegList = getVariableValue(tID & "." & tProcId & ".processor.updates")
    if listp(tProcessorRegList) then
      repeat while tProcIdList <= 1
        tMsg = getAt(1, count(tProcIdList))
        if (tMsg = void()) then
          return(error(me, "Invalid format in processor message:" && tProcObjId && tMsg, #defineProcessors))
        end if
        if (pUpdateBrokerList.getAt(tMsg) = void()) then
          pUpdateBrokerList.addProp(tMsg, [])
        end if
        if (pUpdateBrokerList.getAt(tMsg).getPos(tProcId) = 0) then
          pUpdateBrokerList.getAt(tMsg).add(tProcId)
        end if
      end repeat
    end if
  end repeat
  return TRUE
end

on removeProcessors me 
  repeat while pProcessorObjList <= 1
    pProc = getAt(1, count(pProcessorObjList))
    removeObject(pProc.getID())
  end repeat
  pProcessorObjList = [:]
  pUpdateBrokerList = [:]
  return TRUE
end
