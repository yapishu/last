::  last: universal social scrobbler
::
/-  last
/+  default-agent, dbug, server
|%
+$  card  card:agent:gall
--
::
%-  agent:dbug
=|  state-0:last
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  =.  public  %.y
  :_  this
  :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/last/api] %last]
  ==
::
++  on-save  !>(state)
::
++  on-load
  |=  old-state=vase
  ^-  (quip card _this)
  =/  old  (mule |.(!<(versioned-state:last old-state)))
  ?:  ?=(%| -.old)
    =.  public  %.y
    :_  this
    :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/last/api] %last]
    ==
  ?-  -.p.old
      %0
    :_  this(state p.old)
    :~  [%pass /eyre/connect %arvo %e %connect [~ /apps/last/api] %last]
    ==
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  |^
  ?+  mark  (on-poke:def mark vase)
      %last-action
    (handle-action !<(action:last vase))
  ::
      %handle-http-request
    =+  !<([eyre-id=@ta req=inbound-request:eyre] vase)
    (handle-http eyre-id req)
  ==
  ::
  ++  handle-action
    |=  act=action:last
    ^-  (quip card _this)
    ?-  -.act
        %scrobble
      ?>  =(src.bowl our.bowl)
      =/  sc=scrobble:last  scrobble.act(when now.bowl)
      =.  scrobbles  (~(put by scrobbles) sid.act sc)
      =.  order  [sid.act order]
      :_  this
      :~  [%give %fact ~[/scrobbles] %last-update !>(`update:last`[%new-scrobble sid.act sc])]
      ==
    ::
        %delete
      ?>  =(src.bowl our.bowl)
      =.  scrobbles  (~(del by scrobbles) sid.act)
      =.  order  (skip order |=(s=sid:last =(s sid.act)))
      :_  this
      :~  [%give %fact ~[/scrobbles] %last-update !>(`update:last`[%del-scrobble sid.act])]
      ==
    ::
        %set-public
      ?>  =(src.bowl our.bowl)
      `this(public public.act)
    ::
        %react
      ?>  =(src.bowl our.bowl)
      =/  rxn=reaction:last  [our.bowl type.act text.act now.bowl]
      ?:  =(target.act our.bowl)
        =/  existing=(list reaction:last)  (~(gut by reactions) sid.act ~)
        =.  reactions  (~(put by reactions) sid.act (snoc existing rxn))
        :_  this
        :~  [%give %fact ~[/scrobbles] %last-update !>(`update:last`[%new-react sid.act rxn])]
        ==
      :_  this
      :~  :*  %pass  /react/(scot %p target.act)
              %agent  [target.act %last]
              %poke  %last-action
              !>(`action:last`[%receive-react our.bowl sid.act rxn])
          ==
      ==
    ::
        %receive-scrobbles
      =/  pals=(set @p)  (get-peers bowl)
      ?.  (~(has in pals) src.bowl)  `this
      =.  peers  (~(put by peers) src.bowl (malt items.act))
      `this
    ::
        %receive-react
      =/  pals=(set @p)  (get-peers bowl)
      ?.  (~(has in pals) src.bowl)  `this
      =/  rxn=reaction:last  reaction.act(from src.bowl)
      =/  existing=(list reaction:last)  (~(gut by reactions) sid.act ~)
      =.  reactions  (~(put by reactions) sid.act (snoc existing rxn))
      `this
    ::
        %webhook
      ?>  =(src.bowl our.bowl)
      =/  new-sid=sid:last  `@uv`eny.bowl
      =/  sc=scrobble:last  [verb.act name.act image.act 'webhook' now.bowl]
      =.  scrobbles  (~(put by scrobbles) new-sid sc)
      =.  order  [new-sid order]
      :_  this
      :~  [%give %fact ~[/scrobbles] %last-update !>(`update:last`[%new-scrobble new-sid sc])]
      ==
    ==
  ::
  ++  handle-http
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  rl=request-line:server  (parse-request-line:server url.request.req)
    =/  site=(list @t)  site.rl
    ?.  ?=([%apps %last %api *] site)
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
    =/  site=(list @t)  t.t.t.site
    ::  webhook: basic auth
    ?:  ?=([%webhook ~] site)
      (handle-webhook eyre-id req)
    ::  public feed: CORS, no auth
    ?:  ?=([%public %feed ~] site)
      (handle-public-feed eyre-id req)
    ::  all other endpoints require auth
    ?.  authenticated.req
      :_  this
      %+  give-simple-payload:app:server  eyre-id
      (login-redirect:gen:server request.req)
    ?:  =(%'GET' method.request.req)
      (handle-get eyre-id site)
    ?:  =(%'POST' method.request.req)
      (handle-post eyre-id req)
    :_  this
    (give-http eyre-id 405 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'method not allowed')))
  ::
  ++  handle-get
    |=  [eyre-id=@ta site=(list @t)]
    ^-  (quip card _this)
    ?+  site
      :_  this
      (give-http eyre-id 404 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'not found')))
    ::
        [%feed ~]
      :_  this
      (give-json eyre-id (build-feed-json ~))
    ::
        [%peers ~]
      =/  mutuals=(set @p)  (get-peers bowl)
      =/  sub-cards=(list card)
        %+  murn  ~(tap in mutuals)
        |=  =ship
        =/  w=wire  /peers/(scot %p ship)
        ?:  (~(has by wex.bowl) [w ship %last])  ~
        `[%pass w %agent [ship %last] %watch /scrobbles]
      :_  this
      %+  weld  sub-cards
      (give-json eyre-id (build-peers-json ~))
    ::
        [%stats ~]
      :_  this
      (give-json eyre-id (build-stats-json ~))
    ::
        [%pals ~]
      =/  pals=(set @p)  (get-peers bowl)
      =/  pl=(list json)
        (turn ~(tap in pals) |=(s=@p s+(scot %p s)))
      :_  this
      (give-json eyre-id a+pl)
    ::
        [%settings ~]
      :_  this
      %-  give-json  :-  eyre-id
      %-  pairs:enjs:format
      :~  ['ship' s+(scot %p our.bowl)]
          ['public' b+public]
      ==
    ::
        [%s3-config ~]
      =/  get-str
        |=  [=json keys=(list @t)]
        ^-  @t
        ?~  keys  ?:(?=([%s *] json) p.json '')
        ?.  ?=([%o *] json)  ''
        =/  v  (~(get by p.json) i.keys)
        ?~  v  ''
        $(json u.v, keys t.keys)
      =/  cred-json=json
        =/  res=(unit json)
          %-  mole
          |.(.^(json %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/credentials/json))
        (fall res *json)
      =/  conf-json=json
        =/  res=(unit json)
          %-  mole
          |.(.^(json %gx /(scot %p our.bowl)/storage/(scot %da now.bowl)/configuration/json))
        (fall res *json)
      :_  this
      %-  give-json  :-  eyre-id
      %-  pairs:enjs:format
      :~  ['endpoint' s+(get-str cred-json ~['storage-update' 'credentials' 'endpoint'])]
          ['accessKeyId' s+(get-str cred-json ~['storage-update' 'credentials' 'accessKeyId'])]
          ['secretAccessKey' s+(get-str cred-json ~['storage-update' 'credentials' 'secretAccessKey'])]
          ['bucket' s+(get-str conf-json ~['storage-update' 'configuration' 'currentBucket'])]
          ['region' s+(get-str conf-json ~['storage-update' 'configuration' 'region'])]
          ['publicUrlBase' s+(get-str conf-json ~['storage-update' 'configuration' 'publicUrlBase'])]
          ['service' s+(get-str conf-json ~['storage-update' 'configuration' 'service'])]
      ==
    ==
  ::
  ++  handle-post
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    =/  body=@t
      ?~  body.request.req  ''
      `@t`q.u.body.request.req
    =/  jon=(unit json)  (de:json:html body)
    ?~  jon
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"bad json"}')))
    =/  act=(unit action:last)  (parse-json-action u.jon)
    ?~  act
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"bad action"}')))
    =/  result  (handle-action u.act)
    :_  +.result
    %+  weld  -.result
    (give-http eyre-id 200 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"ok":true}')))
  ::
  ++  handle-webhook
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ?.  =(%'POST' method.request.req)
      :_  this
      (give-http eyre-id 405 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'method not allowed')))
    ?.  ?|  authenticated.req
            (check-basic-auth header-list.request.req bowl)
        ==
      :_  this
      (give-http eyre-id 401 ~[['www-authenticate' 'Basic realm="last"']] (some (as-octs:mimes:html 'unauthorized')))
    =/  body=@t
      ?~  body.request.req  ''
      `@t`q.u.body.request.req
    ?:  =('' body)
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"empty body"}')))
    ::  try JSON first
    =/  jon=(unit json)  (de:json:html body)
    ?^  jon
      (handle-webhook-json eyre-id u.jon)
    ::  fall back to form-encoded (Last.fm compatible)
    (handle-webhook-form eyre-id body)
  ::
  ++  handle-webhook-json
    |=  [eyre-id=@ta jon=json]
    ^-  (quip card _this)
    ?.  ?=([%o *] jon)
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"expected object"}')))
    =/  m=(map @t json)  p.jon
    =/  get-s
      |=  k=@t
      ^-  @t
      =/  v  (~(get by m) k)
      ?~  v  ''
      ?.  ?=([%s *] u.v)  ''
      p.u.v
    =/  verb=@t  ?:(!=('' (get-s 'verb')) (get-s 'verb') 'listening')
    =/  name=@t
      ?:  !=('' (get-s 'name'))  (get-s 'name')
      =/  artist  (get-s 'artist')
      =/  track   (get-s 'track')
      ?:  &(=('' artist) =('' track))  ''
      ?:  =('' artist)  track
      ?:  =('' track)   artist
      (crip "{(trip artist)} - {(trip track)}")
    =/  image=@t  (get-s 'image')
    ?:  =('' name)
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"name or artist+track required"}')))
    (do-webhook eyre-id verb name image)
  ::
  ++  handle-webhook-form
    |=  [eyre-id=@ta body=@t]
    ^-  (quip card _this)
    =/  fake-url=@t  (cat 3 '/?' body)
    =/  rl=request-line:server  (parse-request-line:server fake-url)
    =/  params  args.rl
    =/  get-param
      |=  k=@t
      ^-  @t
      =/  ps=(list [key=@t value=@t])  params
      |-
      ?~  ps  ''
      ?:  =(key.i.ps k)  value.i.ps
      $(ps t.ps)
    =/  artist=@t
      =/  a  (get-param 'artist')
      ?:(!=('' a) a (get-param 'artist[0]'))
    =/  track=@t
      =/  t  (get-param 'track')
      ?:(!=('' t) t (get-param 'track[0]'))
    =/  verb=@t
      =/  v  (get-param 'verb')
      ?:(=('' v) 'listening' v)
    =/  name=@t
      =/  n  (get-param 'name')
      ?:  !=('' n)  n
      ?:  &(=('' artist) =('' track))  ''
      ?:  =('' artist)  track
      ?:  =('' track)   artist
      (crip "{(trip artist)} - {(trip track)}")
    =/  image=@t  (get-param 'image')
    ?:  =('' name)
      :_  this
      (give-http eyre-id 400 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"error":"name or artist+track required"}')))
    (do-webhook eyre-id verb name image)
  ::
  ++  do-webhook
    |=  [eyre-id=@ta verb=@t name=@t image=@t]
    ^-  (quip card _this)
    =/  new-sid=sid:last  `@uv`eny.bowl
    =/  sc=scrobble:last  [verb name image 'webhook' now.bowl]
    =.  scrobbles  (~(put by scrobbles) new-sid sc)
    =.  order  [new-sid order]
    :_  this
    %+  weld
      :~  [%give %fact ~[/scrobbles] %last-update !>(`update:last`[%new-scrobble new-sid sc])]
      ==
    (give-http eyre-id 200 ~[['content-type' 'application/json']] (some (as-octs:mimes:html '{"ok":true}')))
  ::
  ++  handle-public-feed
    |=  [eyre-id=@ta req=inbound-request:eyre]
    ^-  (quip card _this)
    ?:  =(%'OPTIONS' method.request.req)
      :_  this
      %-  give-http  :^  eyre-id  204
      :~  ['access-control-allow-origin' '*']
          ['access-control-allow-methods' 'GET, OPTIONS']
          ['access-control-allow-headers' 'Content-Type']
          ['access-control-max-age' '86400']
      ==
      ~
    ?.  =(%'GET' method.request.req)
      :_  this
      (give-http eyre-id 405 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'method not allowed')))
    ?.  public
      :_  this
      (give-http eyre-id 403 ~[['content-type' 'text/plain']] (some (as-octs:mimes:html 'feed is private')))
    =/  resp=@t  (en:json:html (build-feed-json ~))
    :_  this
    %-  give-http  :^  eyre-id  200
    :~  ['content-type' 'application/json']
        ['access-control-allow-origin' '*']
    ==
    (some (as-octs:mimes:html resp))
  ::
  ++  parse-json-action
    |=  jon=json
    ^-  (unit action:last)
    =/  res  (mule |.((parse-json-action-raw jon)))
    ?:  ?=(%& -.res)  `p.res
    ~
  ::
  ++  parse-json-action-raw
    |=  jon=json
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
      =/  [s=@uv verb=@t name=@t image=@t source=@t]
        (f jon)
      [%scrobble s [verb name image source *@da]]
    ::
        %'delete'
      [%delete ((ot ~[sid+(se %uv)]) jon)]
    ::
        %'set-public'
      [%set-public ((ot ~[public+bo]) jon)]
    ::
        %'react'
      =/  f  (ot ~[target+(se %p) sid+(se %uv) type+so text+so])
      =/  [target=@p s=@uv type=@t text=@t]  (f jon)
      =/  rtype=?(%like %comment)
        ?+  type  %like
          %'like'     %like
          %'comment'  %comment
        ==
      [%react target s rtype text]
    ==
  ::
  ++  scrobble-to-json
    |=  [=sid:last sc=scrobble:last]
    ^-  json
    =/  rxns=(list reaction:last)  (~(gut by reactions) sid ~)
    %-  pairs:enjs:format
    :~  ['sid' s+(scot %uv sid)]
        ['verb' s+verb.sc]
        ['name' s+name.sc]
        ['image' s+image.sc]
        ['source' s+source.sc]
        ['when' (numb:enjs:format (div (sub when.sc ~1970.1.1) ~s1))]
        :-  'reactions'
        :-  %a
        %+  turn  rxns
        |=  r=reaction:last
        %-  pairs:enjs:format
        :~  ['from' s+(scot %p from.r)]
            ['type' s+?:(=(type.r %like) 'like' 'comment')]
            ['text' s+text.r]
            ['when' (numb:enjs:format (div (sub when.r ~1970.1.1) ~s1))]
        ==
    ==
  ::
  ++  build-feed-json
    |=  ~
    ^-  json
    %-  pairs:enjs:format
    :~  ['ship' s+(scot %p our.bowl)]
        :-  'scrobbles'
        :-  %a
        %+  turn  order
        |=  =sid:last
        (scrobble-to-json sid (~(got by scrobbles) sid))
    ==
  ::
  ++  build-peers-json
    |=  ~
    ^-  json
    %-  pairs:enjs:format
    :~  :-  'peers'
        %-  pairs:enjs:format
        %+  turn  ~(tap by peers)
        |=  [=ship items=(map sid:last scrobble:last)]
        :-  (scot %p ship)
        :-  %a
        %+  turn  ~(tap by items)
        |=  [=sid:last sc=scrobble:last]
        (scrobble-to-json sid sc)
    ==
  ::
  ++  build-stats-json
    |=  ~
    ^-  json
    =/  total=@ud  (lent order)
    =/  verb-counts=(map @t @ud)
      =/  acc=(map @t @ud)  ~
      =/  rem=(list sid:last)  order
      |-
      ?~  rem  acc
      =/  sc=scrobble:last  (~(got by scrobbles) i.rem)
      =/  prev=@ud  (~(gut by acc) verb.sc 0)
      $(rem t.rem, acc (~(put by acc) verb.sc +(prev)))
    =/  name-counts=(map @t @ud)
      =/  acc=(map @t @ud)  ~
      =/  rem=(list sid:last)  order
      |-
      ?~  rem  acc
      =/  sc=scrobble:last  (~(got by scrobbles) i.rem)
      =/  prev=@ud  (~(gut by acc) name.sc 0)
      $(rem t.rem, acc (~(put by acc) name.sc +(prev)))
    =/  sorted-names=(list [@t @ud])
      %+  sort  ~(tap by name-counts)
      |=  [a=[@t @ud] b=[@t @ud]]
      (gth +.a +.b)
    =/  top-10=(list [@t @ud])  (scag 10 sorted-names)
    %-  pairs:enjs:format
    :~  ['total' (numb:enjs:format total)]
        :-  'by-verb'
        %-  pairs:enjs:format
        %+  turn  ~(tap by verb-counts)
        |=  [v=@t c=@ud]
        [v (numb:enjs:format c)]
        :-  'top-items'
        :-  %a
        %+  turn  top-10
        |=  [n=@t c=@ud]
        %-  pairs:enjs:format
        :~  ['name' s+n]
            ['count' (numb:enjs:format c)]
        ==
    ==
  --
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?+  path  (on-watch:def path)
      [%http-response @ ~]
    `this
  ::
      [%scrobbles ~]
    ?.  public
      ~|  %last-feed-not-public
      !!
    =/  pals=(set @p)  (get-peers bowl)
    ?.  |(=(src.bowl our.bowl) (~(has in pals) src.bowl))
      ~|  %last-not-mutual
      !!
    =/  items=(list [sid:last scrobble:last])
      %+  turn  order
      |=(s=sid:last [s (~(got by scrobbles) s)])
    :_  this
    :~  [%give %fact ~ %last-update !>(`update:last`[%peer-scrobbles our.bowl items])]
    ==
  ==
::
++  on-leave  on-leave:def
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  ~
      [%x %dbug %state ~]  ``noun+!>(state)
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+  wire  `this
      [%peers @ ~]
    =/  who=@p  (slav %p i.t.wire)
    ?-  -.sign
        %fact
      =/  res=(each update:last tang)
        (mule |.(!<(update:last q.cage.sign)))
      ?:  ?=(%| -.res)
        ~&  [%last-bad-fact-from who]
        `this
      =/  upd=update:last  p.res
      ?-  -.upd
          %peer-scrobbles
        =.  peers  (~(put by peers) from.upd (malt items.upd))
        `this
      ::
          %new-scrobble
        =/  existing=(map sid:last scrobble:last)
          (~(gut by peers) who ~)
        =.  peers
          (~(put by peers) who (~(put by existing) sid.upd scrobble.upd))
        `this
      ::
          %del-scrobble
        =/  existing=(map sid:last scrobble:last)
          (~(gut by peers) who ~)
        =.  peers
          (~(put by peers) who (~(del by existing) sid.upd))
        `this
      ::
          %new-react
        =/  existing=(list reaction:last)
          (~(gut by reactions) sid.upd ~)
        =.  reactions
          (~(put by reactions) sid.upd (snoc existing reaction.upd))
        `this
      ==
    ::
        %watch-ack
      ?~  p.sign  `this
      ~&  [%last-watch-failed who]
      `this
    ::
        %kick
      :_  this
      :~  [%pass /peers/(scot %p who) %agent [who %last] %watch /scrobbles]
      ==
    ::
        %poke-ack
      `this
    ==
  ::
      [%react @ ~]
    ?+  -.sign  `this
        %poke-ack
      ?~  p.sign  `this
      ~&  [%last-react-failed (slav %p i.t.wire)]
      `this
    ==
  ==
::
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ?+  wire  `this
      [%eyre *]
    ?:  ?=(%bound +<.sign)
      ~?  !accepted.sign  [%last %binding-rejected binding.sign]
      `this
    `this
  ==
::
++  on-fail  on-fail:def
--
::
::  helper core
::
|%
++  get-pals
  |=  =bowl:gall
  ^-  (set @p)
  =/  res=(unit (set @p))
    %-  mole
    |.(.^((set @p) %gx /(scot %p our.bowl)/pals/(scot %da now.bowl)/mutuals/noun))
  ?~  res  ~
  u.res
::
++  get-contacts
  |=  =bowl:gall
  ^-  (set @p)
  =/  res=(unit (map * *))
    %-  mole
    |.(.^((map * *) %gx /(scot %p our.bowl)/contacts/(scot %da now.bowl)/v1/book/noun))
  ?~  res  ~
  %-  silt
  %+  murn  ~(tap in ~(key by u.res))
  |=(k=* ?@(k (some `@p`k) ~))
::
++  get-peers
  |=  =bowl:gall
  ^-  (set @p)
  %-  silt
  %+  skim  ~(tap in (~(uni in (get-pals bowl)) (get-contacts bowl)))
  |=(s=@p (lth `@`s (bex 32)))
::
++  check-basic-auth
  |=  [headers=(list [key=@t value=@t]) =bowl:gall]
  ^-  ?
  =/  auth-header=(unit @t)
    =/  hdrs=(list [key=@t value=@t])  headers
    |-
    ?~  hdrs  ~
    ?:  =("authorization" (cass (trip key.i.hdrs)))
      `value.i.hdrs
    $(hdrs t.hdrs)
  ?~  auth-header  %.n
  =/  val=tape  (trip u.auth-header)
  ?.  =("Basic " (scag 6 val))  %.n
  =/  encoded=tape  (slag 6 val)
  =/  decoded=(unit octs)  (de:base64:mimes:html (crip encoded))
  ?~  decoded  %.n
  =/  cred=tape  (trip q.u.decoded)
  =/  colon=(unit @ud)  (find ":" cred)
  ?~  colon  %.n
  =/  pass=tape  (slag +(u.colon) cred)
  =/  code=@p
    .^(@p %j /(scot %p our.bowl)/code/(scot %da now.bowl)/(scot %p our.bowl))
  =/  code-text=tape  (trip (scot %p code))
  =(pass ?:(=("~" (scag 1 code-text)) (slag 1 code-text) code-text))
::
++  give-http
  |=  [eyre-id=@ta status=@ud headers=(list [@t @t]) body=(unit octs)]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  [[status headers] body]
::
++  give-json
  |=  [eyre-id=@ta jon=json]
  ^-  (list card)
  %+  give-simple-payload:app:server  eyre-id
  (json-response:gen:server jon)
--
