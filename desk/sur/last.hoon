|%
::  scrobble identifier
::
+$  sid  @uv
::
::  a single scrobble event
::
+$  scrobble
  $:  verb=@t
      name=@t
      image=@t
      source=@t
      when=@da
  ==
::
::  a reaction (like or comment) on a scrobble
::
+$  reaction
  $:  from=@p
      type=?(%like %comment)
      text=@t
      when=@da
  ==
::
::  agent state
::
+$  state-0
  $:  %0
      scrobbles=(map sid scrobble)
      order=(list sid)
      peers=(map @p (map sid scrobble))
      reactions=(map sid (list reaction))
      public=?
  ==
::
+$  state-1
  $:  %1
      scrobbles=(map sid scrobble)
      order=(list sid)
      peers=(map @p (map sid scrobble))
      reactions=(map sid (list reaction))
      public=?
      webhook-password=@t
  ==
::
+$  versioned-state
  $%  state-0
      state-1
  ==
::
::  poke actions
::
+$  action
  $%  ::  owner actions
      [%scrobble =sid =scrobble]
      [%delete =sid]
      [%set-public public=?]
      [%set-webhook-password password=@t]
      ::  social: owner-initiated
      [%react target=@p =sid type=?(%like %comment) text=@t]
      ::  social: remote-initiated
      [%receive-scrobbles from=@p items=(list [sid scrobble])]
      [%receive-react from=@p =sid =reaction]
      ::  webhook
      [%webhook verb=@t name=@t image=@t]
  ==
::
::  subscription updates
::
+$  update
  $%  [%new-scrobble =sid =scrobble]
      [%del-scrobble =sid]
      [%new-react =sid =reaction]
      [%peer-scrobbles from=@p items=(list [sid scrobble])]
  ==
--
