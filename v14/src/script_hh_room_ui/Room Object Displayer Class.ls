property pCreatorID, pBadgeObjID, pTagListObjID, pBaseWindowIds, pClosed, pWindowCreator, pShowUserTags, pTagListObj, pTagLists, pShowActions, pWindowList, pLastSelectedObjType, pBaseLocZ

on construct me 
  pWindowList = []
  pCreatorID = "room.object.displayer.window.creator"
  createObject(pCreatorID, "Room Object Window Creator Class")
  pBadgeObjID = "room.obj.disp.badge.mngr"
  createObject(pBadgeObjID, "Badge Manager Class")
  pShowActions = 1
  pShowUserTags = 0
  pLastSelectedObjType = void()
  pTagListObjID = "room.obj.disp.tags"
  createObject(pTagListObjID, "Tag List Class")
  pBaseLocZ = 0
  pBaseWindowIds = getVariableValue("object.displayer.window.ids")
  me.createBaseWindows()
  registerMessage(#groupLogoDownloaded, me.getID(), #groupLogoDownloaded)
  registerMessage(#hideInfoStand, me.getID(), #clearWindowDisplayList)
  registerMessage(#updateInfostandAvatar, me.getID(), #refreshView)
  registerMessage(#showObjectInfo, me.getID(), #showObjectInfo)
  registerMessage(#hideObjectInfo, me.getID(), #clearWindowDisplayList)
  registerMessage(#removeObjectInfo, me.getID(), #clearWindowDisplayList)
  registerMessage(#updateInfoStandBadge, me.getID(), #updateBadge)
  registerMessage(#leaveRoom, me.getID(), #clearWindowDisplayList)
  registerMessage(#updateUserTags, me.getID(), #updateTagList)
  registerMessage(#changeRoom, me.getID(), #clearWindowDisplayList)
  registerMessage(#itemObjectsUpdated, me.getID(), #refreshView)
  registerMessage(#activeObjectsUpdated, me.getID(), #refreshView)
  registerMessage(#updateClubStatus, me.getID(), #refreshView)
  pWindowCreator = getObject(pCreatorID)
  pTagListObj = getObject(pTagListObjID)
  pTagLists = [:]
  return TRUE
end

on deconstruct me 
  unregisterMessage(#hideInfoStand, me.getID())
  unregisterMessage(#groupLogoDownloaded, me.getID())
  removeObject(pBadgeObjID)
  removeObject(pCreatorID)
  return TRUE
end

on updateBadge me, tBadgeName 
  me.refreshView()
end

on createBaseWindows me 
  tIndex = 1
  repeat while tIndex <= pBaseWindowIds.count
    tID = pBaseWindowIds.getAt(tIndex)
    if not windowExists(tID) then
      createWindow(tID, "obj_disp_base.window", 999, 999)
      tWndObj = getWindow(tID)
      if (tIndex = 1) then
        pBaseLocZ = (tWndObj.getProperty(#locZ) - 1000)
      end if
    end if
    tWndObj.hide()
    tIndex = (1 + tIndex)
  end repeat
end

on showObjectInfo me, tObjType, tRefresh 
  if pClosed and tRefresh then
    return TRUE
  end if
  if voidp(tObjType) then
    return FALSE
  end if
  if (pWindowCreator = 0) then
    return FALSE
  end if
  me.clearWindowDisplayList()
  pLastSelectedObjType = tObjType
  tRoomComponent = getThread(#room).getComponent()
  tRoomInterface = getThread(#room).getInterface()
  tSelectedObj = tRoomInterface.getSelectedObject()
  tWindowTypes = []
  if (tObjType = "user") then
    tObj = tRoomComponent.getUserObject(tSelectedObj)
    tWindowTypes = getVariableValue("object.display.windows.human")
  else
    if (tObjType = "bot") then
      tObj = tRoomComponent.getUserObject(tSelectedObj)
      tWindowTypes = getVariableValue("object.display.windows.bot")
    else
      if (tObjType = "active") then
        tObj = tRoomComponent.getActiveObject(tSelectedObj)
        tWindowTypes = getVariableValue("object.display.windows.furni")
      else
        if (tObjType = "item") then
          tObj = tRoomComponent.getItemObject(tSelectedObj)
          tWindowTypes = getVariableValue("object.display.windows.furni")
        else
          if (tObjType = "pet") then
            tObj = tRoomComponent.getUserObject(tSelectedObj)
            tWindowTypes = getVariableValue("object.display.windows.pet")
          else
            error(me, "Unsupported object type:" && tObjType, #showObjectInfo, #minor)
            tObj = 0
          end if
        end if
      end if
    end if
  end if
  if (tObj = 0) then
    return FALSE
  else
    tProps = tObj.getInfo()
  end if
  tPos = 1
  repeat while tPos <= tWindowTypes.count
    tWindowType = tWindowTypes.getAt(tPos)
    if (tWindowType = "human") then
      tID = pBaseWindowIds.getAt(#avatar)
      pWindowCreator.createHumanWindow(tID, tProps, tSelectedObj, pBadgeObjID, pShowUserTags)
      me.updateInfoStandGroup(tProps.getAt(#groupid))
      me.pushWindowToDisplayList(tID)
    else
      if (tWindowType = "bot") then
        tID = pBaseWindowIds.getAt(#avatar)
        pWindowCreator.createBotWindow(tID, tProps)
        me.pushWindowToDisplayList(tID)
      else
        if (tWindowType = "furni") then
          tID = pBaseWindowIds.getAt(#avatar)
          pWindowCreator.createFurnitureWindow(tID, tProps)
          me.pushWindowToDisplayList(tID)
        else
          if (tWindowType = "pet") then
            tID = pBaseWindowIds.getAt(#avatar)
            pWindowCreator.createPetWindow(tID, tProps)
            me.pushWindowToDisplayList(tID)
          else
            if (tWindowType = "tags_user") then
              if pShowUserTags then
                tID = pBaseWindowIds.getAt(#tags)
                pWindowCreator.createUserTagsWindow(tID)
                me.pushWindowToDisplayList(tID)
                tTagsWindow = getWindow(tID)
                tTagsElem = tTagsWindow.getElement("room_obj_disp_tags")
                pTagListObj.setWidth(tTagsElem.getProperty(#width))
                pTagListObj.setHeight(tTagsElem.getProperty(#height))
                tTagList = pTagLists.getaProp(tObj.getWebID())
                tTagListImage = pTagListObj.createTagList(tTagList)
                tTagsElem.feedImage(tTagListImage)
              end if
            else
              if (tWindowType = "links_human") then
                tID = pBaseWindowIds.getAt(#links)
                if (tProps.getAt(#name) = getObject(#session).GET("user_name")) then
                  pWindowCreator.createLinksWindow(tID, #own)
                else
                  pWindowCreator.createLinksWindow(tID, #peer)
                end if
                me.pushWindowToDisplayList(tID)
              else
                if (tWindowType = "actions_human") then
                  tID = pBaseWindowIds.getAt(#actions)
                  pWindowCreator.createActionsHumanWindow(tID, tProps.getAt(#name), pShowActions)
                  me.pushWindowToDisplayList(tID)
                else
                  if (tWindowType = "actions_furni") then
                    if tRoomComponent.itemObjectExists(tSelectedObj) then
                      tselectedobject = tRoomComponent.getItemObject(tSelectedObj)
                      tClass = tselectedobject.getClass()
                      if tClass contains "post.it" then
                      else
                        tID = pBaseWindowIds.getAt(#links)
                        pWindowCreator.createActionsFurniWindow(tID, tObjType, pShowActions)
                        me.pushWindowToDisplayList(tID)
                        if (tWindowType = "bottom") then
                          tID = pBaseWindowIds.getAt(#bottom)
                          pWindowCreator.createBottomWindow(tID)
                          me.pushWindowToDisplayList(tID)
                        end if
                        if windowExists(tID) then
                          tWndObj = getWindow(tID)
                          tWndObj.registerProcedure(#eventProc, me.getID(), #mouseUp)
                          tWndObj.registerProcedure(#eventProc, me.getID(), #mouseWithin)
                          tWndObj.registerProcedure(#eventProc, me.getID(), #mouseLeave)
                        end if
                      end if
                      tPos = (1 + tPos)
                      me.alignWindows()
                      pClosed = 0
                    end if
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end if
  end repeat
end

on clearWindowDisplayList me 
  repeat while pWindowList <= 1
    tWindowID = getAt(1, count(pWindowList))
    pWindowCreator.clearWindow(tWindowID)
  end repeat
  pWindowList = []
  if objectExists(pBadgeObjID) then
    getObject(pBadgeObjID).removeBadgeEffect()
  end if
end

on pushWindowToDisplayList me, tWindowID 
  pWindowList.add(tWindowID)
end

on refreshView me 
  me.clearWindowDisplayList()
  me.showObjectInfo(pLastSelectedObjType, 1)
end

on showHideActions me 
  pShowActions = not pShowActions
  me.refreshView()
end

on showHideTags me 
  pShowUserTags = not pShowUserTags
  me.refreshView()
end

on alignWindows me 
  if (pWindowList.count = 0) then
    return FALSE
  end if
  tDefLeftPos = getVariable("object.display.pos.left")
  tDefBottomPos = getVariable("object.display.pos.bottom")
  tIndex = pWindowList.count
  repeat while tIndex >= 1
    tWindowID = pWindowList.getAt(tIndex)
    tWindowObj = getWindow(tWindowID)
    tWindowObj.moveZ((pBaseLocZ + ((tIndex - 1) * 100)))
    if (tIndex = pWindowList.count) then
      tWindowObj.moveTo(tDefLeftPos, (tDefBottomPos - tWindowObj.getProperty(#height)))
    else
      tPrevWindowID = pWindowList.getAt((tIndex + 1))
      tPrevWindow = getWindow(tPrevWindowID)
      tTopPos = (tPrevWindow.getProperty(#locY) - tWindowObj.getProperty(#height))
      tWindowObj.moveTo(tDefLeftPos, tTopPos)
    end if
    tIndex = (255 + tIndex)
  end repeat
end

on updateInfoStandGroup me, tGroupId 
  tHumanWindowID = pBaseWindowIds.getAt(#avatar)
  if windowExists(tHumanWindowID) then
    tWindowObj = getWindow(tHumanWindowID)
    if tWindowObj.elementExists("info_group_badge") then
      tElem = tWindowObj.getElement("info_group_badge")
    else
      return FALSE
    end if
  else
    return FALSE
  end if
  if voidp(tGroupId) or tGroupId < 0 then
    tElem.clearImage()
    tElem.setProperty(#cursor, "cursor.arrow")
    return FALSE
  end if
  tRoomComponent = getThread(#room).getComponent()
  tGroupInfoObject = tRoomComponent.getGroupInfoObject()
  tLogoMemNum = tGroupInfoObject.getGroupLogoMemberNum(tGroupId)
  if not voidp(tGroupId) then
    tElem.clearImage()
    tElem.setProperty(#image, member(tLogoMemNum).image)
    tElem.setProperty(#cursor, "cursor.finger")
  else
    tElem.clearImage()
    tElem.setProperty(#cursor, "cursor.arrow")
  end if
end

on groupLogoDownloaded me, tGroupId 
  tRoomInterface = getThread(#room).getInterface()
  tRoomComponent = getThread(#room).getComponent()
  tSelectedObj = tRoomInterface.getSelectedObject()
  tObj = tRoomComponent.getUserObject(tSelectedObj)
  if (tObj = 0) then
    return FALSE
  end if
  tUsersGroup = tObj.getProperty(#groupid)
  if (tUsersGroup = tGroupId) then
    me.updateInfoStandGroup(tGroupId)
  end if
end

on updateTagList me, tUserID, tTagList 
  tOldList = pTagLists.getaProp(tUserID)
  if tOldList <> tTagList then
    pTagLists.setaProp(tUserID, tTagList)
    me.refreshView()
  end if
end

on eventProc me, tEvent, tSprID, tParam 
  tComponent = getThread(#room).getComponent()
  tOwnUser = tComponent.getOwnUser()
  tInterface = getThread(#room).getInterface()
  tSelectedObj = tInterface.pSelectedObj
  tSelectedType = tInterface.pSelectedType
  if (tEvent = #mouseUp) then
    if (tSprID = "dance.button") then
      tCurrentDance = tOwnUser.getProperty(#dancing)
      if tCurrentDance > 0 then
        tComponent.getRoomConnection().send("STOP", "Dance")
      else
        tComponent.getRoomConnection().send("DANCE")
      end if
      return TRUE
    else
      if (tSprID = "hcdance.button") then
        tCurrentDance = tOwnUser.getProperty(#dancing)
        if (tParam.count(#char) = 6) then
          tInteger = integer(tParam.getProp(#char, 6))
          tComponent.getRoomConnection().send("DANCE", [#integer:tInteger])
        else
          if tCurrentDance > 0 then
            tComponent.getRoomConnection().send("STOP", "Dance")
          end if
        end if
        return TRUE
      else
        if (tSprID = "wave.button") then
          if tOwnUser.getProperty(#dancing) then
            tComponent.getRoomConnection().send("STOP", "Dance")
            tInterface.dancingStoppedExternally()
          end if
          return(tComponent.getRoomConnection().send("WAVE"))
        else
          if (tSprID = "move.button") then
            return(tInterface.startObjectMover(tSelectedObj))
          else
            if (tSprID = "rotate.button") then
              return(tComponent.getActiveObject(tSelectedObj).rotate())
            else
              if (tSprID = "pick.button") then
                if (tSelectedType = "active") then
                  ttype = "stuff"
                else
                  if (tSelectedType = "item") then
                    ttype = "item"
                  else
                    return(me.clearWindowDisplayList())
                  end if
                end if
                me.clearWindowDisplayList()
                return(tComponent.getRoomConnection().send("ADDSTRIPITEM", "new" && ttype && tSelectedObj))
              else
                if (tSelectedType = "delete.button") then
                  pDeleteObjID = tSelectedObj
                  pDeleteType = tSelectedType
                  return(tInterface.showConfirmDelete())
                else
                  if (tSelectedType = "kick.button") then
                    if tComponent.userObjectExists(tSelectedObj) then
                      tUserName = tComponent.getUserObject(tSelectedObj).getName()
                    else
                      tUserName = ""
                    end if
                    tComponent.getRoomConnection().send("KICKUSER", tUserName)
                    return(me.clearWindowDisplayList())
                  else
                    if (tSelectedType = "give_rights.button") then
                      if tComponent.userObjectExists(tSelectedObj) then
                        tUserName = tComponent.getUserObject(tSelectedObj).getName()
                      else
                        tUserName = ""
                      end if
                      tComponent.getRoomConnection().send("ASSIGNRIGHTS", tUserName)
                      tSelectedObj = ""
                      me.clearWindowDisplayList()
                      tInterface.hideArrowHiliter()
                      return TRUE
                    else
                      if (tSelectedType = "take_rights.button") then
                        if tComponent.userObjectExists(tSelectedObj) then
                          tUserName = tComponent.getUserObject(tSelectedObj).getName()
                        else
                          tUserName = ""
                        end if
                        tComponent.getRoomConnection().send("REMOVERIGHTS", tUserName)
                        tSelectedObj = ""
                        me.clearWindowDisplayList()
                        tInterface.hideArrowHiliter()
                        return TRUE
                      else
                        if (tSelectedType = "friend.button") then
                          if tComponent.userObjectExists(tSelectedObj) then
                            tUserName = tComponent.getUserObject(tSelectedObj).getName()
                          else
                            tUserName = ""
                          end if
                          executeMessage(#externalBuddyRequest, tUserName)
                          return TRUE
                        else
                          if (tSelectedType = "trade.button") then
                            tList = [:]
                            tList.setAt("showDialog", 1)
                            executeMessage(#getHotelClosingStatus, tList)
                            if (tList.getAt("retval") = 1) then
                              return TRUE
                            end if
                            if tComponent.userObjectExists(tSelectedObj) then
                              tUserName = tComponent.getUserObject(tSelectedObj).getName()
                            else
                              tUserName = ""
                            end if
                            tInterface.startTrading(tSelectedObj)
                            tInterface.getContainer().open()
                            return TRUE
                          else
                            if (tSelectedType = "ignore.button") then
                              tIgnoreListObj = tInterface.pIgnoreListObj
                              if tComponent.userObjectExists(tSelectedObj) then
                                tUserName = tComponent.getUserObject(tSelectedObj).getName()
                                tIgnoreListObj.setIgnoreStatus(tUserName, 1)
                              end if
                              me.clearWindowDisplayList()
                              tSelectedObj = ""
                            else
                              if (tSelectedType = "unignore.button") then
                                tIgnoreListObj = tInterface.pIgnoreListObj
                                if tComponent.userObjectExists(tSelectedObj) then
                                  tUserName = tComponent.getUserObject(tSelectedObj).getName()
                                  tIgnoreListObj.setIgnoreStatus(tUserName, 0)
                                end if
                                me.clearWindowDisplayList()
                                tSelectedObj = ""
                              else
                                if tSelectedType <> "room_obj_disp_badge_sel" then
                                  if (tSelectedType = "room_obj_disp_icon_badge") then
                                    if objectExists(pBadgeObjID) then
                                      getObject(pBadgeObjID).openBadgeWindow()
                                    end if
                                  else
                                    if tSelectedType <> "room_obj_disp_home" then
                                      if (tSelectedType = "room_obj_disp_icon_home") then
                                        if variableExists("link.format.userpage") then
                                          tWebID = tComponent.getUserObject(tSelectedObj).getWebID()
                                          if not voidp(tWebID) then
                                            tDestURL = replaceChunks(getVariable("link.format.userpage"), "%ID%", string(tWebID))
                                            openNetPage(tDestURL)
                                          end if
                                        end if
                                      else
                                        if (tSelectedType = "info_badge") then
                                          tSession = getObject(#session)
                                          tSelectedObj = tInterface.getSelectedObject()
                                          if (tSelectedObj = tSession.GET("user_index")) then
                                            tBadgeObj = getObject(pBadgeObjID)
                                            tBadgeObj.toggleOwnBadgeVisibility()
                                          end if
                                        else
                                          if (tSelectedType = "info_group_badge") then
                                            tSelectedObj = tInterface.getSelectedObject()
                                            if not voidp(tSelectedObj) and tSelectedObj <> "" then
                                              tUserObj = tComponent.getUserObject(tSelectedObj)
                                              tInfoObj = tComponent.getGroupInfoObject()
                                              if tUserObj <> 0 and tUserObj <> void() then
                                                tUserInfo = tUserObj.getInfo()
                                                tInfoObj.showUsersInfoByName(tUserInfo.getAt(#name))
                                              end if
                                            end if
                                          else
                                            if (tSelectedType = "object_displayer_toggle_actions") then
                                              me.showHideActions()
                                            else
                                              if (tSelectedType = "object_displayer_toggle_actions_icon") then
                                                me.showHideActions()
                                              else
                                                if (tSelectedType = "object_displayer_toggle_tags") then
                                                  me.showHideTags()
                                                else
                                                  if (tSelectedType = "object_displayer_toggle_tags_icon") then
                                                    me.showHideTags()
                                                  else
                                                    if (tSelectedType = "room_obj_disp_close") then
                                                      pClosed = 1
                                                      me.clearWindowDisplayList()
                                                    else
                                                      if tSelectedType <> "room_obj_disp_looks" then
                                                        if (tSelectedType = "room_obj_disp_icon_avatar") then
                                                          tAllowModify = 1
                                                          if getObject(#session).exists("allow_profile_editing") then
                                                            tAllowModify = getObject(#session).GET("allow_profile_editing")
                                                          end if
                                                          if tAllowModify then
                                                            if threadExists(#registration) then
                                                              getThread(#registration).getComponent().openFigureUpdate()
                                                            end if
                                                          else
                                                            openNetPage(getText("url_figure_editor"))
                                                          end if
                                                        else
                                                          if (tSelectedType = "room_obj_disp_tags") then
                                                            tTag = pTagListObj.getTagAt(tParam)
                                                            if stringp(tTag) then
                                                              tDestURL = replaceChunks(getVariable("link.format.tag.search"), "%tag%", tTag)
                                                              openNetPage(tDestURL)
                                                            end if
                                                          else
                                                            if (tSelectedType = "room_obj_disp_bg") then
                                                              return FALSE
                                                            else
                                                              return(error(me, "Unknown object interface command:" && tSprID, #eventProcInterface, #minor))
                                                            end if
                                                          end if
                                                        end if
                                                        if (tEvent = #mouseWithin) then
                                                          if (tSprID = "room_obj_disp_tags") then
                                                            tTagsWindow = getWindow(pBaseWindowIds.getAt(#tags))
                                                            tElem = tTagsWindow.getElement(tSprID)
                                                            if stringp(pTagListObj.getTagAt(tParam)) then
                                                              tElem.setProperty(#cursor, "cursor.finger")
                                                            else
                                                              tElem.setProperty(#cursor, 0)
                                                            end if
                                                          else
                                                            nothing()
                                                          end if
                                                        else
                                                          if (tEvent = #mouseLeave) then
                                                            if (tSprID = "room_obj_disp_tags") then
                                                              tTagsWindow = getWindow(pBaseWindowIds.getAt(#tags))
                                                              tElem = tTagsWindow.getElement(tSprID)
                                                              tElem.setProperty(#cursor, 0)
                                                            else
                                                              nothing()
                                                            end if
                                                          end if
                                                        end if
                                                      end if
                                                    end if
                                                  end if
                                                end if
                                              end if
                                            end if
                                          end if
                                        end if
                                      end if
                                    end if
                                  end if
                                end if
                              end if
                            end if
                          end if
                        end if
                      end if
                    end if
                  end if
                end if
              end if
            end if
          end if
        end if
      end if
    end if
  end if
end
