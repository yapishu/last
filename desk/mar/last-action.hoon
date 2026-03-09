/-  last
|_  act=action:last
++  grow
  |%
  ++  noun  act
  --
++  grab
  |%
  ++  noun  action:last
  ++  json
    |=  jon=^json
    ^-  action:last
    =,  dejs:format
    =/  typ=@t  ((ot ~[action+so]) jon)
    ?+  typ  !!
        %'scrobble'
      =/  f
        %-  ot
        :~  sid+(se %uv)
            verb+so
            name+so
            image+so
            source+so
        ==
      =/  [=sid:last verb=@t name=@t image=@t source=@t]
        (f jon)
      [%scrobble sid [verb name image source *@da]]
    ::
        %'delete'
      [%delete ((ot ~[sid+(se %uv)]) jon)]
    ::
        %'set-public'
      [%set-public ((ot ~[public+bo]) jon)]
    ::
        %'react'
      =/  f  (ot ~[target+(se %p) sid+(se %uv) type+so text+so])
      =/  [target=@p =sid:last type=@t text=@t]  (f jon)
      =/  rtype=?(%like %comment)
        ?+  type  %like
          %'like'     %like
          %'comment'  %comment
        ==
      [%react target sid rtype text]
    ::
        %'webhook'
      =/  f  (ot ~[verb+so name+so image+so])
      =/  [verb=@t name=@t image=@t]  (f jon)
      [%webhook verb name image]
    ==
  --
++  grad  %noun
--
