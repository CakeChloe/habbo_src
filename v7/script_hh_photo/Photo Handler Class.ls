on construct(me)
  registerListener(getVariable("connection.info.id"), me.getID(), [4:#handle_film])
  getMultiuserManager().registerListener(getVariable("connection.mus.id"), me.getID(), ["OK":#handle_ok, "FILM":#handle_film_mus])
  return(1)
  exit
end

on deconstruct(me)
  unregisterListener(getVariable("connection.info.id"), me.getID(), [4:#handle_film])
  getMultiuserManager().unregisterListener(getVariable("connection.mus.id"), me.getID(), ["OK":#handle_ok, "FILM":#handle_film_mus])
  return(1)
  exit
end

on handle_ok(me)
  exit
end

on handle_film(me, tMsg)
  tFilmCnt = tMsg.getaProp(#connection).GetIntFrom(tMsg)
  me.getComponent().setFilm(tFilmCnt)
  exit
end

on handle_film_mus(me, tMsg)
  me.getComponent().setFilm(integer(tMsg.getaProp(#content)))
  exit
end