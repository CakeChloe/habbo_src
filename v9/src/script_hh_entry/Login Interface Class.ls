property pTempPassword

on construct me 
  pConnectionId = getVariable("connection.info.id")
  pTempPassword = ""
  return TRUE
end

on deconstruct me 
  if windowExists(#login_a) then
    removeWindow(#login_a)
  end if
  if windowExists(#login_b) then
    removeWindow(#login_b)
  end if
  return TRUE
end

on showLogin me 
  getObject(#session).set(#userName, "")
  getObject(#session).set(#password, "")
  pTempPassword = ""
  if createWindow(#login_a, "habbo_simple.window", 444, 100) then
    tWndObj = getWindow(#login_a)
    tWndObj.merge("login_a.window")
    tWndObj.registerClient(me.getID())
    tWndObj.registerProcedure(#eventProcLogin, me.getID(), #mouseUp)
  end if
  if createWindow(#login_b, "habbo_simple.window", 444, 230) then
    tWndObj = getWindow(#login_b)
    tWndObj.merge("login_b.window")
    tWndObj.registerClient(me.getID())
    tWndObj.registerProcedure(#eventProcLogin, me.getID(), #mouseUp)
    tWndObj.registerProcedure(#eventProcLogin, me.getID(), #keyDown)
    tWndObj.getElement("login_username").setFocus(1)
    if variableExists("username_input.font.size") then
      tElem = tWndObj.getElement("login_username")
      if (tElem = 0) then
        return FALSE
      end if
      if (tElem.pMember = void()) then
        return FALSE
      end if
      if tElem.pMember.type <> #field then
        return FALSE
      end if
      tElem.pMember.fontSize = getIntVariable("username_input.font.size")
      tElem = tWndObj.getElement("login_password")
      if (tElem = 0) then
        return FALSE
      end if
      if (tElem.pMember = void()) then
        return FALSE
      end if
      if tElem.pMember.type <> #field then
        return FALSE
      end if
      tElem.pMember.fontSize = getIntVariable("username_input.font.size")
    end if
  end if
  return TRUE
end

on hideLogin me 
  if windowExists(#login_a) then
    removeWindow(#login_a)
  end if
  if windowExists(#login_b) then
    removeWindow(#login_b)
  end if
  return TRUE
end

on showDisconnect me 
  createWindow(#error, "error.window", 0, 0, #modal)
  tWndObj = getWindow(#error)
  tWndObj.getElement("error_title").setText(getText("Alert_ConnectionFailure"))
  tWndObj.getElement("error_text").setText(getText("Alert_ConnectionDisconnected"))
  tWndObj.registerClient(me.getID())
  tWndObj.registerProcedure(#eventProcDisconnect, me.getID(), #mouseUp)
  the keyboardFocusSprite = 0
end

on tryLogin me 
  if not windowExists(#login_b) then
    return(error(me, "Window not found:" && #login_b, #eventProcLogin))
  end if
  tWndObj = getWindow(#login_b)
  tUserName = tWndObj.getElement("login_username").getText()
  tPassword = pTempPassword
  if (tUserName = "") then
    return FALSE
  end if
  if (tPassword = "") then
    return FALSE
  end if
  getObject(#session).set(#userName, tUserName)
  getObject(#session).set(#password, tPassword)
  tWndObj.getElement("login_ok").hide()
  tWndObj.getElement("login_connecting").setProperty(#blend, 100)
  tElem = tWndObj.getElement("login_forgotten")
  tElem.setProperty(#blend, 99)
  tElem.setProperty(#cursor, 0)
  tElem = getWindow(#login_a).getElement("login_createUser")
  tElem.setProperty(#blend, 99)
  tElem.setProperty(#cursor, 0)
  me.blinkConnection()
  me.getComponent().setaProp(#pOkToLogin, 1)
  return(me.getComponent().connect())
end

on blinkConnection me 
  if not windowExists(#login_b) then
    return FALSE
  end if
  if timeoutExists(#login_blinker) then
    return FALSE
  end if
  tElem = getWindow(#login_b).getElement("login_connecting")
  if not tElem then
    return FALSE
  end if
  if (getWindow(#login_b).getElement("login_ok").getProperty(#visible) = 1) then
    return FALSE
  end if
  tElem.setProperty(#visible, not tElem.getProperty(#visible))
  return(createTimeout(#login_blinker, 500, #blinkConnection, me.getID(), void(), 1))
end

on showUserFound me 
  if windowExists(#login_b) then
    getWindow(#login_b).unmerge()
  else
    createWindow(#login_b, "habbo_simple.window", 444, 230)
  end if
  tWndObj = getWindow(#login_b)
  tWndObj.merge("login_c.window")
  tTxt = tWndObj.getElement("login_c_welcome").getText()
  tTxt = tTxt && getObject(#session).get("user_name")
  tWndObj.getElement("login_c_welcome").setText(tTxt)
  if objectExists("Figure_Preview") then
    tBuffer = getObject("Figure_Preview").createTemplateHuman("h", 3, "wave")
    tWndObj.getElement("login_preview").setProperty(#buffer, tBuffer)
    me.delay(800, #myHabboSmile)
  else
    me.hideLogin()
  end if
  return TRUE
end

on myHabboSmile me 
  if objectExists("Figure_Preview") then
    getObject("Figure_Preview").createTemplateHuman("h", 3, "gest", "temp sml")
  end if
  me.delay(1200, #stopWaving)
end

on stopWaving me 
  if objectExists("Figure_Preview") then
    getObject("Figure_Preview").createTemplateHuman("h", 3, "reset")
    getObject("Figure_Preview").createTemplateHuman("h", 3, "gest", "temp sml")
    getObject("Figure_Preview").createTemplateHuman("h", 3, "remove")
  end if
  me.delay(400, #hideLogin)
end

on updatePasswordAsterisks me 
  if not windowExists(#login_b) then
    return FALSE
  end if
  tPwdTxt = getWindow(#login_b).getElement("login_password").getText()
  i = 1
  repeat while i <= tPwdTxt.length
    tChar = chars(tPwdTxt, i, i)
    if tChar <> "*" and tChar <> " " then
      pTempPassword = chars(pTempPassword, 1, (i - 1)) & tChar & chars(pTempPassword, (i + 1), (i + 1))
    end if
    i = (1 + i)
  end repeat
  tStars = ""
  i = 1
  repeat while i <= pTempPassword.length
    tStars = tStars & "*"
    i = (1 + i)
  end repeat
  getWindow(#login_b).getElement("login_password").setText(tStars)
end

on eventProcLogin me, tEvent, tSprID, tParam 
  tWndObj = getWindow(#login_b)
  if not tWndObj then
    return FALSE
  end if
  if (tEvent = #mouseUp) then
    if (tEvent = "login_password") then
      tCount = tWndObj.getElement(tSprID).getText().length
      the selStart = tCount
      the selEnd = tCount
    else
      if (tEvent = "login_ok") then
        return(me.tryLogin())
      else
        if (tEvent = "login_createUser") then
          pTempPassword = ""
          if (getWindow(#login_a).getElement(tSprID).getProperty(#blend) = 100) then
            if windowExists(#login_a) then
              removeWindow(#login_a)
            end if
            if windowExists(#login_b) then
              removeWindow(#login_b)
            end if
            executeMessage(#show_registration)
            return TRUE
          end if
        else
          if (tEvent = "login_forgotten") then
            if (tWndObj.getElement(tSprID).getProperty(#blend) = 100) then
              openNetPage(getText("login_forgottenPassword_url"))
            end if
          end if
        end if
      end if
    end if
  else
    if (tEvent = #keyDown) then
      tTimeoutHideName = "pwdhide" & the milliSeconds
      if (the keyCode = 36) then
        me.tryLogin()
        return TRUE
      end if
      if (tEvent = "login_password") then
        if (tEvent = 48) then
          return FALSE
        else
          if (tEvent = 49) then
            return TRUE
          else
            if (tEvent = 51) then
              if pTempPassword.length > 0 then
                pTempPassword = chars(pTempPassword, 1, (pTempPassword.length - 1))
              end if
            else
              if tEvent <> 123 then
                if tEvent <> 124 then
                  if tEvent <> 125 then
                    if (tEvent = 126) then
                      return TRUE
                    else
                      if (tEvent = 117) then
                        if windowExists(#login_b) then
                          tWndObj.getElement(tSprID).setText("")
                          pTempPassword = ""
                        end if
                      end if
                    end if
                    createTimeout(tTimeoutHideName, 1, #updatePasswordAsterisks, me.getID(), void(), 1)
                    return FALSE
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

on eventProcDisconnect me, tEvent, tElemID, tParam 
  if (tEvent = #mouseUp) then
    if (tElemID = "error_close") then
      removeWindow(#error)
      resetClient()
    end if
  end if
end
