# Brief Overview #

You are an asteroid mining prospector trainee.

You are remotely controlling an asteroid prospecting spacecraft.

You have a limited map of the asteroid belt your spacecraft sits within.  This map shows a rough approximation of the materials each asteroid contains.

It's your job to land the craft on an asteroid and gather more data about what the asteroid contains.  You then sell this information for future mining missions.

The value of this information fluctuates relative to the whims of the market.

In this training exercise, your goal is to get to the Zone 5 market.

Don't let your fuel (water) or shields (dirt/regolith) get too low or your craft will become unusable.

Note: you can play here now: https://www.lexaloffle.com/bbs/?tid=35489

# Controls and Interface #

You move between asteroids with the arrow keys. Use x key to start or continue.                                                                                                                                                                                                             

Asteroids can contain a variety of materials.

## Three materials can be sold on the market: ##

  Pink-ite : pink in your map
  
  Green-ite: green in your map                                                                                                          Yellow-ite: yellow in your map

  When you land on an asteroid with these materials:
    1. you will be charged a fee
    2. you will automatically sell them on the market
    3. these materials will no longer be availble to you for selling

In your control panel, the far left two vertical bars indicate the amount of market materials your craft has detected.

The third bar from the left indicates the money/gold you have.  The red dots at the top of this bar indicate the cost of landing on an asteroid, with market materials, in this market.

You receive gold based on the volume of the market materials found relative to the current exchange rate.

The exchange rate, for a particular Zone's market is shown in the area above your map.  These rates cycle through three variants each day.  The center exchange rate is applied today.  The bottom rate is what will happen tomorrow.  The top rate is what happened yesterday.

When your gold has reached the top of the bar, your spacecraft's fuel and shield algorithm will be upgraded. Press x to continue.  After upgrade, you will get gold equivalent to the green dots next to the gold bar.

## Two other materials can be on asteroids: ##

Water : blue in your map
Regolith (dirt) : brown in your map                                                                                                       

You hop between asteroids by heating water and generating steam.  Water can be found on some asteroids, represented as blue in your map, for refueling.                                                                                                                                   

You protect yourself from the sun by coating your spacecraft with regolith (brown dirt) found on the asteroid.  Regolith can be found on some asteroids to replenish your shields.

Your fuel (blue water) and shield (brown regolith/dirt) levels are shown in the two bars to the right of your map.  The red dots at the top of these indicates how much they are reduced when you move.  The green dots indicate how much these bars are replenished when landing on an asteroid that contains water or dirt.

Your shield and fuel usage will be upgraded as you max out your gold.  This will help you get to Zone 5.

# Thanks and Backstory #

Thanks go out to feedback on my initial asteroid generation effort by @freds72 :https://www.lexaloffle.com/bbs/?tid=34135 . I indeed used the 3d library by @electricgryphon.  I used rasterization code from @creamdog.

Inspiration for the backstory via the following cool articles:
https://www.nasa.gov/directorates/spacetech/niac/rogolith_derived_heat/
https://www.technologyreview.com/s/612999/steam-powered-spacecraft-could-jump-start-asteroid-exploration/
http://www.thespacereview.com/article/3304/1
https://www.forbes.com/sites/brucedorminey/2019/01/14/steam-powered-asteroid-hopper-offers-revolutionary-new-way-to-explore-our-solar-system/#7a59520f500b
