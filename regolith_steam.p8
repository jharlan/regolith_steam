pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

color_list = {
    [0]={0,0,0,0,0,0,0,0,0,0},  -- black 0
    {0,0,0,1,1,1,1,13,13,12},
    {0,1,1,2,2,8,8,8,14,14},
    {0,1,1,3,3,3,3,11,11,10},
    {0,1,1,4,4,4,4,9,9,10},     -- brown
    {0,0,1,5,5,5,5,13,13,6},    -- dark_gray
    {0,5,5,6,6,6,6,6,6,7},      -- light_gray
    {5,5,6,7,7,7,7,7,7,7},      -- white 7
    {0,2,2,2,2,8,8,14,14,15},
    {2,2,4,4,9,9,15,15,7,7},    -- orange 9
    {1,1,1,10,10,10,7,7,7,7},   -- yellow 10
    {0,1,1,3,3,11,11,10,10,7},
    {0,1,1,12,12,12,12,6,6,7},
    {1,1,5,5,13,13,6,6,7,7},    -- indigo 13
    {1,1,2,14,14,14,15,15,7,7}, -- pink 14
    {4,4,9,9,15,15,7,7,7,7}     -- peach 15
  }

--static icosohedran face definition
ast_faces =  {
  {3,7,8},
  {8,7,2},
  {12,1,2},
  {1,9,2},
  {5,10,9},
  {9,10,8},
  {10,4,3},
  {11,3,4},
  {6,12,11},
  {12,7,11},
  {1,6,5},
  {6,4,5},
  {7,3,11},
  {7,12,2},
  {2,9,8},
  {10,3,8},
  {4,6,11},
  {1,12,6},
  {4,10,5},
  {1,5,9}
}

function _init()
  cur_frame=0
  max_sensor = 96
  ts = {[0]=0} -- target span in pixels
  target = {[0]={[0]=3,3,3,3}}
  mbc = 9
  px0=0
  py0=0
  fntspr=64
  fntdefaultcol=7
  fntx={}
  fnty={}
  initfont()
  ast_log={}
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

-- font sprite mapping big
font={a=32,b=33,c=34,d=35,e=36,f=37,g=38,h=39,i=40,
j=41,k=42,l=43,m=44,n=45,o=46,p=47,q=48,r=49,s=50,
t=51,u=52,v=53,w=54,x=55,y=56,z=57,[" "]=58,["<"]=59,[">"]=60}

function init_asteroid()
  add_new_ast(player.x-delta,player.y-delta)
  add_new_ast(player.x,player.y-delta)
  add_new_ast(player.x+delta,player.y-delta)

  add_new_ast(player.x-delta,player.y)
  add_new_ast(player.x,player.y)
  add_new_ast(player.x+delta,player.y)

  add_new_ast(player.x-delta,player.y+delta)
  add_new_ast(player.x,player.y+delta)
  add_new_ast(player.x+delta,player.y+delta)

  ast_log[hkey(pairing(player.x,player.y))] = true
end

--- discrete distribution sampling helpers
function build_dist(dist)
  local rl = {}
  local t = 0
  for e,v in pairs(dist) do
    t += v 
    add(rl,{[0]=e,t}) 
  end
  return {[0]=t,rl}
end

function get_from_dist(dl)
  local pag = rnd(dl[0]) -- aggregate value
  for v in all(dl[1]) do
    if (v[1]>= pag) return v[0]
  end
end

function add_new_ast(qx,qy)
  srand(abs(pairing(qx,qy))+gseed) 
  local ring = flr(sqrt((px0-qx)*(px0-qx)+(py0-qy)*(py0-qy)))%zone_size

  if (get_from_dist(build_dist(exist_d[ring]))==1 and not in_view(qx,qy)) then

    local pc = allp[get_from_dist(build_dist(p_color_d[ring]))] -- primary color
    local sc = allp[get_from_dist(build_dist(s_color_d[pc]))]   -- secondary
    local v =  get_from_dist(build_dist(volume_d[pc]))/100      -- volume
    local w =  get_from_dist(build_dist(water_d[pc]))           -- water
    local d =  get_from_dist(build_dist(dirt_d[pc]))            -- dirt

    -- sold TODO: neaten this
    if(ast_log[hkey(pairing(qx,qy))] != nil) then
      pc = 6
      sc = 6
    end

    load_object(
      ast_vertices(v),
      ast_faces,qx,qy,0,0,-.35,0,false,
      {[0]=pc,sc},
      v,
      w,
      d  
    )

  end
end

function spin_asteroids()
  local cur_ast
  for cur_ast in all(object_list) do
    cur_ast.ax += .005--flr(rnd(10))/1800
    --cur_ast.ay += .001 --flr(rnd(10))/1800
    cur_ast.az += .015 
  end
end

-- generates shape and volume
function ast_vertices(ub)
  local sa,sb,ra= .9,1.1,0.5
  return  {
    {0,-sa*(rnd(ra)+ub),-sb*(rnd(ra)+ub)},
    {0,sa*(rnd(ra)+ub),-sb*(rnd(ra)+ub)},
    {0,sa*(rnd(ra)+ub),sb*(rnd(ra)+ub)},
    {0,-sa*(rnd(ra)+ub),sb*(rnd(ra)+ub)},
    {-sa*(rnd(ra)+ub),-sb*(rnd(ra)+ub),0},
    {sa*(rnd(ra)+ub),-sb*(rnd(ra)+ub),0},
    {sa*(rnd(ra)+ub),sb*(rnd(ra)+ub),0},
    {-sa*(rnd(ra)+ub),sb*(rnd(ra)+ub),0},
    {-sb*(rnd(ra)+ub),0,-sa*(rnd(ra)+ub)},
    {-sb*(rnd(ra)+ub),0,sa*(rnd(ra)+ub)},
    {sb*(rnd(ra)+ub),0,sa*(rnd(ra)+ub)},
    {sb*(rnd(ra)+ub),0,-sa*(rnd(ra)+ub)}
  }
end

function in_view(px,py) -- leaving out z since will be constant
  for ca in all(object_list) do  
    if (ca.x==px and ca.y==py) return true
  end
  return false
end

function can_afford(x,y)
  for ast in all(object_list) do  
    if (ast.x==x and ast.y==y and ast.palette[0]!=6 and player.gold<gold_dn_c) then
      return false
    end
  end
  return true
end

-- TODO : this is the dir that asteroids move...opposite to player :(
function spawn_belt(dir)

  if (dir == "w") then -- moving left so adding to the right

    add_new_ast(player.x-delta*2.0,player.y-delta)  -- top
    add_new_ast(player.x-delta*2.0,player.y)        -- middle
    add_new_ast(player.x-delta*2.0,player.y+delta)  -- bot

    set_ast_cull(player.x+delta*2.0,player.y-delta)
    set_ast_cull(player.x+delta*2.0,player.y)
    set_ast_cull(player.x+delta*2.0,player.y+delta)

  elseif (dir == "e") then

    add_new_ast(player.x+delta*2.0,player.y-delta)
    add_new_ast(player.x+delta*2.0,player.y)
    add_new_ast(player.x+delta*2.0,player.y+delta)

    set_ast_cull(player.x-delta*2.0,player.y-delta)
    set_ast_cull(player.x-delta*2.0,player.y)
    set_ast_cull(player.x-delta*2.0,player.y+delta)

  elseif (dir == "n") then

    add_new_ast(player.x-delta,player.y-delta*2.0) -- left 
    add_new_ast(player.x,      player.y-delta*2.0) -- middle
    add_new_ast(player.x+delta,player.y-delta*2.0) -- right

    set_ast_cull(player.x-delta,player.y+delta*2.0)
    set_ast_cull(player.x,      player.y+delta*2.0)
    set_ast_cull(player.x+delta,player.y+delta*2.0)

  elseif (dir == "s") then

    add_new_ast(player.x-delta,player.y+delta*2.0) -- left 
    add_new_ast(player.x,      player.y+delta*2.0) -- middle
    add_new_ast(player.x+delta,player.y+delta*2.0) -- right

    set_ast_cull(player.x-delta,player.y-delta*2.0)
    set_ast_cull(player.x,      player.y-delta*2.0)
    set_ast_cull(player.x+delta,player.y-delta*2.0)

  end
end

function gafc(xp,y)-- get_addr_from_coord(x,y)
  return 0x6000+64*y+xp
end

function update_market()
  for element,data in pairs(mrkt_zone[zone]) do
    local v = data[1]
    del(data,v)
    add(data,v)
  end
end

----------game sequence--------------
function game_sequence()
  g_welcome  = cocreate(welcome_sequence)
  g_active   = cocreate(active_sequence)
  g_over     = cocreate(over_sequence)
  while true do
    if (g_welcome and costatus(g_welcome) != "dead") then
      coresume(g_welcome)
    elseif (g_active and costatus(g_active) != "dead") then
      g_welcome = nil
      coresume(g_active)
    elseif (g_over and costatus(g_over) != "dead") then
      g_active = nil 
      coresume(g_over)
    else
      g_over = nil
      return
    end
    yield()
  end
end

--- game_sequence : welcome_sequence ---
function welcome_sequence()
  mbc = 10
  message_box = "---regolith-    steam"
  purge_all = true
  triangle_list = nil
  player = nil
  welcome_init()

  while (not btnp(0) and not btnp(1) and 
        not btnp(2) and not btnp(3) and 
        not btnp(4) and not btnp(5)) do 
    yield()
  end
end

function welcome_init()
  basic_init()
  days=0
  zone=0
end

function basic_init()
  gseed = stat(95)+stat(93)+stat(7)+stat(1)
  srand(gseed)

  -- ship interface config
  dudm=2
  dm=124
  wudm=2
  wm=124 

  -- ship init
  water_dn_c = 34+flr(rnd(4))
  water_up_c = water_dn_c*2+2+flr(rnd(6))
  dirt_dn_c = 28+flr(rnd(6))
  dirt_up_c = dirt_dn_c*2+2+flr(rnd(4))

  -- gold 
  gm=110
  gudm=16
  gold_dn_c0=8
  gold_dn_c=gold_dn_c0
  gold_up_c=30

  -- sensor
  sm=110
  st=16

  days=1
  distance=0

  zone=1
  zm = 6
  zone_size=12
end

--- game_sequence : active_sequence ---
function active_init()
  basic_init()
  -- electric gryphon 3d library config
  z_clip=-3
  z_max=-50
  k_min_x=0
  k_max_x=128
  k_min_y=0
  k_max_y=128
  k_screen_scale=80
  k_x_center=64
  k_y_center=64

  ---- lighting ---
  k_ambient=.4--.3 -- light strength
  light1_x=.35
  light1_y=.35
  light1_z=.1
  t_light_x=0
  t_light_y=0
  t_light_z=0

  -- player config
  player = new_object()  
  player.x=px0--2000   --0
  player.y=py0--3000    --8
  player.z=5.2  --15

  player.dirt=dm
  player.water=wm
  player.sensor={} -- {{element,amount},{element,amount}...} 
  player.gold=gold_up_c

  init_light()

  -- asteroid belt config - 
  allp={[0]=14,10,11,6}  

  -- allp[0] = pink, allp[1] = yellow, allp[2] = green
  mrkt_zone={
     {
       [14]={ 8,10, 6}
      ,[10]={ 4, 6, 4}
      ,[11]={12, 9,12}
    }
    ,{
       [14]={ 4,12, 4}
      ,[10]={ 6,10, 6}
      ,[11]={ 8, 6,10}
    }
    ,{
       [14]={ 2,14, 2}
      ,[10]={ 6,10, 6}
      ,[11]={ 4, 4,10}
     }
    ,{
       [14]={ 2, 6, 2}
      ,[10]={10,10, 6}
      ,[11]={ 8, 6,10}
     }
    ,{
       [14]={ 2, 2, 6}
      ,[10]={ 6, 2, 2}
      ,[11]={ 4, 4, 4}
     }
    ,{
       [14]={ 2, 2, 6}
      ,[10]={ 6, 2, 2}
      ,[11]={ 4, 4, 4}
     }
  }
  
  -- existence - 12 rings
  exist_d =  {
    [0]={[0]=2,[1]=0}
    ,{[0]=1,[1]=2} -- 1
    ,{[0]=1,[1]=3} -- 2
    ,{[0]=1,[1]=5} -- 3
    ,{[0]=1,[1]=1} -- 4
    ,{[0]=1,[1]=3} -- 5
    ,{[0]=2,[1]=3} -- 6
    ,{[0]=4,[1]=1} -- 7
    ,{[0]=1,[1]=4} -- 8
    ,{[0]=3,[1]=4} -- 9
    ,{[0]=3,[1]=4} -- 10
    ,{[0]=3,[1]=4} -- 11
  }

 -- primary color; allp={[0]=14,10,11}
  p_color_d = {
   [0]={[0]=1,[1]=1,[2]=1,[3]=4}
      ,{[0]=1,[1]=2,[2]=1,[3]=5} -- 1
      ,{[0]=1,[1]=1,[2]=4,[3]=5} -- 2
      ,{[0]=1,[1]=1,[2]=4,[3]=5} -- 3
      ,{[0]=4,[1]=3,[2]=1,[3]=5} -- 4
      ,{[0]=4,[1]=4,[2]=1,[3]=6} -- 5
      ,{[0]=4,[1]=3,[2]=1,[3]=6} -- 6
      ,{[0]=1,[1]=2,[2]=1,[3]=7} -- 7
      ,{[0]=1,[1]=3,[2]=2,[3]=8} -- 8
      ,{[0]=1,[1]=4,[2]=2,[3]=9} -- 9
      ,{[0]=1,[1]=3,[2]=2,[3]=1} -- 10
      ,{[0]=1,[1]=2,[2]=2,[3]=1} -- 11
  }

  -- secondary color
  s_color_d = {
     [14]={[0]=2,[1]=1,[2]=4}
    ,[10]={[0]=1,[1]=2,[2]=1}
    ,[11]={[0]=4,[1]=1,[2]=2}
    ,[6]={[3]=1}
  }

  volume_d = {
     [14]={[13]=1,[18]=1,[23]=1,[28]=4}
    ,[10]={[13]=1,[18]=1,[23]=4,[28]=1}
    ,[11]={[13]=1,[18]=4,[23]=1,[28]=1}
    ,[6]={[13]=1,[18]=4,[23]=3,[28]=4}
  }

  water_d = {
     [14]={[0]=5,[1]=1}
    ,[10]={[0]=1,[1]=4}
    ,[11]={[0]=1,[1]=1}
    ,[6]={[0]=1,[1]=3}
  }

  dirt_d = {
     [14]={[0]=4,[1]=1}
    ,[10]={[0]=1,[1]=4}
    ,[11]={[0]=1,[1]=2}
    ,[6]={[0]=1,[1]=3}
  }

  purge_all = false -- setting this to true will purge object list
  object_list={} -- stores asteroid belt 
  delta = 2      -- distance between asteroids (units term?)

  em0,em1=305,245 -- volume constants; primary and secondary
  ast_log={}      -- which asteroids have been mined/sold
  init_asteroid()   -- starting set 
end

function is_game_active()
  return (player.water > 0 and player.dirt > 0 and zone < zm)
end

function upgrade_sequence()
  mbc=10
  message_box = "--- upgrade--   ship"
  while true do  
    if (btnp(5) and player.water>=4 and player.dirt>=4) then
      water_dn_c -= 2
      dirt_dn_c -= 2
      break
    elseif (btnp(5)) then
      break 
    end
    yield()
  end
  player.dirt=dm
  player.water=wm
  message_box = nil 
  player.gold = gold_up_c
end

function active_sequence()

  message_box = nil
  active_init()

  local dir
  while (is_game_active()) do
    -- ready for input
    if (not s_moving and not s_upgrade) then
      if(btnp(1) and can_afford(player.x-delta,player.y))then     -- w
        dir="w"
        s_moving = cocreate(move_sequence)    
      elseif(btnp(0) and can_afford(player.x+delta,player.y))then -- e
        dir="e"
        s_moving = cocreate(move_sequence)    
      elseif(btnp(3) and can_afford(player.x,player.y-delta))then -- n
        dir="n"
        s_moving = cocreate(move_sequence)    
      elseif(btnp(2) and can_afford(player.x,player.y+delta))then -- s
        dir="s"
        s_moving = cocreate(move_sequence)    
      elseif(player.gold >= gm)then -- available upgrade
        s_upgrade = cocreate(upgrade_sequence)
      end
    end

    if (s_moving and costatus(s_moving) != "dead") then
      coresume(s_moving,dir)
    else
      ts={[0]=0}
      target={[0]={[0]=3,3,3,3}}
      s_moving=nil
    end

    if (s_upgrade and costatus(s_upgrade) != "dead") then
      coresume(s_upgrade)
    else
      s_upgrade=nil
    end

    generate_matrix_transform(cam_ax,cam_ay,cam_az)
    matrix_inverse()
    vx,vy,vz=rotate_point(0,0,.2)
    cam_x=player.x
    cam_y=player.y
    cam_z=player.z
    cam_ax=player.ax
    cam_ay=player.ay
    cam_az=player.az
    generate_cam_matrix_transform(cam_ax,cam_ay,cam_az)

    spin_asteroids()

    for object in all(object_list) do
      update_visible(object)
      transform_object(object)
      cam_transform_object(object)
      update_light()
    end

    triangle_list={}
    quicksort(object_list)
    for object in all(object_list) do
      if (object.cull or purge_all) then
        del(object_list,object)
      elseif (object.visible) then
        render_object(object)
      end
    end
    quicksort(triangle_list)
    yield()
  end
  s_upgrade=nil
  s_moving=nil
end

--- game_sequence : active_sequence : move_sequence ---

function move_sequence(dir)
  spawn_belt(dir)
  m_steam   = cocreate(generate_steam)
  m_move    = cocreate(move_ship)
  s_sensing = cocreate(sensing_sequence)
  while true do
    -- blinking target
    if (cur_frame%2 == 0 ) then
      ts = {[0]=0}
      target = {[0]={[0]=3,3,3,3}}
    else
      ts = {[0]=0}
      target = {[0]={[0]=11,11,11,11}}
    end

    if (m_steam and costatus(m_steam) != "dead") then
      coresume(m_steam)
    elseif (m_move and costatus(m_move) != "dead") then
      m_steam = nil
      coresume(m_move,dir)
    elseif (s_sensing and costatus(s_sensing) != "dead") then
      m_move = nil
      coresume(s_sensing)
    else
      s_sensing = nil

      -- day is over TODO consolidate this
      update_market()
      days+=1
      distance=flr(sqrt((player.x/2-px0)*(player.x/2-px0)+(player.y/2-py0)*(player.y/2-py0)))
      zone = (ceil(distance/zone_size) == 0) and 1 or ceil(distance/zone_size)
      if (zone <=1) then
        gold_dn_c = gold_dn_c0
      else
        gold_dn_c = gold_dn_c0+zone+1
      end

      return
    end
    yield()
  end
end

function gather_water(ast)
  if (ast.w>0) then
    if (player.water+water_up_c >= wm) then
      player.water = wm 
    else
      player.water += water_up_c
    end
  end
end

function gather_dirt(ast)
  if (ast.d>0) then
    if (player.dirt+dirt_up_c >= dm) then
      player.dirt = dm
    else
      player.dirt += dirt_up_c
    end
  end
end

function generate_steam()
  player.water -= water_dn_c
end

function move_ship(dir)
  local mag = delta/8
  player.sensor = {} 
  player.dirt -= dirt_dn_c
  for i=0,7 do
    if (dir == "n") then 
      player.y -= mag
    elseif (dir == "e") then
      player.x += mag
    elseif (dir == "s") then 
      player.y += mag
    elseif (dir == "w") then
      player.x -= mag
    end
    yield()
  end
end

--- game_sequence : active_sequence : move_sequence : sensing_sequence ---

function sensing_sequence()
  local ast = get_c_ast()
  m_water =    cocreate(gather_water)
  m_dirt  =    cocreate(gather_dirt)
  m_elements = cocreate(sense_elements)
  while true do
    if(ast) then
      if (cur_frame%2 == 0 ) then
        ts = {[0]=0,2,4}
        target = {[0]={[0]=11,11,11,11},{[0]=14,14,14,14},{[0]=14,14,14,14}}
      else
        ts = {[0]=0,2}
        target = {[0]={[0]=11,11,11,11},{[0]=7,7,7,7}}
      end
    end
    if (m_water and costatus(m_water) != "dead") then
      coresume(m_water,ast)
    elseif (m_dirt and costatus(m_dirt) != "dead") then
      m_water = nil
      coresume(m_dirt,ast)
    elseif (m_elements and costatus(m_elements) != "dead") then
      m_dirt = nil
      coresume(m_elements,ast)
    else
      m_elements = nil

      -- update sold asteroid
      local pal_dist = {[6]=10,[5]=2} -- base
      if (ast.w>0) pal_dist[12]=2 -- add some water
      if (ast.d>0) pal_dist[4]=4  
      ast.ne = build_dist(pal_dist) -- TODO : name this appropriately
      ast_log[hkey(pairing(ast.x,ast.y))] = true  

      return
    end
    yield()
  end
end

function sense_elements(ast)
  if (ast_log[hkey(pairing(ast.x,ast.y))]==nil and ast.palette[0] != 6) then 
    local pri_amnt,sec_amnt = ast.ub*em0,ast.ub*em1
    player.sensor = {
      [ast.palette[0]]=pri_amnt,
      [ast.palette[1]]=sec_amnt
    }
    player.gold -= gold_dn_c
    if (player.gold +
        pri_amnt/mrkt_zone[zone][ast.palette[0]][2]+
        sec_amnt/mrkt_zone[zone][ast.palette[1]][2] > gm) then
      player.gold = gm
    else
      player.gold += pri_amnt/mrkt_zone[zone][ast.palette[0]][2]
      player.gold += sec_amnt/mrkt_zone[zone][ast.palette[1]][2]
    end
  end
end

--- game_sequence : over_sequence ---

function over_sequence()
  if (player.water <=0) then
    mbc = 8
    message_box = "--- fuel-- depleted "
  elseif (player.dirt <=0) then
    mbc = 8
    message_box = "--- shield-- depleted"
  elseif (zone==zm) then
    mbc = 10
    message_box = "--you won "
  end

  ts = {[0]=0}
  target = {[0]={[0]=0,0,0,0}}
  while (not btnp(4) and not btnp(5)) do
    yield()
  end
end

--- helper functions ---
function hkey(pv)
  return (pv<0) and "n"..tostr(pv) or "p"..tostr(pv)
end

function set_ast_cull(x,y)
  for o in all(object_list) do  
    if (o.x==x and o.y==y) o.cull=true
  end
end

-- pairing function
-- limits roughly -180,180
-- roughly distance 254
function pairing(x,y)
  x,y = flr(x/delta),flr(y/delta) -- translating to 1 step
  local xa = (x>=0) and 2*x or 2*x-1 
  local ya = (y>=0) and 2*y or 2*y-1
  if (xa>=ya) then
    return xa*xa+xa+ya
  else
    return xa+ya*ya
  end
end

-- get current asteroid player is over
function get_c_ast()
  for ca in all(object_list) do 
    if (ca.x==player.x and ca.y==player.y) return ca
  end
  return nil
end

----- Interface Elements -------------

function draw_display()
  draw_message_box()
  --if(player) then
    draw_vert_meters()
    draw_console()
    draw_market()
  --end
end

function sdraw(s,x,y,c)
  local w = 10 
  pal(7,c)
  local xcurs,ycurs = 0,0
  for i=1,#s do
    local tok = sub(s,i,i)
    if (tok == "-") then -- hacky new line
      ycurs+=1
      xcurs=0
    else
      spr(font[tok],x+xcurs*10,y+ycurs*10)
      xcurs+=1
    end
    i+=1
  end
  pal()
end

function pad(s,l)
  if(#s==l) return s
  return "0"..pad(s,l-1)
end

function cl_help(v,s,o,sl,pin)
  local xc,yc
 
  if (o=="v") then 
    s = (v<0) and "s"..s or "n"..s
  else
    s = (v<0) and "w"..s or "e"..s
  end

  for i=1,6 do
    if(o == "v") then
      xc,yc=pin,49+4*i
    else
      xc,yc=48+4*i,pin
    end

    if(i==1) then
      print3(sub(s,i,i),xc,yc,11)
    else
    --  print3(sub(s,i,i),xc,yc,11)
      print3(sub(s,i,i),xc,yc,3)
    end

  end
end

function coord_label()
  --bot
  rectfill(52,109,74,111,0)
  rectfill(16,111,111,111,0)
  --top 
  rectfill(52,17,74,19,0)
  rectfill(16,17,110,17,0)
  --left
  rectfill(16,53,18,75,0)
  rectfill(16,19,16,109,0)
  --right
  rectfill(108,53,110,75,0)
  rectfill(110,19,110,109,0)

  pal(5,3)
  spr(2,18,19)
  spr(2,101,19,1,1,true,false)
  spr(2,18,102,1,1,false,true)
  spr(2,101,102,1,1,true,true)

  local px,slx = pad(tostr(abs(flr(player.x/2))),5),#tostr(abs(flr(player.x/2)))
  local py,sly = pad(tostr(abs(flr(player.y/2))),5),#tostr(abs(flr(player.y/2)))

  cl_help(player.y,py,"v",sly,16)
  cl_help(player.y,py,"v",sly,108)
  cl_help(-1*player.x,px,"h",slx,17)
  cl_help(-1*player.x,px,"h",slx,109)

end

function draw_target()

  -- outer corners
  coord_label()

  -- inner target
  for i=0,#ts do
    if (target[i][0] != 0) then 
      pal(8,target[i][0]) -- nw
      spr(1,48+ts[i]-1,49+ts[i]-1,1,1,false,false) 
    end

    if (target[i][1] != 0) then
      pal(8,target[i][1]) -- ne
      spr(1,72-ts[i],48+ts[i],1,1,true,false) 
    end

    if (target[i][2] != 0) then
      pal(8,target[i][2]) -- sw
      spr(1,48+ts[i]-1,73-ts[i],1,1,false,true)
    end

    if (target[i][3] != 0) then
      pal(8,target[i][3]) -- se
      spr(1,72-ts[i],73-ts[i],1,1,true,true)
    end
  end
  pal()
end

function draw_message_box()
  -- barriers
  fillp(0)
  rectfill(0,0,15,127,0)       -- left
  rectfill(110,0,127,127,0) -- right
  rectfill(0,0,127,19,0)       -- top
  rectfill(0,110,127,127,0) -- bot

  if (message_box) then
    sdraw(message_box,19,19,mbc)
  end

  -- center panel 
  fillp(0b1111000011110000.1)
  rectfill(16,16,111,111,1)
  fillp(0b1010101010101010.1)
  rectfill(16,16,111,111,0)
  fillp(0)

  if (player) then
    draw_target()
  end
end

function draw_console()
  local c=1

  if(player) then
    c=9
    print3("zone",56,115,c)
    c=5
    print3("day",32,115,c)
    print3("dist",83,115,c)
  else
    print3("0000",56,115,c)
    print3("000",32,115,c)
    print3("0000",83,115,c)
  end

  if(player)c=6
  print(pad(tostr(days),5),28,120,c)
  print(pad(tostr(zone),2),60,120,c)
  print(pad(tostr(distance),5),81,120,c)
end

function draw_market()
  local c=1
  if(player) then
    c=5
    print3(pad(tostr(days-1),5),0,3,c)
    print3(pad(tostr(days+1),5),0,11,c)
  else
    print3(pad("0",5),0,3,c)
    print3(pad("0",5),0,11,c)
  end
  line(50,4,50,12,c)
  line(82,4,82,12,c)

  if(player)c=6
  print3(pad(tostr(days),5),0,7,c)
  line(50,7,50,9,c)
  line(82,7,82,9,c)

  fillp(0b0101010101010101.1)

  for day=0,2 do
    -- pink-ite
    rectfill(20,3+day*4,48,5+day*4,1)
    -- yellow-ite
    rectfill(52,3+day*4,80,5+day*4,1)
    -- green-ite
    rectfill(84,3+day*4,112,5+day*4,1)
    if(player) then
      for i=0,2 do
        rectfill(20+32*i,3+day*4,19+
          mrkt_zone[zone][allp[i]][day+1]+32*i,5+day*4,allp[i])
        rectfill(47+32*i,3+day*4,48+32*i,5+day*4,9)
      end
    end
  end
  fillp()
end

function draw_vert_meters()

  fillp(0b1111000011110000.1)
  local c = 1 
  rectfill(115,wudm,115,wudm+wm,c)
  rectfill(125,dudm,125,dudm+dm,c)
  if(player) c=8
  rectfill(115,wudm,115,wudm+water_dn_c,c) -- water
  rectfill(125,dudm,125,dudm+dirt_dn_c,c) -- dirt
  if (gold_dn_c>0) rectfill(13,gudm,13,gudm+gold_dn_c,c) -- gold

  if(player) c=11
  rectfill(115,wm+wudm-water_up_c,115,wm+wudm,c) -- water
  rectfill(125,dm+dudm-dirt_up_c,125,dm+dudm,c) -- dirt
  if (gold_up_c>0) rectfill(13,gudm+gm-gold_up_c,13,gudm+gm,c) -- gold

  --water
  rectfill(117,wudm,119,wudm+wm,1)
  if(player and player.water>0) then
    rectfill(117,wm+wudm-player.water,119,wm+wudm,12)
  end
   -- dirt
  rectfill(121,dudm,123,dudm+dm,1)
  if(player and player.dirt>0) then
    rectfill(121,dm+dudm-player.dirt,123,dm+dudm,4)
  end

  -- gold
  rectfill(9,gudm,11,gudm+gm,1) 
  if (player and player.gold>0) then
    rectfill(9,gudm+gm-player.gold,11,gudm+gm,9) 
  end

  -- sensor bins
  rectfill(4,st,6,st+sm,1) -- primary
  rectfill(0,st,2,st+sm,1) -- secondary
  local spacer=0
  if (player) then
    for el,am in pairs(player.sensor) do
      rectfill(
        0+spacer,
        st+sm-am,
        2+spacer,
        st+sm,
        el
      )
      spacer += 4
    end
  end
  fillp(0)

  if(player) c=5 
  line(0,st+1,6,st+1,c)
  line(0,st+sm-1,6,st+sm-1,c)

end

function _update()
  if (not g_seq) then
    g_seq = cocreate(game_sequence)
  end
  if (g_seq and costatus(g_seq) != "dead") then
    coresume(g_seq)
  else
    g_seq = nil
  end
end

function _draw()
  cls(0)
  cur_frame+=1
  if(triangle_list) draw_triangle_list()
  draw_display()
end

function creamdog_tri(x1,y1,x2,y2,x3,y3,br,palette,ne,w,d)

  local list = {{flr(x1),flr(y1)},{flr(x2),flr(y2)},{flr(x3),flr(y3)}}

  list = sort2dvectors(list)
 
  local xs = list[1][1] -- start 
  local xe = list[1][1] -- end
 
  local vx1 = (list[2][1]-list[1][1])/(list[2][2]-list[1][2]) -- (x2-x1)/(y2-x1)
  local vx2 = (list[3][1]-list[2][1])/(list[3][2]-list[2][2]) -- (x3-x2)/(y3-y2)
  local vx3 = (list[3][1]-list[1][1])/(list[3][2]-list[1][2]) -- (x3-x1)/(y3-y1)
 
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
          color_list[get_from_dist(ne)][br]+
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

--------------------------BEGIN CUT HERE-------------------------------------------------
------------------Electric Gryphon's 3D Library-----------------------------------------

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

-- TODO: remove obstacle concept
function load_object(object_vertices,object_faces,x,y,z,ax,ay,az,obstacle,palette,ub,w,d)

  object=new_object()
  object.vertices=object_vertices

  --make local deep copy of faces 
  object.base_faces=object_faces
  object.faces={}
  for i=1,#object_faces do
    object.faces[i]={}
    for j=1,#object_faces[i] do
      object.faces[i][j]=object_faces[i][j]
    end
  end
  
  object.radius=0
  
  --make local deep copy of translated vertices
  --we share the initial vertices
  for i=1,#object_vertices do
    object.t_vertices[i]={}
      for j=1,3 do
        object.t_vertices[i][j]=object.vertices[i][j]
      end
  end

  object.ax=ax or 0
  object.ay=ay or 0
  object.az=az or 0
  
  transform_object(object)
  set_radius(object)        -- TODO: is this used? most likely no
  
  object.x=x or 0
  object.y=y or 0
  object.z=z or 0
  object.palette = palette

  local pal_dist = {[palette[0]]=6,[palette[1]]=4,[6]=10,[5]=2} -- base
  if (w>0) pal_dist[12]=2 -- add some water
  if (d>0) pal_dist[4]=4  
  object.ne = build_dist(pal_dist)

  object.ub = ub
  object.w = w
  object.d = d
  return object
end

function set_radius(object)
  for vertex in all(object.vertices) do
      object.radius=max(
        object.radius,vertex[1]*vertex[1]+vertex[2]*vertex[2]+vertex[3]*vertex[3])
  end
  object.radius=sqrt(object.radius)
end

-- TODO : remove unused object defaults
function new_object()

  object={}

  object.vertices={}
  object.faces={}
  object.t_vertices={} -- TODO: difference from vertices?

  object.x=0
  object.y=0
  object.z=0

  object.palette = {}
  object.visible=false -- TODO: diff between these

 -- TODO: understand
  object.rx=0
  object.ry=0
  object.rz=0
  
  object.tx=0
  object.ty=0
  object.tz=0
  
  object.ax=0
  object.ay=0
  object.az=0
  
  object.sx=0
  object.sy=0

  object.vx=0
  object.vy=0
  object.vz=0

  add(object_list,object) --TODO: do you want this side effect
  return object
end

function delete_object(object)
  del(object_list,object)
end

function new_triangle(p1x,p1y,p2x,p2y,p3x,p3y,z,c1,c2,ne)
  add(triangle_list,
    {
      p1x=p1x,
      p1y=p1y,
      p2x=p2x,
      p2y=p2y,
      p3x=p3x,
      p3y=p3y,
      tz=z,
      c1=c1,
      c2=c2,
      ne=ne
    }
  )
end

function draw_triangle_list()
  for i=1,#triangle_list do
      local t=triangle_list[i]
      creamdog_tri( t.p1x,t.p1y,t.p2x,t.p2y,t.p3x,t.p3y,
        t.c1, -- brightness
        t.c2, -- palette
        t.ne, -- # not excluded neighbor colors repeated in palette
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

                object.palette,
                object.ne
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
                object.palette,
                object.ne
              )
            end

            if( max(s4x,max(s3x,s2x))>0 and min(s4x,min(s3x,s2x))<128)  then
              new_triangle(
                s2x,s2y,s4x,s4y,s3x,s3y,z_paint,
                get_br(nx,ny,nz),
                object.palette,
                object.ne
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
                object.ne
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

----------------------------------END COPY-------------------------------------------------------
----------------------------------Electric Gryphon's 3D Library----------------------------------
-------------------------------------------------------------------------------------------------


__gfx__
000000500000000055550000000000000000000007777770000000000000c0000000000000000000000000000000000000000000000000000000000000000000
0000000008800000500000000000000000000000066776600009a000000dc00000d5d500005dd500005df600000a0600005df60000d66600000dc00000000000
0000500008000000500000000007770000777700000770000097aa0000d7cc00009dad0000daad00005ea60000a065000059a6000066d600005dcc0000000000
0000000000000000500000000000700000077000007777000097aa0000d7cc00009dad00005dd5000059c600000650000059a6000066660000d7cc0000000000
0050000000000000000000000007070000777700076776700009a000000dc00000d5d50000d99d0000056000006500000005600000666d00005dc50000000000
00000000000000000000000000000000007007000706607000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000000000000000000000000000000000000007600006700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007000000700000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777007777777777777700777777777777777777777777770000777777777707777777770000777700000077700777770000777777777777777777
77777777777777007777777777777700777777777777777777777777770000777777777707777777770007777700000077777777777000777777777777777777
77000077777777007700000077000077770000007700000077000000770000770007700000007700770077707700000077777777777700777700007777000007
77000077777777007700000077000077777770007777700077000000777777770007700000007700777777007700000077077077777770777700007777777777
77777777770000777700000077000077777770007777700077000077777777770007700000007700777777007700000077077077777777777700007777777777
77777777770000777700000077000077770000007700000077000077770000770007700000007700770077707700000077000077770777777700007777000000
77000077777777777777777777777700777777777700000077777777770000777777777777777700770007777777777777000077770077777777777777000000
77000077777777777777777777777700777777777700000077777777770000777777777777777700770000777777777777000077770007777777777777000000
77777777777777777777777777777777770000777700007777000077770000777700007777777777000000000007700000770000000000000000000000000000
77777777777777777777777777777777770000777700007777000077777007777770077777777777000000000077000000077000000000000000000000000000
77000077770000777700000000077000770000777700007777000077077777700777777000000077000000000770000000007700000000000000000000000000
77000077777777777777777700077000770000777700007777000077007777000077770077777777000000007770000000007770000000000000000000000000
77007777777777777777777700077000770000777700007777770077007777000007700077777777000000007770000000007770000000000000000000000000
77007777770077000000007700077000770000770770077077770077077777700007700077000000000000000770000000007700000000000000000000000000
77777777770077007777777700077000777777770777777077777777777007770007700077777777000000000077000000077000000000000000000000000000
77777777770077007777777700077000777777770007700077777777770000770007700077777777000000000007700000770000000000000000000000000000
07077077777077777777070777700770770077777777777777777707777770770770770770777000000000000000000000000000000000000000000000000000
77777770070777077070777707070777070077770770777777770007007070770777707077707000000000000000000000000000000000000000000000000000
70777777777077770077770777777770777770770777770000770077007077707077770707007700000000000000000000000000000000000000000000000000
77777077077770707770077707777700000007077707007077007707000770077770707007000000000000000000000000000000000000000000000000000000
70707007007777707077700777777700007070707770000770000700007007000070707077777700000000000000000000000000000000000000000000000000
77777707777700777077700777700707070000007007007077007707070000777700000007000000000000000000000000000000000000000000000000000000
