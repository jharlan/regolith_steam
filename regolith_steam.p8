pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- game:   Regolith
-- author: (personaj) Jason Harlan
-- date: Sept. 12, 2020

function _update()
  cur_frame+=1
  g_seq=g_seq or cocreate(game_sequence)
  if (g_seq and costatus(g_seq) != "dead") then
    coresume(g_seq)
    update_objects()
  else
    g_seq = nil
  end
end

function game_sequence()
  level_init()
  local level=cocreate(level_processor)
  local cutscene=cocreate(cutscene_sequence)
  local over_reason
  while true do
    if (cur_frame%6==0) lines[1] += 1
    if (level and costatus(level) != "dead") then
      _,over_reason=coresume(level)
    elseif (cutscene and costatus(cutscene) != "dead") then
      coresume(cutscene,over_reason)
    else
      return
    end
    yield()
  end
end

function level_processor()
  local over_reason
  local target=cocreate(target_process)
  local ship=cocreate(ship_process)
  
  TASKS={}
  INPUT_LOCK=nil
  
  while not over_reason do
    over_reason=level_over()
    coresume(target)
    coresume(ship)
    yield()
  end
  return over_reason
end

function _draw()
  cls(0)
  if(triangle_list) draw_triangle_list()
  draw_display()
end

function _init()
  cur_frame,max_sensor,mbc,px0,py0,fntspr,fntdefaultcol,fntx,fnty,ast_log,player=0,96,9,0,50,64,7,{},{},{},{lvl=1,z=5.2}
  z_clip,z_max,k_min_x,k_max_x,k_min_y,k_max_y,k_screen_scale,k_x_center,k_y_center,k_ambient,light1_x,light1_y,light1_z,t_light_x,t_light_y,t_light_z=-3,-50,0,128,0,128,80,64,64,.4,.35,.35,.1,0,0,0

  initfont()

  color_list={}
  for t in all(str_to_table("@",colors)) do
    add(color_list,str_to_table(",",t,true))  
  end

  ast_faces={}
  for t in all(str_to_table("@",astf)) do
    add(ast_faces,str_to_table(",",t,true))  
  end
end

Task={}
function Task:new(ast,dir)
  self.__index=self
  local task={}
  task.dir=dir
  if ast then 
    task.ast=ast
    task.w=ast.w
    task.d=ast.d
    task[14],task[10]=0,0
    if (not ast_log[hkey(pairing(ast.x,ast.y))]) then
      for i=1,2 do 
        if (ast.palette[i]!=3) then -- ignore grey
          task[allp[ast.palette[i]]]+=((i==1) and 105 or 45)*ast.lower_scale
        end
      end
    end
  end
  setmetatable(task,self)
  return task
end
function Task:has_mineral()
  return self.w>0 or self.d>0 or self[14]>0 or self[10]>0
end

Beacon={}
function Beacon:new(x,y,config)
  self.__index=self
  srand(abs(pairing(x,y))+config.seed)
  local beacon_type=(x%4==y%4) and "distance" or "weather"
  local o={
    x=x,
    y=y,
    color=(x%4==y%4) and 12 or 4,
    t=(x%4==y%4) and "w" or "d", -- resource impacted; water or dirt
    value=ceil(rnd(config[beacon_type]))+1
  }
  setmetatable(o,self)
  return o
end

function spawn_beacons(x,y,config)
  local imap = {[1]=13,[3]=11,[5]=9,[7]=7,[9]=5,[11]=3,[13]=1}
  local b={
    xoffset=0, -- for drawing
    yoffset=0
  }
  for i,vx in pairs(imap) do
    b[i]={}
    for j,vy in pairs(imap) do
      b[i][j]=Beacon:new(vx+x-8,vy+y-8,config)
    end
  end 
  return b
end

Target={}
function Target:new(ship_spr)
  self.__index=self
  local o= {

    f0=cur_frame,

    -- display arrow?
    an=true,
    aw=true,
    as=true,
    ae=true,
    ac=11,
    -- strings
    s0="",
    s2="",
    -- string colors
    c0=8,
    c2=8,

    -- ship
    ship_x=59,
    ship_y=61,
    ship_spr=ship_spr or 16
  }
  setmetatable(o,self)
  return o
end

function Target:reset()
  self.an,self.aw,self.as,self.ae=true,true,true,true
  self.ac,self.s0,self.s2=11,"",""
end

function Target:get_color()
  return get_tog(self.f0,cur_frame,6) and self.ac or 5
end

function ship_process()
  local ready=cocreate(ready_wait_work)
  local process
  while true do
    if (ready and costatus(ready) != "dead") then
      _,process=coresume(ready)
    elseif (process and costatus(process) != "dead") then
      coresume(process)
    else
      ready=cocreate(ready_wait_work)
    end
    yield()
  end
end

function ready_wait_work()
  local task
  while not task do
    task=dequeue(TASKS)
    yield()
  end
  return cocreate(function() mine_sequence(task) end)
end

function ready_wait_input(dispatch)
  local p
  while not p do
    --if not INPUT_LOCK then
      if(btnp(1) and dispatch["ra"]) then
        p=cocreate(dispatch["ra"])
      elseif(btnp(0) and dispatch["la"]) then
        p=cocreate(dispatch["la"])
      elseif(btnp(3) and dispatch["da"]) then
        p=cocreate(dispatch["da"])
      elseif(btnp(2) and dispatch["ua"]) then
        p=cocreate(dispatch["ua"])
      elseif(btnp(5) and dispatch["x"]) then
        p=cocreate(dispatch["x"])
      end
    --end
    yield()
  end
  return p
end

function cutscene(over_reason)

  purge_all=true -- remove asteroids
  update_objects()

  -- nil target

  tc.an,tc.aw,tc.as,tc.ae=true,true,true,true
  tc.s0,tc.s2="",""

  local timer=1
  local start_frame=cur_frame

  local ship_dir={
    ((59-tc.ship_x)<0 and -1 or ((59-tc.ship_x)==0 and 0 or 1)),
    ((61-tc.ship_y)<0 and -1 or ((61-tc.ship_y)==0 and 0 or 1))
  }

  if (over_reason == "restart") then -- TODO change restart to restart level

  elseif (over_reason == "goal") then
    tc.ship_x,tc.ship_y=59,61
    tc.s0,tc.s2="LEVEL","UP"
    tc.c0,tc.c2=14,14
    tc.ac=14
    lines={0,"     ...level complete!!! - press x for the next level...",11}
    player.lvl =player.lvl+1

  elseif (over_reason=="win") then
    tc.ship_x,tc.ship_y=59,61
    tc.s0,tc.s2="YOU","WIN"
    tc.c0,tc.c2=14,14
    tc.ac=14
    lines={0,"    ...congratulations! you win!!! you are a skilled miner...",14}
    player.lvl=1

  elseif (over_reason=="dirt") then
    sfx(12)
    while timer <=12 do
      -- move ship to center
      if cur_frame-start_frame >= 6 then
      tc.ship_x+=ship_dir[1] 
      tc.ship_y+=ship_dir[2]
      tc.ship_spr=32+timer-1
        lines={0,"  ...shields down!!! - press x to restart level...",8}
        timer+=1        
      end
      yield()
    end 
    tc.ship_x,tc.ship_y=59,61
    tc.s0,tc.s2="GAME","OVER"
    tc.c0,tc.c2=8,8
    tc.ac=8
  elseif (over_reason=="water") then
    while timer <=14 do
      if cur_frame-start_frame >= 6 then
      tc.ship_x+=ship_dir[1]
      tc.ship_y+=ship_dir[2]
        lines={0,"   ...fuel empty!!! - press x to restart level...",8}
        timer+=1        
      end
      yield()
    end 
    tc.ship_x,tc.ship_y=59,61
    tc.s0,tc.s2="GAME","OVER"
    tc.c0,tc.c2=8,8
    tc.ac=8
    sfx(13)
  end
end

function cutscene_sequence(over_reason)
  local scene=cocreate(cutscene)
  local ready=cocreate(ready_wait_input)
  local process
  local dispatch={
    ["x"]=function() return end
  }
    
  while true do
    if (scene and costatus(scene) != "dead") then
      coresume(scene,over_reason)
    elseif (ready and costatus(ready) != "dead") then
      _,process=coresume(ready,dispatch) -- TODO alter expected methods
    elseif (process and costatus(process) != "dead") then
      coresume(process) 
    else
      return 
    end
    yield()
  end
end

function mine_sequence(task)
  local thrust=cocreate(thrust_ship)
  local sensing=cocreate(sensing_sequence)
  while true do
    if (thrust and costatus(thrust) != "dead") then
      coresume(thrust,task.dir)
   elseif (sensing and costatus(sensing) != "dead") then
      coresume(sensing,task)
    else
      player.move_count+=1
      -- update visited asteroid
      local pal_dist={[6]=10,[5]=2} -- base 6 was 10
      if (task.w>0) pal_dist[12]=2 -- add some water
      if (task.d>0) pal_dist[4]=4
      task.ast.pal_dist=build_dist(pal_dist) 
      ast_log[hkey(pairing(task.ast.x,task.ast.y))]=true
      return
    end
    yield()
  end
end

function gather_mineral(mineral,volume)
  local f0=cur_frame
  local sounds={[10]=5,[14]=6}
  local player_sensor=player.sensor
  while volume > 0 do
    sfx(sounds[mineral])
    player_sensor[mineral]+=1 
    volume-=1
    if (player_sensor[mineral]==72) then
      redeem_coin(mineral)
      player_sensor[mineral]=0  
    end
    if (not INPUT_LOCK) yield()
  end
  if (player.lvl==1 and player.message_index<4) then
    player.message_index=4
    lines={0,clvl.lines[player.message_index]}
  end
  
end

function gather_resource(resource)
  local f0=cur_frame
  local sound=resource=="w" and 4 or 3
  while player[resource] < 72 do
    sfx(sound)
    player[resource]+=1
    if (not INPUT_LOCK) yield()
  end
  if (player.lvl==1 and player.message_index==1) then
    player.message_index=2
    lines={0,clvl.lines[player.message_index]}
  elseif (player.lvl==1 and player.message_index==2) then
    player.message_index=3
    lines={0,clvl.lines[player.message_index]}
  end
end

function toggle_beacons(dir,toggle)
  -- possibly determine coords first so can toggle and return
  if (dir=="e") then -- ship moving west
    -- crossing col 5
    new_beacons[5][5].toggle=toggle
    new_beacons[5][7].toggle=toggle
  elseif (dir=="w") then -- ship moving east
    -- crossing col 7
    new_beacons[7][5].toggle=toggle
    new_beacons[7][7].toggle=toggle
  elseif (dir=="s") then -- ship moving north
    -- crossing row 5
    new_beacons[5][5].toggle=toggle
    new_beacons[7][5].toggle=toggle
  elseif (dir=="n") then -- ship moving south
    -- crossing row 7
    new_beacons[5][7].toggle=toggle
    new_beacons[7][7].toggle=toggle
  end
end

function decrement_resources(dir)
   if (dir=="e") then -- ship moving west
    -- crossing col 5
    player[new_beacons[5][5].t]=safe_dec(
      player[new_beacons[5][5].t],new_beacons[5][5].value*2)
    player[new_beacons[5][7].t]=safe_dec(
      player[new_beacons[5][7].t],new_beacons[5][7].value*2)
  elseif (dir=="w") then -- ship moving east
    -- crossing col 7
    player[new_beacons[7][5].t]=safe_dec(
      player[new_beacons[7][5].t],new_beacons[7][5].value*2)
    player[new_beacons[7][7].t]=safe_dec(
      player[new_beacons[7][7].t],new_beacons[7][7].value*2)
  elseif (dir=="s") then -- ship moving north
    -- crossing row 5
    player[new_beacons[5][5].t]=safe_dec(
      player[new_beacons[5][5].t],new_beacons[5][5].value*2)
    player[new_beacons[7][5].t]=safe_dec(
      player[new_beacons[7][5].t],new_beacons[7][5].value*2)
  elseif (dir=="n") then -- ship moving south
    -- crossing row 7
    player[new_beacons[5][7].t]=safe_dec(
      player[new_beacons[5][7].t],new_beacons[5][7].value*2)
    player[new_beacons[7][7].t]=safe_dec(
      player[new_beacons[7][7].t],new_beacons[7][7].value*2)
  end 
end

function safe_dec(prev,dec)
  return (prev-dec)<0 and 0 or prev-dec
end

enqueue=add
function dequeue(queue)
  local v = queue[1]
  del(queue, v)
  return v
end

function target_process()
  local ready=cocreate(ready_wait_input)
  local process
  local dispatch={
    ["ra"]=function() target_working("w") end,
    ["la"]=function() target_working("e") end,
    ["da"]=function() target_working("n") end,
    ["ua"]=function() target_working("s") end
  }
  while true do
    if (ready and costatus(ready) != "dead") then
      _,process=coresume(ready,dispatch)
    elseif (process and costatus(process) != "dead") then
      coresume(process)
    else
      ready=cocreate(ready_wait_input)
    end
    yield()
  end
end

function target_working(dir)
  spawn_belt(dir)
  tc.s0,tc.ac="",5 
  tc.aw,tc.ae,tc.an,tc.as=(dir=="e"),(dir=="w"),(dir=="s"),(dir=="n")

  local dtb={n=3,w=1,s=2,e=0} -- dir to button translate
  local dir_vector = {n={0,-1},e={1,0},s={0,1},w={-1,0}}
  local dx,dy=dir_vector[dir][1],dir_vector[dir][2]

  local assist=(player.lvl==1 and player.move_count<3)

  local start_frame=cur_frame
  local timer=1

  -- 1. set input lock
  INPUT_LOCK=true

  sfx(1)

  -- 2. move target
  while timer <= 8 do
    if cur_frame-start_frame >=1 then
      start_frame=cur_frame

      tc.ship_x+=dx*4
      tc.ship_y+=dy*4

      player.x+=dx*0.25
      player.y+=dy*0.25

      new_beacons.xoffset+=dx*3.75
      new_beacons.yoffset+=dy*3.75

      timer+=1
    end
    yield()
  end

  -- 3. add task
  enqueue(TASKS,Task:new(get_c_ast(),dir))

  -- 4. wait for lock to release
  while INPUT_LOCK do
    yield()
  end

end

function thrust_ship(dir)
  --[[   
  beacon grid
    asteroids appear at uppercase letter
    beacons appear at alternating lowercase w and d

     3  4  5  6  7  8  9
     |  ^  |  ^  |  ^  |
  3--w--|--d--|--w--|--d--
     |  V  |  V  |  V  |
  4 <-> A <-> B <-> C <->
     |  ^  |  ^  |  ^  |
  5--d--|--w--|--d--|--w--
     |  V  |  V  |  V  |
  6 <-> D <->[E]<-> F <->
     |  ^  |  ^  |  ^  |
  7--w--|--d--|--w--|--d--
     |  V  |  V  |  V  |
  8 <-> G <-> H <-> I <->
     |  ^  |  ^  |  ^  |
  9--d--|--w--|--d--|--w--
     |  V  |  V  |  V  |

  --]]

  local dtb={n=3,w=1,s=2,e=0} -- dir to button translate
  local dir_vector={n={0,-1},e={1,0},s={0,1},w={-1,0}}
  local dx,dy=dir_vector[dir][1],dir_vector[dir][2]

  local assist=(player.lvl==1 and player.move_count<3)

  local f0=cur_frame
  local start_frame=cur_frame
  local timer=1

  -- thrust ship portion
  timer=1
  sfx(0)
  while timer<=16 do
    if cur_frame-start_frame >=1 then 
      start_frame=cur_frame
      if (timer>5 and timer<11) then
        toggle_beacons(dir,get_tog(f0,cur_frame,3))
      end
      
      if (timer==8) then
        sfx(2)
        if (assist) then
          tc.ac=11
          tc.s0,tc.s2,tc.c0,tc.c2,lines="MOVE","COST",15,15,{0,clvl.lines[5],8}
          while (not btnp(dtb[dir])) do
            toggle_beacons(dir,get_tog(f0,cur_frame,3))
            yield()
          end
          sfx(0)
        end
        decrement_resources(dir)
      end
      if (timer==10) then
        tc.s0,tc.s2="",""
      end
      tc.ship_x-=dx*2
      tc.ship_y-=dy*2
      timer+=1
    end 
    yield()
  end

  INPUT_LOCK=nil
  tc:reset()

  if (assist) lines={0,clvl.lines[player.message_index]}
  new_beacons=spawn_beacons(player.x,player.y,clvl)
end

function vert_ship()
  sfx(0)
  local start_frame,timer,spr0 = cur_frame,1,tc.ship_spr
  local dir=spr0==16 and 1 or -1
  while timer <= 3 do 
    if cur_frame-start_frame >= 2 then
      start_frame=cur_frame
      tc.ship_spr=spr0+timer*dir
      timer+=1
    end
    yield()
  end
end

function sensing_sequence(task)
  local ast = get_c_ast()
  if (task:has_mineral()) then
    local lower=cocreate(vert_ship)
    local water=task.w>0 and cocreate(gather_resource) or nil
    local dirt=task.d>0 and cocreate(gather_resource) or nil
    local m10=task[10]>0 and cocreate(gather_mineral) or nil
    local m14=task[14]>0 and cocreate(gather_mineral) or nil
    local raise=cocreate(vert_ship)
    while true do
      if (lower and costatus(lower) != "dead") then
        coresume(lower)
      elseif (water and costatus(water) != "dead") then
        coresume(water,"w")
      elseif (dirt and costatus(dirt) != "dead") then
        coresume(dirt,"d")
      elseif (m10 and costatus(m10) != "dead") then
        coresume(m10,10,task[10])
      elseif (m14 and costatus(m14) != "dead") then
        coresume(m14,14,task[14])
      elseif (raise and costatus(raise) != "dead") then
        coresume(raise)
      else
        return
      end
      yield()
    end
  end
end

function get_tog(f0,cf,frame_delay)
  return (cf-f0)%(frame_delay*2+1) < frame_delay
end

function redeem_coin(mineral)
  local start_frame = cur_frame
  local timer = 0

  while timer <= 10 do 
    if cur_frame-start_frame >= 1 then
      start_frame = cur_frame
      timer += 1
      sfx(7)
      coin.offset[mineral] = timer
      coin.spr[mineral][1] = 82+timer%2 -- gold
      coin.spr[mineral][2] = 98+timer%2 -- shadow
    end
    yield()
  end

  coin.spr[mineral][1],coin.spr[mineral][2]=82,98
  coin.offset[mineral]=0

  if (mineral==14) then
    player.goal_attain+=2
  else
    player.goal_attain+=1
  end
end

--3text by connor halford
function initfont()
  local top="abcdefghijklmnopqrstuvwxyz"
  local bot="0123456789.,^?()[]:/\\=\"'+-"
  fntsprx=(fntspr%16)*8
  fntspry=flr((fntspr/16))*8
  for i=1,#top do
    x=fntsprx+(i-1)*3
    c=sub(top,i,i)
    fntx[c]=x
    fnty[c]=fntspry
    c=sub(bot,i,i)
    fntx[c]=x
    fnty[c]=fntspry+3
  end
end

function print3(str,x,y,col)
  col=col or fntdefaultcol
  pal(7,col)
  for i=1,#str do
    c=sub(str,i,i)
    if fntx[c] then
      sspr(fntx[c],fnty[c],3,3,x+(i-1)*4,y)
    else
      print(c,x+(i-1)*4,y-2,col)
    end
  end
  pal()
end

function str_to_table(delim,tbl_str,isnum)
  return split(tbl_str,delim or "",isnum)
end

function load_lvl(enc_lvl)
  local rt={}

  local temp_t=str_to_table("@",enc_lvl)

  rt.goal=tonum(temp_t[1])
  rt.ring_size=tonum(temp_t[2])
  rt.distance=tonum(temp_t[3]) 
  rt.weather=tonum(temp_t[4])
  rt.lines=str_to_table(",",temp_t[5])

  local rings_t=str_to_table("=",temp_t[6])

  for rs in all(rings_t) do
    local curr_ring={}
    local all_dist_t = str_to_table(",",rs)
    
    curr_ring.exist  = str_to_table(nil,all_dist_t[1])
    curr_ring.prim_c = str_to_table(nil,all_dist_t[2])

    curr_ring.sec_c = {}
    for sec in all(str_to_table("|",all_dist_t[3])) do
      add(curr_ring.sec_c,str_to_table(nil,sec))
    end

    curr_ring.vol = {}
    for vol in all(str_to_table("|",all_dist_t[4])) do
      add(curr_ring.vol,str_to_table(nil,vol))
    end

    curr_ring.water = {}
    for w in all(str_to_table("|",all_dist_t[5])) do
      add(curr_ring.water,str_to_table(nil,w))
    end

    curr_ring.dirt={}
    for d in all(str_to_table("|",all_dist_t[6])) do
      add(curr_ring.dirt,str_to_table(nil,d))   
    end
    add(rt,curr_ring)
  end
  return rt 
end

function init_asteroid()
  for r=-2,2,2 do
    for c=-2,2,2 do
      if (r~=0 and c~=0) add_new_ast(player.x+r,player.y+c)
    end
  end
  ast_log[hkey(pairing(player.x,player.y))] = true -- always start on blank
end

--- discrete distribution sampling helpers
function build_dist(dist)
  local rl={}
  local t=0
  for e,v in pairs(dist) do
    t+=tonum(v) -- may come in as a string
    add(rl,{[0]=e,t})
  end
  return {[0]=t,rl}
end

function get_from_dist(dl)
  local pag=rnd(dl[0]) -- aggregate value
  for v in all(dl[1]) do
    if (v[1]>= pag) return v[0]
  end
end

function add_new_ast(qx,qy)
  if (qx!=px0 and qy!=py0) then
    srand(abs(pairing(qx,qy))+gseed)
    local ring =
      flr((flr(sqrt((px0-qx)*(px0-qx)+(py0-qy)*(py0-qy)))+.01)/clvl.ring_size)%#clvl+1
    local clvl_ring = clvl[ring]

    if (get_from_dist(build_dist(clvl_ring.exist))==2 and 
        not in_view(qx,qy)) then

      local pc = get_from_dist(build_dist(clvl_ring.prim_c )) -- primary
      local sc = get_from_dist(build_dist(clvl_ring.sec_c[pc]))   -- secondary
      local lower_scale = vols[get_from_dist(build_dist(clvl_ring.vol[pc]))]/100
      local w = get_from_dist(build_dist(clvl_ring.water[pc]))-1 -- water
      local d = get_from_dist(build_dist(clvl_ring.dirt[pc]))-1 -- dirt

      if(ast_log[hkey(pairing(qx,qy))]) pc,sc = 3,3  -- empty

      load_ast(
        ast_vertices(lower_scale),
        ast_faces,
        qx,qy,0,
        0,-.35,0,
        false,
        {pc,sc},
        lower_scale,
        w,
        d
      )

    end
  end
end

-- scales vertex dimension
function sv(lower_scale) 
  return rnd(0.5)+lower_scale
end

function ast_vertices(lower_scale)
  return  {
    {0,-sv(lower_scale),-sv(lower_scale)},
    {0,sv(lower_scale),-sv(lower_scale)},
    {0,sv(lower_scale),sv(lower_scale)},
    {0,-sv(lower_scale),sv(lower_scale)},
    {-sv(lower_scale),-sv(lower_scale),0},
    {sv(lower_scale),-sv(lower_scale),0},
    {sv(lower_scale),sv(lower_scale),0},
    {-sv(lower_scale),sv(lower_scale),0},
    {-sv(lower_scale),0,-sv(lower_scale)},
    {-sv(lower_scale),0,sv(lower_scale)},
    {sv(lower_scale),0,sv(lower_scale)},
    {sv(lower_scale),0,-sv(lower_scale)}
  }
end
function in_view(px,py) -- leaving out z since will be constant
  for ca in all(ast_list) do
    if (ca.x==px and ca.y==py) return true
  end
  return false
end

function spawn_belt(dir)
  for c=-2,2,2 do
    if (dir=="w") then -- moving left so adding to the right
      add_new_ast(player.x-4,player.y+c)  -- top
      set_ast_cull(player.x+4,player.y+c)
    elseif (dir=="e") then
      add_new_ast(player.x+4,player.y+c)  -- top
      set_ast_cull(player.x-4,player.y+c)
    elseif (dir=="n") then
      add_new_ast(player.x+c,player.y-4)
      set_ast_cull(player.x+c,player.y+4)
    elseif (dir=="s") then
      add_new_ast(player.x+c,player.y+4)
      set_ast_cull(player.x+c,player.y-4)
    end
  end
end

function gafc(xp,y)-- get_addr_from_coord(x,y)
  return 0x6000+64*y+xp
end

function level_init()
  purge_all=false 
  gseed=stat(95)+stat(94)+stat(93)+stat(0)

  -- global objects --

  tc=Target:new() -- center text
  
  coin={spr={[10]={82,98},[14]={82,98}},offset={[10]=0,[14]=0}}

  player.x=px0--2000   --0
  player.y=py0--3000    --8
  player.d=72--72 -- dirt 
  player.w=72--72 -- water
  player.sensor=(player.lvl==1) and {[10]=30,[14]=30} or {[10]=2,[14]=2} 
  player.move_count=0
  player.message_index=1
  player.goal_attain=0

  clvl=load_lvl(lvl_list[player.lvl]) -- current level
  clvl.seed=gseed 

  new_beacons=spawn_beacons(player.x,player.y,clvl)

  lines={}  -- console content
  lines={0,clvl.lines[1]}

  init_light()

  ast_list={}    -- stores asteroid belt
  ast_log={}     -- which asteroids have been mined/sold
  -- TODO pass in clvl
  init_asteroid()   -- starting set
end

function level_over()
  local over_reason=false
  if (player.w<=0) over_reason="water"
  if (player.d<=0) over_reason="dirt"
  if (player.goal_attain>=clvl.goal) over_reason="goal"
  if (over_reason=="goal" and player.lvl>=#lvl_list) over_reason="win"
  return over_reason
end

function update_objects()
  generate_matrix_transform(cam_ax,cam_ay,cam_az)
  matrix_inverse()
  vx,vy,vz=rotate_point(0,0,.2)
  cam_x=player.x
  cam_y=player.y+.2
  cam_z=player.z
  cam_ax=player.ax
  cam_ay=player.ay
  cam_az=player.az
  generate_cam_matrix_transform(cam_ax,cam_ay,cam_az)

  triangle_list={}

  for ast in all(ast_list) do
    ast.ax+=.005--.005--flr(rnd(10))/1800
    ast.az+=.015--.015
    update_visible(ast)
    transform_object(ast)
    cam_transform_object(ast)
    update_light()
     if (ast.cull or purge_all) then
      del(ast_list,ast)
    elseif (ast.visible) then
      render_object(ast)
    end
  end
  quicksort(triangle_list)
end

--- helper functions ---
function hkey(pv)
  return (pv<0) and "n"..tostr(pv) or "p"..tostr(pv)
end

function set_ast_cull(x,y)
  for o in all(ast_list) do
    if (o.x==x and o.y==y) o.cull=true
  end
end

-- pairing function
-- limits roughly -180,180
-- roughly distance 254
function pairing(x,y)
  x,y = flr(x/2),flr(y/2) -- translating to 1 step
  local xa = (x>=0) and 2*x or 2*x-1
  local ya = (y>=0) and 2*y or 2*y-1
  if (xa>=ya) then
    return xa*xa+xa+ya
  else
    return xa+ya*ya
  end
end

function get_c_ast()
  for ca in all(ast_list) do
    if (ca.x==player.x and ca.y==player.y) return ca
  end
  return nil
end

function draw_display()
  draw_message_box()
  draw_upper()
  draw_vert_meters()
  draw_console()
end

function printv(s,x0,y0,c)
  for i=0,#s-1 do
    print3(sub(s,i+1,i+1),x0,y0+(i*4),c)
  end
end

function draw_goal()
  for i=0,clvl.goal-1 do
    local gspr=(player.goal_attain-i > 0) and 100 or 82
    pal(2,1)
    spr(98,i*4+91,12)
    pal(2,3)
    spr(gspr,i*4+90,11)
  end
end

function draw_target()

  pal(5,tc:get_color()) -- arrow colors shared
  pal(7,3)
  if(tc.an) spr(8,60,53,1,1,false,true) -- north
  if(tc.aw) spr(7,50,62,1,1,false,true) -- west
  if(tc.as) spr(8,59,72,1,1,true,false) -- south
  if(tc.ae) spr(7,69,63,1,1,true,false) -- east
  pal()

  if(tc.s0!="") then
    rectfill(tc.ship_x-#tc.s0*2+5,tc.ship_y-3,tc.ship_x-#tc.s0*2+4+#tc.s0*4,tc.ship_y+1,1)
    print(tc.s0,tc.ship_x-#tc.s0*2+5,tc.ship_y-4,tc.c0)
  end

  if(tc.s2!="") then
    rectfill(tc.ship_x-#tc.s2*2+5,tc.ship_y+11,tc.ship_x-#tc.s2*2+4+#tc.s2*4,tc.ship_y+14,1)
    print(tc.s2,tc.ship_x-#tc.s2*2+5,tc.ship_y+9,tc.c2)
  end

  --spr(tc.ship_spr,tc.ship_x+1,tc.ship_y+2+1)
  --pal(2,14)
  spr(tc.ship_spr,tc.ship_x,tc.ship_y+2)

end

-- cost beacons
function draw_beacon_nums()
  local x0,y0 = flr(new_beacons.xoffset)+2,flr(new_beacons.yoffset)+2
  for col=1,13,2 do
    -- beacon
    for row=1,13,2 do
      local beacon=new_beacons[col][row]
      if (beacon.toggle) pal({[13]=8,[6]=14})
      -- ring
      spr(1,x0+col*15-5-30,y0+row*15+1-5-30+2,1,1,true,true)
      spr(1,x0+col*15-30,y0+row*15+1-30+2)
      pal()
      -- number
      print(
        (player.w>0 and player.d>0) and beacon.value or "?",
        x0+col*15-30,
        y0+row*15-30+2,
        beacon.color
      )
      -- edge
      pal(8,5)
      spr(3,x0+col*15+1-30,y0+row*15+8-30+2)
      spr(3,x0+col*15+1-30,y0+row*15-10-30+2)
      spr(4,x0+col*15+7-30,y0+row*15+2-30+2)
      spr(4,x0+col*15-11-30,y0+row*15+2-30+2)
      pal()
    end
  end
end

function draw_message_box()
  -- barriers
  fillp(0b1111000011110000.1)
  rectfill(16,16,111,111,1)
  fillp(0b1010101010101010.1)
  rectfill(16,16,111,111,0)
  fillp(0)

  rectfill(0,0,17,127,0)       -- left
  rectfill(109,0,127,127,0) -- right
  rectfill(0,0,127,20,0)       -- top
  rectfill(0,112,127,127,0) -- bot

  draw_beacon_nums()
  draw_target() -- new place for draw_target

  rectfill(0,0,16,127,0)       -- left
  rectfill(110,0,127,127,0) -- right
  rectfill(0,0,127,18,0)       -- top
  rectfill(0,114,127,127,0) -- bot

end

-- prints contents of the global lines
function draw_console()
  local cy=116
  local raw_text=lines[2]
  local ti=lines[1]
  local cursor=1
  local buffer=""

  -- first line that can horiz scroll
  if (#raw_text>27) then
    while cursor < 29 do
      buffer = buffer .. sub(raw_text,ti%#raw_text+1,ti%#raw_text+1)
      ti += 1
      cursor += 1
    end
  else
    buffer=raw_text 
  end
  print("8888888888888888888888888888",8,cy,1)
  --print("8888888888888888888888888888",8,cy+6,1)
  print(buffer,8,cy,lines[3] or 15)

  -- second interface line
  cy +=6
  --print(lines[4] or "  \151restart",36,cy,13)
end

function draw_upper()
  print("level",26,13,1)
  print("level",25,12,13)
  print(" "..tostr(player.lvl)..":"..#lvl_list,46,13,1)
  print(" "..tostr(player.lvl)..":"..#lvl_list,45,12,15)

  print("goal",75,13,1)
  print("goal",74,12,13)
  draw_goal()
  pal({[4]=2,[6]=2})
  spr(128,27,1,12,2)
  pal()
  pal(4,13)
  spr(128,26,0,12,2)
end

function draw_vert_meters()

  fillp(0b1111000011110000.1)
  
  printv("shield",114,15,
    player.d>16 and 2 or (get_tog(tc.f0,cur_frame,6) and 8 or 2))
  printv("shield",113,14,15)

  printv("fuel",120,23,
    player.w>16 and 2 or (get_tog(tc.f0,cur_frame,6) and 8 or 2))
  printv("fuel",119,22,15)

  rectfill(113,110-72,116,110,1)
  rectfill(119,110-72,122,110,1)

  --water storage
  rectfill(118,110-player.w,121,110,12) -- fill
  -- dirt storage
  rectfill(112,110-player.d,115,110,4) -- fill

  -- sensor
  rectfill(5,110-72,8,110,1)
  rectfill(11,110-72,14,110,1)

  rectfill(4,110-player.sensor[10],7,110,10)
  rectfill(10,110-player.sensor[14],13,110,14)

  pal(2,1)
  -- coins
  spr(coin.spr[10][2],3,32-coin.offset[10])
  spr(coin.spr[10][1],2,31-coin.offset[10])

  -- pink
  spr(coin.spr[14][2],9,32-coin.offset[14])
  spr(coin.spr[14][1],8,31-coin.offset[14])

  spr(coin.spr[14][2],9,25-coin.offset[14])
  spr(coin.spr[14][1],8,24-coin.offset[14])

fillp(0)
end

function load_ast(base_object_vertices,base_object_faces,
                  x,y,z,
                  ax,ay,az,
                  obstacle,
                  palette,lower_scale,w,d)

  local new_ast={radius=0,
    visible=false,
    palette=palette,
    rx=0,
    ry=0,
    rz=0,
    tx=0,
    ty=0,
    tz=0,
    sx=0,
    sy=0,
    vx=0,
    vy=0,
    vz=0,
    ax=ax or 0,
    ay=ay or 0,
    az=az or 0,
    x=x or 0,
    y=y or 0,
    z=z or 0,
    faces={},
    base_faces=base_object_faces,
    vertices={},
    t_vertices={},
    vertices=base_object_vertices,
    lower_scale = lower_scale,
    w = w,
    d = d
  }

  -- build palette distribution
  local pal_dist = {[allp[palette[1]]]=6,[allp[palette[2]]]=4,[6]=10,[5]=2}
  if (w>0) pal_dist[12]=2 -- add some water
  if (d>0) pal_dist[4]=4
  new_ast.pal_dist = build_dist(pal_dist)

  --make local deep copy of faces
  for i=1,#base_object_faces do
    new_ast.faces[i]={}
    for j=1,#base_object_faces[i] do
      new_ast.faces[i][j]=base_object_faces[i][j]
    end
  end

  --make local deep copy of translated vertices. we share the initial vertices
  for i=1,#base_object_vertices do
    new_ast.t_vertices[i]={}
      for j=1,3 do
        new_ast.t_vertices[i][j]=new_ast.vertices[i][j]
      end
  end

  transform_object(new_ast)
  set_radius(new_ast)
  add(ast_list,new_ast)
end

--- modified creamdog rasterizer
function creamdog_tri(x1,y1,x2,y2,x3,y3,br,pal_dist,w,d)

  local list = {{flr(x1),flr(y1)},{flr(x2),flr(y2)},{flr(x3),flr(y3)}}

  list = sort2dvectors(list)

  local xs = list[1][1] -- start
  local xe = list[1][1] -- end

  local vx1 = (list[2][1]-list[1][1])/(list[2][2]-list[1][2]) 
  local vx2 = (list[3][1]-list[2][1])/(list[3][2]-list[2][2]) 
  local vx3 = (list[3][1]-list[1][1])/(list[3][2]-list[1][2]) 

  if flr((list[2][2]-list[1][2])) == 0 then
    vx2 = vx3
    xe = list[2][1]
    vx3 = (list[3][1]-list[2][1])/(list[3][2]-list[2][2])
  end

  for y=list[1][2],list[3][2],1 do

   if (y >= 0 and y <=127 and y%2 ==0) then -- optimization; only rasterize even
    local x1 = xs
    local x2 = xe
    if (x1 < 0) x1 = 0
    if (x1 > 128) x1 = 128
    if (x2 < 0) x2 = 0
    if (x2 > 128) x2 = 128

    local l = sqrt((x1-x2)*(x1-x2))
    local x0 = xs
    if (xe<xs) x0 = xe
    for i=0,flr(l),2 do
      if (x0+i <= 127 and x0+i >= 0 and y <= 127 and y >= 0) then
        memset(
          gafc(flr((x0+i)/2),y),
          color_list[get_from_dist(pal_dist)][br]+
          0,1 -- optimization to only calc color for even i
          --color_list[get_from_dist(ne)][br]*16,1
        )
      end
    end
  end

   if y < list[2][2] then
    xs += vx1
   elseif y >= list[2][2] then
    xs += vx2
   end
   xe += vx3
  end
  return list
 end

-------BEGIN Electric Gryphon's 3D Library---------------

function get_br(nx,ny,nz)
  return band(
          mid(
            nx*t_light_x+
            ny*t_light_y+
            nz*t_light_z,
            0,
            1
          )*(1-k_ambient)+k_ambient*10,
          0xffff)
end

function init_light()
  light1_x,light1_y,light1_z=normalize(light1_x,light1_y,light1_z)
end

function update_light()
  t_light_x,t_light_y,t_light_z = rotate_cam_point(light1_x,light1_y,light1_z)
end

function normalize(x,y,z)
  local x1=shl(x,2)
  local y1=shl(y,2)
  local z1=shl(z,2)
  local inv_dist=1/sqrt(x1*x1+y1*y1+z1*z1)
  return x1*inv_dist,y1*inv_dist,z1*inv_dist
end

function vector_dot_3d(ax,ay,az,bx,by,bz)
  return ax*bx+ay*by+az*bz
end

function vector_cross_3d(px,py,pz,ax,ay,az,bx,by,bz)
  ax-=px
  ay-=py
  az-=pz
  bx-=px
  by-=py
  bz-=pz

  local dx=ay*bz-az*by
  local dy=az*bx-ax*bz
  local dz=ax*by-ay*bx
  return dx,dy,dz
end

function set_radius(object)
  for vertex in all(object.vertices) do
      object.radius=max(
        object.radius,vertex[1]*vertex[1]+vertex[2]*vertex[2]+vertex[3]*vertex[3])
  end
  object.radius=sqrt(object.radius)
end

function new_triangle(p1x,p1y,p2x,p2y,p3x,p3y,z,c1,pal_dist)
  add(triangle_list,
    {
      p1x=p1x,
      p1y=p1y,
      p2x=p2x,
      p2y=p2y,
      p3x=p3x,
      p3y=p3y,
      tz=z,
      c1=c1, -- brightness
      pal_dist=pal_dist
    }
  )
end

function draw_triangle_list()
  for i=1,#triangle_list do
      local t=triangle_list[i]
      creamdog_tri( t.p1x,t.p1y,t.p2x,t.p2y,t.p3x,t.p3y,
        t.c1, -- brightness
        --t.c2, -- palette
        t.pal_dist, -- # not excluded neighbor colors repeated in palette
        t.w,
        t.d
      )
  end
end

function update_visible(object)
  object.visible=false
  local px,py,pz = object.x-cam_x,object.y-cam_y,object.z-cam_z
  object.tx, object.ty, object.tz =rotate_cam_point(px,py,pz)
  object.sx,object.sy = project_point(object.tx,object.ty,object.tz)
  object.sradius=project_radius(object.radius,object.tz)
  object.visible= is_visible(object)
end

function cam_transform_object(object)
  if(object.visible)then
    for i=1, #object.vertices do
      local vertex=object.t_vertices[i]
      vertex[1]+=object.x - cam_x
      vertex[2]+=object.y - cam_y
      vertex[3]+=object.z - cam_z
      vertex[1],vertex[2],
      vertex[3]=rotate_cam_point(vertex[1],vertex[2],vertex[3])
    end
  end
end

function transform_object(object)
  if(object.visible)then
    generate_matrix_transform(object.ax,object.ay,object.az)
    for i=1, #object.vertices do
      local t_vertex=object.t_vertices[i]
      local vertex=object.vertices[i]
      t_vertex[1],t_vertex[2],t_vertex[3]=
      rotate_point(vertex[1],vertex[2],vertex[3])
    end
  end
end

function generate_matrix_transform(xa,ya,za)
  local sx=sin(xa)
  local sy=sin(ya)
  local sz=sin(za)
  local cx=cos(xa)
  local cy=cos(ya)
  local cz=cos(za)
  mat00=cz*cy
  mat10=-sz
  mat20=cz*sy
  mat01=cx*sz*cy+sx*sy
  mat11=cx*cz
  mat21=cx*sz*sy-sx*cy
  mat02=sx*sz*cy-cx*sy
  mat12=sx*cz
  mat22=sx*sz*sy+cx*cy
end

function generate_cam_matrix_transform(xa,ya,za)
  local sx=sin(xa)
  local sy=sin(ya)
  local sz=sin(za)
  local cx=cos(xa)
  local cy=cos(ya)
  local cz=cos(za)
  cam_mat00=cz*cy
  cam_mat10=-sz
  cam_mat20=cz*sy
  cam_mat01=cx*sz*cy+sx*sy
  cam_mat11=cx*cz
  cam_mat21=cx*sz*sy-sx*cy
  cam_mat02=sx*sz*cy-cx*sy
  cam_mat12=sx*cz
  cam_mat22=sx*sz*sy+cx*cy
end

function matrix_inverse()
  local det = mat00* (mat11 * mat22- mat21 * mat12) -
              mat01* (mat10 * mat22- mat12 * mat20) +
              mat02* (mat10 * mat21- mat11 * mat20)
  local invdet=2/det
  mat00,mat01,mat02,mat10,mat11,mat12,mat20,mat21,mat22=(mat11 * mat22 - mat21 * mat12) * invdet,(mat02 * mat21 - mat01 * mat22) * invdet,(mat01 * mat12 - mat02 * mat11) * invdet,(mat12 * mat20 - mat10 * mat22) * invdet,(mat00 * mat22 - mat02 * mat20) * invdet,(mat10 * mat02 - mat00 * mat12) * invdet,(mat10 * mat21 - mat20 * mat11) * invdet,(mat20 * mat01 - mat00 * mat21) * invdet,(mat00 * mat11 - mat10 * mat01) * invdet
end

function rotate_point(x,y,z)
  return (x)*mat00+(y)*mat10+(z)*mat20,(x)*mat01+(y)*mat11+(z)*mat21,(x)*mat02+(y)*mat12+(z)*mat22
end

function rotate_cam_point(x,y,z)
  return (x)*cam_mat00+(y)*cam_mat10+(z)*cam_mat20,(x)*cam_mat01+(y)*cam_mat11+(z)*cam_mat21,(x)*cam_mat02+(y)*cam_mat12+(z)*cam_mat22
end

  -- update these - these don't appear to be used as you think
function is_visible(object)
  local xl,xr,yu,yd = 28,100,28,100
  if(
    object.tz+object.radius>z_max and
    object.tz-object.radius<z_clip and
    object.sx+object.sradius>xl and
    object.sx-object.sradius<xr and
    object.sy+object.sradius>yu and
    object.sy-object.sradius<yd
  )then return true
  else return false end
end

-- converts to triangles and adds to triangle_list
function render_object(object)

  for i=1, #object.t_vertices do
    local vertex=object.t_vertices[i]
    vertex[4],vertex[5] =
      vertex[1]*k_screen_scale/vertex[3]+k_x_center,
      vertex[2]*k_screen_scale/vertex[3]+k_x_center
  end

  for i=1,#object.faces do

    local face=object.faces[i]

    -- get translated vertices for each face
    local p1=object.t_vertices[face[1]]
    local p2=object.t_vertices[face[2]]
    local p3=object.t_vertices[face[3]]

    local p1x,p1y,p1z=p1[1],p1[2],p1[3]
    local p2x,p2y,p2z=p2[1],p2[2],p2[3]
    local p3x,p3y,p3z=p3[1],p3[2],p3[3]

    local cz=.01*(p1z+p2z+p3z)/3
    local cx=.01*(p1x+p2x+p3x)/3
    local cy=.01*(p1y+p2y+p3y)/3

    local z_paint= -cx*cx-cy*cy-cz*cz

    face[6]=z_paint

    if((p1z>z_max or p2z>z_max or p3z>z_max))then
      if(p1z< z_clip and p2z< z_clip and p3z< z_clip)then

        --simple option -- no clipping required
        local s1x,s1y = p1[4],p1[5]
        local s2x,s2y = p2[4],p2[5]
        local s3x,s3y = p3[4],p3[5]

        if(
            max(s3x,max(s1x,s2x))>0 and
            min(s3x,min(s1x,s2x))<128
          ) then

          if(((s1x-s2x)*(s3y-s2y)-(s1y-s2y)*(s3x-s2x)) < 0) then

            p2x-=p1x p2y-=p1y p2z-=p1z
            p3x-=p1x p3y-=p1y p3z-=p1z

            -- brightness prep
            local nx = p2y*p3z-p2z*p3y
            local ny = p2z*p3x-p2x*p3z
            local nz = p2x*p3y-p2y*p3x
            nx=shl(nx,2) ny=shl(ny,2) nz=shl(nz,2)
            local inv_dist=1/sqrt(nx*nx+ny*ny+nz*nz)
            nx*=inv_dist ny*=inv_dist nz*=inv_dist      

            new_triangle(
                s1x,s1y,
                s2x,s2y,
                s3x,s3y,
                z_paint,
                get_br(nx,ny,nz),
                object.pal_dist
            )

          end
        end

        elseif(p1z< z_clip or p2z< z_clip or p3z< z_clip)then

          p1x,p1y,p1z,p2x,p2y,p2z,p3x,p3y,p3z =
            three_point_sort(p1x,p1y,p1z,p2x,p2y,p2z,p3x,p3y,p3z)

          -- brightness prep
          local nx = p2y*p3z-p2z*p3y
          local ny = p2z*p3x-p2x*p3z
          local nz = p2x*p3y-p2y*p3x
          nx=shl(nx,2) ny=shl(ny,2) nz=shl(nz,2)
          local inv_dist=1/sqrt(nx*nx+ny*ny+nz*nz)
          nx*=inv_dist ny*=inv_dist nz*=inv_dist      

          if(p1z<z_clip and p2z<z_clip)then

            local n2x,n2y,n2z = z_clip_line(p2x,p2y,p2z,p3x,p3y,p3z,z_clip)
            local n3x,n3y,n3z = z_clip_line(p3x,p3y,p3z,p1x,p1y,p1z,z_clip)

            local s1x,s1y = project_point(p1x,p1y,p1z)
            local s2x,s2y = project_point(p2x,p2y,p2z)
            local s3x,s3y = project_point(n2x,n2y,n2z)
            local s4x,s4y = project_point(n3x,n3y,n3z)

            if( max(s4x,max(s1x,s2x))>0 and min(s4x,min(s1x,s2x))<128)  then
              new_triangle(
                s1x,s1y,s2x,s2y,s4x,s4y,z_paint,
                get_br(nx,ny,nz),
                object.pal_dist
              )
            end

            if( max(s4x,max(s3x,s2x))>0 and min(s4x,min(s3x,s2x))<128)  then
              new_triangle(
                s2x,s2y,s4x,s4y,s3x,s3y,z_paint,
                get_br(nx,ny,nz),
                object.pal_dist
              )
            end
          else
            local n1x,n1y,n1z = z_clip_line(p1x,p1y,p1z,p2x,p2y,p2z,z_clip)
            local n2x,n2y,n2z = z_clip_line(p1x,p1y,p1z,p3x,p3y,p3z,z_clip)
            local s1x,s1y = project_point(p1x,p1y,p1z)
            local s2x,s2y = project_point(n1x,n1y,n1z)
            local s3x,s3y = project_point(n2x,n2y,n2z)
            if( max(s3x,max(s1x,s2x))>0 and min(s3x,min(s1x,s2x))<128)  then
              new_triangle(
                s1x,s1y,s2x,s2y,s3x,s3y,z_paint,
                get_br(nx,ny,nz),
                object.palette,
                object.pal_dist
              )
            end
          end
        end
      end
    end
end

function three_point_sort(p1x,p1y,p1z,p2x,p2y,p2z,p3x,p3y,p3z)
  if(p1z>p2z) p1z,p2z = p2z,p1z p1x,p2x = p2x,p1x p1y,p2y = p2y,p1y
  if(p1z>p3z) p1z,p3z = p3z,p1z p1x,p3x = p3x,p1x p1y,p3y = p3y,p1y
  if(p2z>p3z) p2z,p3z = p3z,p2z p2x,p3x = p3x,p2x p2y,p3y = p3y,p2y
  return p1x,p1y,p1z,p2x,p2y,p2z,p3x,p3y,p3z
end

function quicksort(t, start, endi)
  start, endi = start or 1, endi or #t
 if(endi - start < 1) then return t end
 local pivot = start
 for i = start + 1, endi do
  if t[i].tz <= t[pivot].tz then
    if i == pivot + 1 then
      t[pivot],t[pivot+1] = t[pivot+1],t[pivot]
    else
      t[pivot],t[pivot+1],t[i] = t[i],t[pivot],t[pivot+1]
    end
    pivot = pivot + 1
  end
 end
  t = quicksort(t, start, pivot - 1)
 return quicksort(t, pivot + 1, endi)
end

function z_clip_line(p1x,p1y,p1z,p2x,p2y,p2z,clip)
  if(p1z>p2z)then
    p1x,p2x=p2x,p1x
    p1z,p2z=p2z,p1z
    p1y,p2y=p2y,p1y
  end

  if(clip>p1z and clip<=p2z)then
    alpha= abs((p1z-clip)/(p2z-p1z))
    nx=lerp(p1x,p2x,alpha)
    ny=lerp(p1y,p2y,alpha)
    nz=lerp(p1z,p2z,alpha)
    return nx,ny,nz
  else
    return false
  end
end

function project_point(x,y,z)
  return x*k_screen_scale/z+k_x_center,y*k_screen_scale/z+k_x_center
end

function project_radius(r,z)
  return r*k_screen_scale/abs(z)
end

function lerp(a,b,alpha)
 return a*(1.0-alpha)+b*alpha
end

function sort2dvectors(list)
  for i=1,#list do
  for j=1,#list do
   if i != j then
    local x1 = list[i][1]
    local y1 = list[i][2]
    local x2 = list[j][1]
    local y2 = list[j][2]
    if y2 > y1 then
     local tmp = list[i]
     list[i] = list[j]
     list[j] = tmp
    elseif y2 == y1 then
     if x2 > x1 then
     local tmp = list[i]
     list[i] = list[j]
     list[j] = tmp
     end
    end
   end
  end
  end
  return list
 end

-------------END Electric Gryphon's 3D Library-----------------

--- DATA --

--static icosohedran face definition
astf="3,7,8@8,7,2@12,1,2@1,9,2@5,10,9@9,10,8@10,4,3@11,3,4@6,12,11@12,7,11@1,6,5@6,4,5@7,3,11@7,12,2@2,9,8@10,3,8@4,6,11@1,12,6@4,10,5@1,5,9"
--- level definition ---
lvl_list={
  "3@".. -- level goal
  "6@".. -- ring size
  "2@".. -- water use upper bound : distance
  "2@".. -- dirt use upper bound : solar wind
  "    ...arrow keys move your ship - blue water asteroids refuel your ship...   ,"..
  "    ...brown regolith asteroids fix your shields...   ,"..
  "    ...yellow and pink asteroids are mined and sold for coins...   ,"..
  "       collect coins!,"..
  "    ...moving decreases fuel and shield... press arrow to continue...  @"..
  -- first ring
  "24,".. -- exist
  "001,"..--"001,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12341|12341|12342," .. -- volume as f(primary)
  "10|10|09," .. -- water f(primary)
  "10|10|10=".. --dirt as f(primary)
  -- second ring
  "21,".. -- exist
  "001,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12341|12311|12311," .. -- volume as f(primary)
  "10|10|10," .. -- water f(primary)
  "10|10|01=".. --dirt as f(primary)
  -- third ring
  "32,".. -- exist
  "221,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12311|12311|12311," .. -- volume as f(primary)
  "10|10|09," .. -- water f(primary)
  "10|20|09"
-- stepping stone easy
,"3@3@2@2@  level loaded get mining!@14,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=41,112,111|121|111,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone medium
,"3@3@2@2@  stepping stones in space@13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,332,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone medium 2
,"3@3@2@5@  solar storms hurt shield@13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,332,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone hard
,"5@3@3@3@ fewer minerals more fun @13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,112,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- barren stripe
,"5@6@5@5@  so far away each rock  @13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,113,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
}

colors = "0,0,0,1,1@0,1,1,2,2@0,1,1,3,3@0,1,1,4,4@0,0,1,5,5@0,5,5,6,6@5,5,6,7,7@0,2,2,2,2@2,2,4,4,9@1,1,1,10,10@0,1,1,3,3@0,1,1,12,12@1,1,5,5,13@1,1,2,14,14@4,4,9,9,15"

allp={14,10,6}
vols={8,13,18,23,28}
m_names={"PINK","YELLOW"}
sequence_config={
  water = {"FUEL","EMPTY","        restarting!",8},
  dirt = {"SHIELD","DOWN!","        restarting!",9},
  restart = {"START","OVER!","        restarting!",10},
  goal = {"NEXT","LEVEL","    loading new level...",11}
}


__gfx__
000000000000d00000000000800000008080808001110000000000000000000000000000000000000eee00000aaa000000000000000000000000000000000000
0000000000006dd000000000000000000000000010001000000000000070000000000000777770001555100019991000000bb300100010001eee10000006b300
000000000000d00000000000800000000000000011111000000000070750000000000000777770001111100011111000000bb30010001000111110000006b300
000000000000000000000000000000000000000000000000000000077500000000000000777770000000000000000000000bb30000000000000000000006b300
00000000000000000000000080000000000000000000000000000007075000000000000077777000000000000000000000bb33300000000000000000006bb330
00000000d6d000000000000000000000000000000000000000000000007000000750570077777000000000000000000000b333300000000000000000006bb330
000000000d000000000000008000000000000000000000000000000000000000007570007777700000000000000000000b300033000000000000000006b00033
000000000d0000000000000000000000000000000000000000077700000000000007000077777000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000050005000050000000000000000000dd1000500000000000000000000000001dd00000000
0006b30000000000000000000000000000000000000000000000000050005000055000000005555500000551000d000000000000000500000000015500000000
0006b3000000000000000000000000000000000000000000000000005505500005d0000000005d5000151551d01d10d000015150000d00000000015500000000
0006b3000000000000000000000000000000000000000000000000000565000005500000000000005dd100505051505005dd1000001d10000000005000000000
006bb3300003b0000000000000000000000000000000000000000000056500000500000000000000001515510010100000015150005150000000015500000000
006bb3300003b00000000000000000000000000000000000000000000050000000000000000000000000055105ddd50000000000001010000000015500000000
06b000330003b0000000b0000000000000000000000000000000000000000000000000000000000000000dd1050005000000000000505000000001dd55505550
0000000000300b000000b00000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000
0200b0020b0000030b000003000000030200b0020200b0020200b0020200b0020200b0020200b0020200b0020000000000000000000000000000000000000000
000000000000b3000000b30000b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00029200000bb000000bb0000000b000000292000002920000029200000292000002920000029200000292000000000000000000000000000000000000000000
000929000b0bb3030b0bb303000bb300000929000009290000092900000929000009290000092900000929000000000000000000000000000000000000000000
00029200000b3300000b3300000b3300000292000002920000029200000292000002920000029200000292000000000000000000000000000000000000000000
0b00000000b3333000b3333000b303300b0000000b0000000b0000000b0000000b0000000b0000000b0000000000000000000000000000000000000000000000
020300320b3000330030003000000000020300320203003202030032020300320203003202030032020300320000000000000000000000000000000000000000
0000000000000000b000300003000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b0000000b0000030b000003b0000030000000030200b002000000000000000000000000000000000000000000000000000000000000000000000000
000000000000b3000000b3000000b3000000b00000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000bb300000bb000000bb000000bb0000000b00000029200000000000000000000000000000000000000000000000000000000000000000000000000
00000000000bb3030b0bb3030b0bb303b00bb300000bb30000092900000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bb3300000b3300000b3300000b3300000b330000029200000000000000000000000000000000000000000000000000000000000000000000000000
0000000000b3333000b3333000b3333000b3333000b303300b000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b3000330b30003300300030003000000000000002030032000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000b0003000000000030300030000000000000000000000000000000000000000000000000000000000000000000000000000000000
07077077777077777777070777700770770077777777777777777707777770770770770770777000000000000000000000000000000000000000000000000000
77777770070777077070777707070777070077770770777777770007007070770777707077707000000000000000000000000000000000000000000000000000
70777777777077770077770777777770777770770777770000770077007077707077770707007700000000000000000000000000000000000000000000000000
77777077077770707770077707777700000007077707007077007707000770077770707007000000000000000000000000000000000000000000000000000000
70707007007777707077700777777700007070707770000770000700007007000070707077777700000000000000000000000000000000000000000000000000
77777707777700777077700777700707070000007007007077007707070000777700000007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000005d5000000000000000000000008c8c8c8c8c8c8c80000000000000000
000a900000099000000070000000700000000000000000000000000000000000000500555550050000000000000000000c000000e000005c0000000000000000
00aa79000007a00000077900000070000000000000000000000000000000000000555555d5555550000000000000000008000000000000080000000000000000
00aa79000007a000000aa9000000a0000000000000000000000000000000000000dddd5d5d5dddd000000000000000000c0000000000000c0000000000000000
000a900000099000000aa9000000a0000000000000000000000000000000000000555555d5555550000000000000000008000000000000080000000000000000
0000000000000000000090000000900000000000000000000000000000000000000505555555050000000000000000000c0000000000000c0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000555d5550000000000000000000008000000000000080000000000000000
0000000000000000000000000000000000000000000000000000000000000000000225555555220000000000000000000c0000000000000c0000000000000000
000000000000000000000000000000000000000000000000000000000000000000555555d5555550000000000000000008000000000000080000000000000000
0002200000022000000020000000200000000000000000000000000000000000000555555555550000000000000000000c0000000000000c0000000000000000
002222000002200000022200000020000000000000000000000000000000000000000555d5550000000000000000000008000000000000080000000000000000
0022220000022000000222000000200000000000000000000000000000000000000005055505000000000000000000000c0000000000000c0000000000000000
000220000002200000022200000020000000000000000000000000000000000000000505d5050000000000000000000008000000000000080000000000000000
0000000000000000000020000000200000000000000000000000000000000000000005055505000000000000000000000c0000000000000c0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000505d5050000000000000000000008000000000000080000000000000000
0000000000000000000000000000000000000000000000000000000000000000000005055505000000000000000000000c0000000000000c0000000000000000
000770000000d0000000000005050500000000000000000000000000000000000000000505000000000000000000000008000000000000080000000000000000
00777700000ddd00000000000055500000555000000000050000000005000000000005055505000000000000000000000c0000000000000c0000000000000000
0777777000ddddd00050005000ddd000000d00000300dd5500000000050000000000050555050000000000000000000008000000000000080000000000000000
777007770ddddddd00005055000d0000003d0000223dddd10000505005000000000005050505000000000000000000000c0000000000000c0000000000000000
77700777ddddddd000500050000d0000000300000300dd5500050005550000000000050555050000000000000000000008000000000000080000000000000000
077777700ddddd0000000000000d0000000d3000000000050000000005000000000005055505000000000000000000000c0000000000000c0000000000000000
0077770000ddd0000000000000ddd000000d30000000000000050005050000000000055555550000000000000000000008000000000000080000000000000000
00077000000d00000000000000555000000d3000000000000000505005000000055555555555555500000000000000000c8c8c8c8c8c8c8c0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444444000444444440000444444000444444000444000000044400444444444004440044400000000000000000000000000000000000000000000000000000
04646666400464666640044466664004666666400464000000046400466666664004640046400000000000000000000000004444400000000000666660000000
04644446400464444440046444444004644446400464000000046400444444444004640046400000000000000000000000046666640000000006444440000000
04640046400464000000046400000004640046400464000000046400000464000004644446400000000000000000000000046444664000000006400044000000
04644446400464444400046400000004640046400464000000046400000464000004646646400000000000000000000000046400464000000006400064000000
04646666400464000000046400444004640046400464000000046400000464000004644446400000000000000000000000046400464000000006400064000000
04644664000464444440046444464004644446400464444440046400000464000004640046400000000000000000000000046444664000000006466644000000
04640466400464666640044466664004666666400464666640046400000464000004640046400000000000000000000000046666640000000006444440000000
04440044400444444440000444444000444444000444444440044400000444000004440044400000000000000000000000046444664000000006444000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046400464000000006404400000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046400464000000006400440000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000046400464000000006400044000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000040000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04444444000444444440000444444000444444000444000000044400444444444004440044400000000000000000000000000000000000000000000000000000
04646666400464666640044466664004666666400464000000046400466666664004640046400000000000000000000000000000000000000000000000000000
04644446400464444440046444444004644446400464000000046400444444444004640046400000000000000000000000000000000000000000000000000000
04640046400464000000046400000004640046400464000000046400000464000004644446400000000000000000000000000000000000000000000000000000
04644446400464444400046400000004640046400464000000046400000464000004646646400000000000000000000000000000000000000000000000000000
04646666400464000000046400444004640046400464000000046400000464000004644446400000000000000000000000000000000000000000000000000000
04644664000464444440046444464004644446400464444440046400000464000004640046400000000000000000000000000000000000000000000000000000
04640466400464666640044466664004666666400464666640046400000464000004640046400000000000000000000000000000000000000000000000000000
04440044400444444440000444444000444444000444444440044400000444000004440044400000000000000000000000000000000000000000000000000000
__sfx__
010b00001f7351e024036000260001600016000060000600006000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00001e0241f735036000200001600013000000000000340003500037000370000000000000273002930000000000000000000000000000000000000000000000000000000000000000000000000000000000
001500000d75416700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000d5140f5110520015200102000b2000520000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
01030000195141b5110b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000195141b511003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010300002551427511003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002a31016320003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
0110000027554175112755117511275511751127551175150d6410463100621046110061200615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000027554175112755117511275511751127551175150d6410463100621046110061200615000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001531413315000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002715417212271531721227153172122715317215000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
014800001a6311a6731a6001a6001a600006000060000600006000060000600006000060000600006000060000600006000000000000000000000000000000000000000000000000000000000000000000000000
014500001933320650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010d0008000453f3001b3003f200007450000300003000030c0000000000000000000c0000000000000000000c0000000000000000000c0000000000000000000c0000000000000000000c000000000000000000
011000041b315246153f3153f3003f3003f3003f3003f3003f3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000101c1151c1151d1251f125201252012521125201151f1251b12517125141151311512115121151211500005000050000500005000050000500005000050000500005000050000500005000050000500005
012000050c02400000000000000030424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000862000000066200000000624006220062200625127000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff00020072400725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff00020374503744007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000000000000000000000000000000000000000000
014f00010073200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070000000
01c800010073200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020070200702007020000000000
010700010d71600704007040070300704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704
010500010d71200705007040070300704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704007040070400704
011000040052400522005220052500504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504
01100000000000000002145020200e11002045021200e01002145020200e11002045021200e010021400e01502140020200e11502040021200e01502140020200e11002045021200e010021450e010021450e010
011000080c7353f3001b3003f2000c725000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400020073300732007320073100732007350073200735007310073100731007310073300733007330073300731007320073100732007310073100731007310073300733007330073300733007330073300733
01a100000000000000000000073300000000000000000000000000000000000007330000000000000000000000000000000000000732000000000000000000000000000000000000073200000000000000000000
__music__
03 10151916
03 15171819
03 191a1b5e
03 1d1c5e44
03 1e5a1610

