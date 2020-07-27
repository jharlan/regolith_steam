pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

-- game: Regolith
-- author: personaj, March 2020

--static icosohedran face definition
astf="3,7,8@8,7,2@12,1,2@1,9,2@5,10,9@9,10,8@10,4,3@11,3,4@6,12,11@12,7,11@1,6,5@6,4,5@7,3,11@7,12,2@2,9,8@10,3,8@4,6,11@1,12,6@4,10,5@1,5,9"
--- level definition ---
lvl_list={
  "3@".. -- level goal
  "6@".. -- ring size
  "2@".. -- water use upper bound : distance
  "2@".. -- dirt use upper bound : solar wind
  "    blue water asteroids refuel your ship...   ,"..
  "    brown regolith asteroids fix your shields...   ,"..
  "    yellow and pink asteroids are mined and sold for coins...   ,"..
  "      collect coins!,"..
  "    moving decreases fuel and shield... press arrow to continue...  @"..
  -- first ring
  "24,".. -- exist
  "001,"..--"001,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12341|12341|12342," .. -- volume as f(primary)
  "10|10|09," .. -- water f(primary)
  "10|10|10=".. --dirt as f(primary)
  -- second ring
  "23,".. -- exist
  "001,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12341|12311|12311," .. -- volume as f(primary)
  "10|10|10," .. -- water f(primary)
  "10|10|01=".. --dirt as f(primary)
  -- third ring
  "24,".. -- exist
  "221,".. -- primary
  "001|001|001," .. -- secondary as function of primary
  "12311|12311|12311," .. -- volume as f(primary)
  "10|10|09," .. -- water f(primary)
  "10|20|09"
-- stepping stone easy
,"3@3@2@2@ level loaded get mining!@14,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=41,112,111|121|111,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone medium
,"3@3@2@2@ stepping stones in space@13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,332,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone medium 2
,"3@3@2@5@ solar storms hurt shield@13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,332,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- stepping stone hard
,"5@3@3@3@ fewer minerals more fun @13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,112,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
-- barren stripe
,"5@6@5@5@  so far away each rock  @13,001,001|001|001,12321|12321|12321,00|00|11,00|00|11=51,113,111|111|001,12111|12111|12321,00|11|00,11|00|00=41,003,001|001|001,12111|12111|12351,00|00|00,00|00|00"
}

colors = "0,0,0,1,1@0,1,1,2,2@0,1,1,3,3@0,1,1,4,4@0,0,1,5,5@0,5,5,6,6@5,5,6,7,7@0,2,2,2,2@2,2,4,4,9@1,1,1,10,10@0,1,1,3,3@0,1,1,12,12@1,1,5,5,13@1,1,2,14,14@4,4,9,9,15"

allp={14,10,6}
vols={8,13,18,23,28}
m_names={"PINK","YELLOW"}
sequence_text={
  water = {"FUEL","EMPTY","        restarting!"},
  dirt = {"SHIELD","DOWN!","        restarting!"},
  restart = {"START","OVER!","        restarting!"},
  goal = {"NEXT","LEVEL","    loading new level..."}
}

---

function _init()
  cur_frame,max_sensor,mbc,px0,py0,fntspr,fntdefaultcol,fntx,fnty,ast_log=0,96,9,0,50,64,7,{},{},{}

  initfont()

  color_list={}
  for t in all(str_to_table("@",colors)) do
    add(color_list,str_to_table(",",t,true))  
  end

  ast_faces={}
  for t in all(str_to_table("@",astf)) do
    add(ast_faces,str_to_table(",",t,true))  
  end

  -- player config
  player = {}--new_3d_object()
  player.lvl,player.z=1,5.2
  --player.z=5.2  --15

  -- electric gryphon config
  z_clip,z_max,k_min_x,k_max_x,k_min_y,k_max_y,k_screen_scale,k_x_center,k_y_center,k_ambient,light1_x,light1_y,light1_z,t_light_x,t_light_y,t_light_z=-3,-50,0,128,0,128,80,64,64,.4,.35,.35,.1,0,0,0

end

function game_sequence()
  g_active = cocreate(active_sequence)
  g_transition = cocreate(transition_sequence)
  while true do
    if (g_active and costatus(g_active) != "dead") then
      coresume(g_active)
    elseif (g_transition and costatus(g_transition) != "dead") then
      g_active = nil
      coresume(g_transition)
    else
      g_transition = nil
      return
    end
    yield()
  end
end

function transition_sequence()
  local over_reason = level_over() or "restart"
  purge_all = true
  update_objects()
  local toggle,col = false,8
  if (over_reason == "restart" or over_reason == "goal") then
    tc.c0,tc.c2,col=15,15,10
  end
  if (over_reason=="win") then
    tc.c0,tc.c2=11,11
    while(not btnp(5)) do 
      toggle=get_toggle(toggle)
      tc.s0 = toggle and "YOU" or ""
      tc.s2 = toggle and "WIN!" or ""
      lines = {0,"     congratulations!"}
      yield()
    end
    player.lvl = 1
    return
  else
    for i=1,80 do
      toggle=get_toggle(toggle)
      tc.ac = toggle and 5 or col 
      tc.s0=sequence_text[over_reason][1]
      tc.s2=sequence_text[over_reason][2]
      lines = {0,sequence_text[over_reason][3]}
      yield()
    end
    player.lvl = (over_reason == "goal") and (player.lvl+1) or 1
    return
  end
end

function move_sequence(dir)
  spawn_belt(dir)
  m_target  = cocreate(move_target)
  m_move    = cocreate(move_ship)
  s_sensing = cocreate(sensing_sequence)
  while true do
    if (m_target and costatus(m_target) != "dead") then
      coresume(m_target,dir)
    elseif (m_move and costatus(m_move) != "dead") then
      m_target = nil
      coresume(m_move,dir)
    elseif (s_sensing and costatus(s_sensing) != "dead") then
      m_move = nil
      coresume(s_sensing)
    else
      s_sensing = nil
      player.move_count +=1
      return
    end
    yield()
  end
end

function sense_elements(ast)
  if (
    not ast_log[hkey(pairing(ast.x,ast.y))] and -- have not been here before
    (ast.palette[1]!=3 or ast.palette[2]!=3)) then

    local delay =
      (player.lvl == 1 and player.move_count <10 and player.message_index<4 ) and 42 or 15

    local toggle=true
    tc.s0,tc.c0 = "MINING",15
    for i=1,2 do
      local vol_proxy = (i==1) and 105 or 45 --vol proxy constants
      local cur_mineral = ast.palette[i] 
      if (cur_mineral==1 or cur_mineral==2) then
        tc.c2=allp[ast.palette[i]]

        for j=1,delay do

          sfx(4+cur_mineral)
          toggle=get_toggle(toggle)

          tc.ac =toggle and cur_mineral or 5
          tc.s2 =(toggle and player.lvl==1) and m_names[cur_mineral] or ""

          -- is mineral bin full
          if (player.sensor[cur_mineral]+ast.lower_scale*vol_proxy/delay >= 72) then
            player.sensor[cur_mineral] = 72

            -- coin flipping
            for k=1,10 do 
              sfx(7)
              coin.offset[cur_mineral] = k
              coin.spr[cur_mineral][1] = 82+cur_frame%2
              coin.spr[cur_mineral][2] = 98+cur_frame%2
              yield()
            end

            coin.spr[cur_mineral][1],coin.spr[cur_mineral][2]=82,98
            coin.offset[cur_mineral]=0

            -- redeem coin
            if (cur_mineral==1) then
              player.goal_attain += 2
            else
              player.goal_attain += 1
            end

            -- reset sensor
            player.sensor[cur_mineral] = 0  

          else
            -- increment sensor
            player.sensor[cur_mineral]+=ast.lower_scale*vol_proxy/delay
          end

          yield()
        end
      end
      yield()
    end

    tc_init()

    if (player.lvl == 1 and player.message_index == 3) then
      player.message_index=4
      lines = {0,clvl.lines[4]}
    end
  end
  -- update sold asteroid
  local pal_dist = {[6]=10,[5]=2} -- base 6 was 10
  if (ast.w>0) pal_dist[12]=2 -- add some water
  if (ast.d>0) pal_dist[4]=4
  ast.pal_dist = build_dist(pal_dist) 
  ast_log[hkey(pairing(ast.x,ast.y))] = true
end

function gather_resource(ast,resource)
  local toggle=true
  local sound = resource == "water" and 4 or 3
  local delay = (player.lvl == 1 and player.move_count <10) and 42 or 15
  local msg=(resource=="water") and {"FUEL",12,2} or {"SHIELD",4,3}
  if ((ast.w>0 and resource=="water") or (ast.d>0 and resource=="dirt")) then
    local dif = (player[resource]<=72) and (72-player[resource]) or 0
    tc.s0,tc.c0,tc.c2="MINING",15,msg[2]
    for i=1,delay do
      toggle=get_toggle(toggle)
      tc.ac = toggle and 5 or msg[2]
      tc.s2 = (toggle and player.lvl==1) and msg[1] or ""
      sfx(sound)
      if (player[resource]+dif/delay >= 72) then
        player[resource] = 72
      else
        player[resource] +=dif/delay
      end
      yield()
    end
    tc_init()
    if (player.lvl == 1 and player.message_index == msg[3]-1) then
      player.message_index=msg[3]
      lines = {0,clvl.lines[msg[3]]}
    end
  end
end

function move_target(dir)
  local dm = {["n"]={0,-1},["e"]={1,0},["s"]={0,1},["w"]={-1,0}}
  local dx,dy=dm[dir][1],dm[dir][2]
  sfx(0)
  for i=1,8 do
    ship.x += dx*4
    ship.y += dy*4
    player.x += dx*0.25
    player.y += dy*0.25
    beacons.xoffset += dx*3.75
    beacons.yoffset += dy*3.75
    yield()
  end
  beacons.xoffset,beacons.yoffset,beacons.x,beacons.y=0,0,player.x,player.y
end

function raise_ship()
  if (ship.spr==15) then
    for i=0,8 do
      if (i<3) then ship.spr = 21
      elseif(i>5) then ship.spr = 25
      else ship.spr = 20
      end
      yield()
    end
  end
end

function lower_ship()
  local ast = get_c_ast()
  if (ast) then
    sfx(1)
    for i=0,8 do
      if (i<3) then ship.spr = 20
      elseif (i>5) then ship.spr = 15
      else ship.spr = 21
      end
      yield()
    end
  end
end

function bkg_move_cost(x,y,show)
  if (show) then
    spr(42,x,y)
    spr(42,x+1,y-1,1,1,true,true)
  end
end

function move_value(is_brown,ast_nb)
  return is_brown and ast_nb[2] or ast_nb[1]
end

function thrust_ship(dir)
  local dtb={n=3,w=1,s=2,e=0} -- dir to button translate
  local ship_mag,init_ship,steps=2,ship.spr,16
  local toggle=true
  local dw,dd=0,0 -- decrements
  local assist=(player.lvl==1 and player.move_count<3)
  ship.thrust=true

  for i=1,steps do
    toggle=get_toggle(toggle)

    tc.ac = toggle and 5 or 11

    if (i==9) then

      if(assist) tc.s0,tc.s2,tc.c0,tc.c2,lines="MOVE","COST",15,15,{0,clvl.lines[5]}
      sfx(2)

      if (dir=="w") then
        tc.bnw,tc.bsw=true,true
        dw = tc.bnwb and tc.bswv or tc.bnwv -- if upper left is brown sw is blue
        dd = tc.bnwb and tc.bnwv or tc.bswv
      elseif(dir=="e") then
        tc.bne,tc.bse=true,true
        dw = tc.bnwb and tc.bnev or tc.bsev
        dd = tc.bnwb and tc.bsev or tc.bnev
      elseif(dir=="s")then
        tc.bsw,tc.bse=true,true
        dw = tc.bnwb and tc.bswv or tc.bsev
        dd = tc.bnwb and tc.bsev or tc.bswv
      elseif(dir=="n")then
        tc.bnw,tc.bne=true,true
        dw = tc.bnwb and tc.bnev or tc.bnwv
        dd = tc.bnwb and tc.bnwv or tc.bnev
      end

      if(assist) then
        while (not btnp(dtb[dir])) do
          toggle=get_toggle(toggle)
          tc.ac = toggle and 5 or 11
          yield()
        end
        sfx(0)
      end

    elseif(i>8) then
      tc.s0=""
      tc.s2=""
    end

    if (dir=="n") then
      ship.y += ship_mag
    elseif (dir=="e") then
      ship.x -= ship_mag
    elseif (dir=="s") then
      ship.y -= ship_mag
    elseif (dir=="w") then
      ship.x += ship_mag
    end
    yield()
  end
  player.dirt = (player.dirt-dd*2<0) and 0 or (player.dirt-dd*2)
  player.water = (player.water-dw*2<0) and 0 or (player.water-dw*2)
  tc_init()
  if (assist) lines = {0,clvl.lines[player.message_index]}
  ship.x,ship.y=59,59
  ship.thrust = false
end

function move_ship(dir)
  m_thrust = cocreate(thrust_ship)
  m_lower =  cocreate(lower_ship)
  while true do
    if (m_thrust and costatus(m_thrust) != "dead") then
      coresume(m_thrust,dir)
    elseif (m_lower and costatus(m_lower) != "dead") then
      m_thrust = nil
      coresume(m_lower)
    else
      m_thrust = nil
      return
    end
    yield()
  end
end

function sensing_sequence()
  local ast = get_c_ast()
  m_water =    cocreate(gather_resource)
  m_dirt  =    cocreate(gather_resource)
  m_elements = cocreate(sense_elements)
  m_raise =    cocreate(raise_ship)
  while true do
    if (m_water and costatus(m_water) != "dead") then
      coresume(m_water,ast,"water")
    elseif (m_dirt and costatus(m_dirt) != "dead") then
      m_water = nil
      coresume(m_dirt,ast,"dirt")
    elseif (m_elements and costatus(m_elements) != "dead") then
      m_dirt = nil
      coresume(m_elements,ast)
    elseif (m_raise and costatus(m_raise) != "dead") then
      m_elements = nil
      coresume(m_raise)
    else
      m_raise = nil
      return
    end
    yield()
  end
end

function get_toggle(tog)
  if(cur_frame%6==0) return not tog 
  return tog
end

function init_move(curr_dir)
  tc.s0=""  
  tc.aw,tc.ae,tc.an,tc.as=(curr_dir=="e"),(curr_dir=="w"),(curr_dir=="s"),(curr_dir=="n")
  s_moving=cocreate(move_sequence)
  return curr_dir
end

function active_sequence()
  level_init()
  local dir
  lines = {0,clvl.lines[1]}
  local toggle=true
  while (not level_over() and not btnp(5)) do
    toggle=get_toggle(toggle)
    if (cur_frame%6==0) lines[1] += 1
    if (not s_moving) then
      tc.s0,tc.c0,tc.ac="READY",15,toggle and 5 or 11
      if(btnp(1))     then dir=init_move("w")
      elseif(btnp(0)) then dir=init_move("e")
      elseif(btnp(3)) then dir=init_move("n")
      elseif(btnp(2)) then dir=init_move("s")
      end
    end
    if (s_moving and costatus(s_moving) != "dead") then
      coresume(s_moving,dir)
    else
      s_moving=nil
    end
    update_objects()
    yield()
  end
  s_moving=nil
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
  local rt,val,cs,len={},"","",#tbl_str
  for i=1,len do
    cs = sub(tbl_str,i,i)
    if (cs==delim or not delim) then -- delim can be nil
      if (not delim) val = cs
      val = isnum and tonum(val) or val
      add(rt,val)
      val=""
    else
      val = val..cs
    end
  end
  if(val and delim) then
    val = isnum and tonum(val) or val
    add(rt,val)
  end
  return rt 
end

function load_lvl(enc_lvl)
  local rt={}

  local temp_t=str_to_table("@",enc_lvl)

  rt.goal=tonum(temp_t[1])
  rt.ring_size=tonum(temp_t[2])
  rt.dist_ub=tonum(temp_t[3]) 
  rt.weather_ub=tonum(temp_t[4])
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
  local rl = {}
  local t = 0
  for e,v in pairs(dist) do
    t += tonum(v) -- may come in as a string
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
    if (dir == "w") then -- moving left so adding to the right
      add_new_ast(player.x-4,player.y+c)  -- top
      set_ast_cull(player.x+4,player.y+c)
    elseif (dir == "e") then
      add_new_ast(player.x+4,player.y+c)  -- top
      set_ast_cull(player.x-4,player.y+c)
    elseif (dir == "n") then
      add_new_ast(player.x+c,player.y-4)
      set_ast_cull(player.x+c,player.y+4)
    elseif (dir == "s") then
      add_new_ast(player.x+c,player.y+4)
      set_ast_cull(player.x+c,player.y-4)
    end
  end
end

function gafc(xp,y)-- get_addr_from_coord(x,y)
  return 0x6000+64*y+xp
end

function tc_init()
  tc.an,tc.aw,tc.as,tc.ae=true,true,true,true -- arrows
  tc.ac=5 -- arrow colors
  tc.s0,tc.s2="",""-- strings
  tc.c0,tc.c2=8,8 -- string color
  tc.bnw,tc.bne,tc.bsw,tc.bse=false,false,false,false -- active beacon backgrounds
  tc.bc=6 -- color of beacon background
  tc.bnwv,tc.bnev,tc.bswv,tc.bsev=0,0,0,0
end

--- game_sequence : active_sequence ---
function level_init()
  purge_all=false 
  gseed = stat(95)+stat(94)+stat(93)+stat(0)

  -- global objects --
  ast_list={}    -- stores asteroid belt
  ast_log={}     -- which asteroids have been mined/sold
  beacons={
    xoffset=0,
    yoffset=0,
    x=px0,
    y=py0
  }
  lines={}  -- console content
  tc={} -- center text
  tc_init()
  coin={spr={{82,98},{82,98}},offset={0,0}}
  ship={spr=25,x=59,y=59}

  player.x=px0--2000   --0
  player.y=py0--3000    --8
  player.dirt=72
  player.water=72
  player.sensor=(player.lvl==1) and {30,30} or {2,2} 
  player.move_count=0
  player.message_index=1
  player.goal_attain=0

  clvl=load_lvl(lvl_list[player.lvl]) -- current level

  init_light()
  init_asteroid()   -- starting set
end

function level_over()
  local over_reason = false
  if (player.water<=0) over_reason = "water"
  if (player.dirt<=0) over_reason = "dirt"
  if (player.goal_attain>=clvl.goal) over_reason = "goal"
  if (over_reason=="goal" and player.lvl>=#lvl_list) over_reason = "win"
  return over_reason
end

function update_objects()
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

  triangle_list={}

  for ast in all(ast_list) do
    ast.ax += .005--.005--flr(rnd(10))/1800
    ast.az += .015--.015
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
    draw_vert_meters()
    draw_console()
    draw_market()
end

function printv(s,x0,y0,c,t)
  for i=0,#s-1 do
    if(t) then
      print3(sub(s,i+1,i+1),x0,y0+(i*4),c)
    else
      print(sub(s,i+1,i+1),x0,y0+(i*6),c)
    end
  end
end

function draw_goal()
  for i=0,clvl.goal-1 do
    local gspr = (player.goal_attain-i > 0) and 45 or 44
    spr(gspr,67+i*4,8)
  end
end

function draw_target()
  pal()
  --bot
  rectfill(16,111,111,111,0)
  --top
  rectfill(16,17,110,17,0)
  --left
  rectfill(16,19,16,109,0)
  --right
  rectfill(110,19,110,109,0)

  pal(5,tc.ac) -- arrow colors shared
  if(tc.an) spr(60,60,51,1,1,false,true) -- north
  if(tc.aw) spr(59,50,60,1,1,false,true) -- west
  if(tc.as) spr(60,59,70,1,1,true,false) -- south
  if(tc.ae) spr(59,69,61,1,1,true,false) -- east
  pal()

  local ulx,uly=-13+flr(beacons.xoffset),-13+flr(beacons.yoffset)
  pal(8,5)
  for xi=0,5 do
    for yi=0,5 do

      spr(1,ulx+xi*30,uly+yi*30+1) -- 1,false,false
      spr(1,ulx+xi*30-5,uly+yi*30+1-5,1,1,true,true)

      spr(3,ulx+xi*30+1,uly+yi*30+8)
      spr(3,ulx+xi*30+1,uly+yi*30-10)

      spr(4,ulx+xi*30+7,uly+yi*30+2)
      spr(4,ulx+xi*30+7-18,uly+yi*30+2)

    end
  end
  pal()

  if(tc.s0!="") then
    rectfill(ship.x-#tc.s0*2+5,ship.y-3,ship.x-#tc.s0*2+4+#tc.s0*4,ship.y+1,1)
    print(tc.s0,ship.x-#tc.s0*2+5,ship.y-4,tc.c0)
  end
  if(tc.s2!="") then
    rectfill(ship.x-#tc.s2*2+5,ship.y+11,ship.x-#tc.s2*2+4+#tc.s2*4,ship.y+15,1)
    print(tc.s2,ship.x-#tc.s2*2+5,ship.y+10,tc.c2)
  end
  spr(ship.spr,ship.x,ship.y+2,1,1)
end

-- cost beacons
function draw_beacon_nums()
  local ulx,uly=-13+flr(beacons.xoffset),-13+flr(beacons.yoffset)
  local init_brown=true
  if (beacons.x%4 == beacons.y%4) then
    init_brown=false
  end
  local nc
  local ast_nb=nil
  local assist=(player.lvl==1 and player.move_count<=3)
  local toggle=get_toggle(true)
  local bx,by
  for xi=0,5 do
    init_brown = not init_brown
    for yi=0,5 do
      init_brown = not init_brown
      -- get weather and distance
      srand(abs(pairing(beacons.x+2*2-xi*2,beacons.y+3*2-yi*2))+gseed)
      ast_nb={ceil(rnd(clvl.dist_ub))+1,ceil(rnd(clvl.weather_ub))+1}

      tc.bnwb=init_brown -- is upper left brown -- so many hacks :(
      if (toggle) pal(7,8)
      bx,by=ulx+xi*30-3,uly+yi*30-1
      if(yi==3 and xi==3) then 
        bkg_move_cost(bx,by,tc.bse)
        tc.bsev = move_value(init_brown,ast_nb)
      elseif(yi==2 and xi==2) then
        bkg_move_cost(bx,by,tc.bnw)
        tc.bnwv = move_value(init_brown,ast_nb)
      elseif(yi==2 and xi==3) then
        bkg_move_cost(bx,by,tc.bne)
        tc.bnev = move_value(init_brown,ast_nb)
      elseif(yi==3 and xi==2) then 
        bkg_move_cost(bx,by,tc.bsw)
        tc.bswv = move_value(init_brown,ast_nb)
      end
      pal()

      if (init_brown) then
        print(
        ast_nb[2],
        ulx+xi*30,
        uly+yi*30,4)
      else
        print(
        ast_nb[1],
        ulx+xi*30,
        uly+yi*30,12)
      end
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
  rectfill(0,0,127,18,0)       -- top
  rectfill(0,110,127,127,0) -- bot

  draw_target() -- new place for draw_target
  draw_beacon_nums()

  rectfill(0,0,16,127,0)       -- left
  rectfill(110,0,127,127,0) -- right
  rectfill(0,0,127,16,0)       -- top
  rectfill(0,112,127,127,0) -- bot

  -- side latches
  spr(26,107,63)
  spr(26,107,33)
  spr(26,107,93)
  spr(26,12,63,1,1,true)
  spr(26,12,33,1,1,true)
  spr(26,12,93,1,1,true)
  spr(27,32,13,1,1,false,true)
  spr(27,62,13,1,1,false,true)
  spr(27,92,13,1,1,false,true)
  spr(27,32,108)
  spr(27,62,108)
  spr(27,92,108)
end

-- prints contents of the global lines
function draw_console()

  -- corner framing
  --local cx = 26
  local cy = 115

  local raw_text = lines[2]
  local ti = lines[1]
  local cursor = 1
  local buffer = ""

  -- first line that can horiz scroll
  if (#raw_text>25) then
    while cursor < 27 do
      buffer = buffer .. sub(raw_text,ti%#raw_text+1,ti%#raw_text+1)
      ti += 1
      cursor += 1
    end
  else
    buffer=raw_text 
  end
  print("88888888888888888888888888",12,cy,1)
  print("88888888888888888888888888",12,cy+6,1)
  print(buffer,12,cy,15)

  -- second interface line
  cy += 6
  print("  \151restart",36,cy,13)
end

function draw_market()
  print("8888888888888888888",26,3,1)
  print("8888888888888888888",26,9,1)
  print(" level",26,3,8)
  print(" "..tostr(player.lvl).." of "..tostr(#lvl_list),26,9,15)
  print("goal",70,3,8)
  draw_goal()

  -- market caps
  spr(49,99,9)
  spr(49,99,0,1,1,false,true)

  spr(49,113,121)
  spr(49,113,112,1,1,false,true)

  spr(49,20,9,1,1,true)
  spr(49,20,0,1,1,true,true)

  spr(49,6,121,1,1,true)
  spr(49,6,112,1,1,true,true)

end

function draw_vert_meters()
  for i=0,18 do
    spr(61,2,27+i*4)
    spr(61,8,27+i*4)
    spr(61,114,27+i*4)
    spr(61,120,27+i*4)
  end

  fillp(0b1111000011110000.1)
  
  printv("shield",116,2,5,true)
  printv("shield",115,1,15,true)

  printv("fuel",122,10,5,true)
  printv("fuel",121,9,15,true)

  --water storage
  rectfill(120,100-player.water,124,100,12) -- fill
  -- dirt storage
  rectfill(114,100-player.dirt,118,100,4) -- fill
  -- sensor
  rectfill(2,100-player.sensor[2],6,100,10)
  rectfill(8,100-player.sensor[1],12,100,14)

  -- coins
  spr(coin.spr[2][2],1,19-coin.offset[2])
  spr(coin.spr[2][1],0,18-coin.offset[2])

  -- pink
  spr(coin.spr[1][2],7,19-coin.offset[1])
  spr(coin.spr[1][1],6,18-coin.offset[1])

  spr(coin.spr[1][2],7,13-coin.offset[1])
  spr(coin.spr[1][1],6,12-coin.offset[1])

  spr(50,111,21,1,1,false,true)
  spr(50,120,21,1,1,true,true)
  spr(50,111,100)
  spr(50,120,100,1,1,true)

  spr(50,-1,21,1,1,false,true)
  spr(50,8,21,1,1,true,true)
  spr(50,-1,100)
  spr(50,8,100,1,1,true)
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

function set_radius(object)
  for vertex in all(object.vertices) do
      object.radius=max(
        object.radius,vertex[1]*vertex[1]+vertex[2]*vertex[2]+vertex[3]*vertex[3])
  end
  object.radius=sqrt(object.radius)
end

function delete_object(object)
  del(ast_list,object)
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

----------------------------------END COPY-------------------------------------------------------
----------------------------------Electric Gryphon's 3D Library----------------------------------
-------------------------------------------------------------------------------------------------


__gfx__
000000000000500033330000800000008080808000007000000000000000000000000000000000000007a0000000000000000000000000000000c00000000000
000000000000655033000000000000000000000000077700000a9000000fe000000550000009a00000777a00000bb300005df60000d66600000dc00000000000
00056000000050003000000080000000000000000007770000aa790000ff7e00005555000097aa0000777a00000bb3000059a6000066d60000d7cc0000000000
0059a600000000003000000000000000000000000000000000aa790000ff7e00005555000097aa000007a000000bb3000059a6000066660000d7cc0000000000
0059a6000000000000000000800000000000000000000000000a9000000fe000000550000009a0000000000000bb33300005600000666d00000dc00000000000
0059f6005650000000000000000000000000000000000000000000000000000000000000000000000000000000b3333000000000000000000000000000000000
0555f660050000000000000080000000000000000000000000000000000000000000000000000000000000000b30003300000000000000000000000000000000
55000066050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000030000000000000000000000000000000000000000000000000000000000151500000000066600000000000000000000033333333
0000000003bb000003330000330000000000000000000000000000000000000000000000000bb300055510000500000066600000000000000000000033333000
0003b000033bb0000b333000033330000000000000000000000000000000000000000000000bb300000151500500000000600000000000000000000033000000
0033bb000333bbbb0bb3333303333300000000000000000000c70c00000c000000000000000bb300000000001510000000600000000000000000000033000000
0033bb0000333b0000bb33000bbbbb000003b00000000000000c7000000cc7000000000000bb3330000000005150000006600000000000005500000033000000
0033bb0000033000000bb0000bbbb0000003b0000000000000c70c00007000000060000000b33330000000001010000006600000666666665555000030000000
0333bbb000030000000b0000bb0000000003b0000000b000000c00000000c000060600000b300033000000005050000000600000660066005555550030000000
330000bb00030000000b0000b000000000300b000000b0000000c000000c00006000600000000000000000000000000000600000660000005555555530000000
0000000000000000000a900000000000000000000000000000055000000000000007a00000003000000000000000000000000000000000000000000077777777
00000000000a900000aa7900000000000000000000055000005555000000000000777a0000030300000000000000a000000070000000d0000000700077777777
000a900000aa790000aa7900000a90000005500000555500005555000005500000777a0000300030000000070007a90000077900000ddd00000b7b0077000007
00aa790000aa7900000a900000aa7900005555000055550000055000005555000007a0000000000000000007000aa900000aa900000ddd00000ab90077777777
00aa7900000a90000000000000aa79000055550000055000000000000055550000000000000000000000000700009000000aa900000ddd00000bab0077777777
000a90000000000000000000000a90000005500000000000000000000005500000000000000000000000000000000000000090000000d0000000900077000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000777000000000000000000000000000000000077000000
500050000500000000500000000777000000000000000000dddd5550000000000000000000000000000000000000000000000000111110000007700000000000
500050000550000000555555007777700666d5000666d500dfa99450dddf55500000060000000600000000000070000000000000101010000077770000000000
550550000560000000005650007777700fa945000fa94500dfa99450d6fa94500000006000000060000000000750000000000000111110000777777000000000
056500000550000000000000007777700fa945000fa94500dfa99450d6fa94500000000600000006000000007500000000000000000000007770077700000000
056500000500000000000000007777700fa945000fa94500dfa99450d6fa94500000006000000060000000000750000000000000000000007770077700000000
0050000055000000000000000077777000f4500000f45000dfa99450d6fa94500000060000000600000000000070000007505700000000000777777000000000
0000000000000000000000000007770000050000000500000da995000dfa95000000000000000000000000000000000000757000000000000077770000000000
00500000000000000000000000000000000000000000000000d5500000da50000000000000000000000000000000000000070000000000000007700000000000
07077077777077777777070777700770770077777777777777777707777770770770770770777000000000000000000000000000000000000000000000000000
77777770070777077070777707070777070077770770777777770007007070770777707077707000000000000000000000000000000000000000000000000000
70777777777077770077770777777770777770770777770000770077007077707077770707007700000000000000000000000000000000000000000000000000
77777077077770707770077707777700000007077707007077007707000770077770707007000000000000000000000000000000000000000000000000000000
70707007007777707077700777777700007070707770000770000700007007000070707077777700000000000000000000000000000000000000000000000000
77777707777700777077700777700707070000007007007077007707070000777700000007000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a9000000990000000700000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa79000007a0000007790000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aa79000007a000000aa9000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a900000099000000aa9000000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000900000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000550000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000550000005550000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500000550000005550000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000550000005550000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000500000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00040000086300e7000663012700086301870007610076100761007610076100761007610136002060025600256001060012600056000a7000560004700037000370002700017000170000700007000070000700
000400000700006650040000363002000016100130000000000003400035000370003700000000000002730029300000000000000000000000000000000000000000000000000000000000000000000000000000
00100000003101c500167000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000016030250000520015200102000b2000520000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200002000020000200
0001000026030000000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f3202c300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200001631016300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
000200002a31016320003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
