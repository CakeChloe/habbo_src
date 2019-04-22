property pDirection, pSprite, pPausedTime, pOffset, pTurnPnt

on define me, tsprite, tCount 
  if tCount mod 2 then
    tdir = #right
  else
    tdir = #left
  end if
  pSprite = tsprite
  pOffset = [0, 0]
  pTurnPnt = 0
  pDirection = tdir
  me.reset()
  return(1)
end

on reset me 
  tmodel = ["car2", "car_b2"].getAt(random(2))
  if pDirection = #left then
    pSprite.castNum = getmemnum(tmodel)
    pSprite.flipH = 0
    pSprite.loc = point(732, 477)
    pOffset = [-2, -1]
    pTurnPnt = 488
  else
    pSprite.castNum = getmemnum(tmodel)
    pSprite.flipH = 1
    pSprite.loc = point(213, 505)
    pOffset = [2, -1]
    pTurnPnt = 487
  end if
  pSprite.width = member.width
  pSprite.height = member.height
  pSprite.ink = 41
  pSprite.backColor = random(150) + 20
  pPausedTime = random(150)
end

on update me 
  if pPausedTime > 0 then
    pPausedTime = pPausedTime - 1
    return(0)
  end if
  pSprite.loc = pSprite.loc + pOffset
  if pSprite.locH = pTurnPnt then
    pOffset.setAt(2, -pOffset.getAt(2))
    tMemName = member.name
    tDirNum = integer(tMemName.getProp(#char, length(tMemName)))
    tDirNum = not tDirNum - 1 + 1
    tMemName = tMemName.getProp(#char, 1, length(tMemName) - 1) & tDirNum
    pSprite.castNum = getmemnum(tMemName)
  end if
  if pSprite.locV > 510 then
    return(me.reset())
  end if
end