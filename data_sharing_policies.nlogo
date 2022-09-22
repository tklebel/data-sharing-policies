extensions [ nw ]

globals [
  rank-list
  top-teams
  bottom-teams
]

breed [teams team]

undirected-link-breed [ team-links team-link ]

teams-own [
  resources
  resources-last-round
  proposal-strength
  effort
  inv_effort ; the inv_logit of the effort (mapping it back onto [0, 1]
  individual-utility
  descriptive-norm
  shared-data?
  sharing-dividend-pool
]


to setup
  clear-all

  ask patches [set pcolor white]

  ifelse network != "none" [
    if network = "random" [
      nw:generate-random teams team-links n-teams 0.05 [
        setxy random-xcor random-ycor
      ]
    ]
    if network = "small-world" [
      nw:generate-small-world teams team-links 10 10 2 false [
        ; TODO: here we would want the teams to move in some way that the small world network (clustering) becomes visible
        setxy random-xcor random-ycor
      ]
    ]
  ] [
    create-teams n-teams [
      setxy random-xcor random-ycor
    ]
  ]


  ask teams [
    set shape "circle"
    set color 65
    ; create resource distribution
    if effort-dist = "uniform" [set resources random-float 1]
    if effort-dist = "left-skewed" [
      let x random-gamma 2 1
      set resources (x / (x + random-gamma 7 1))
    ]
    if effort-dist = "right-skewed" [
      let x random-gamma 7 1
      set resources (x / (x + random-gamma 2 1))
    ]
    set resources-last-round resources
    set individual-utility initial-utility
    set descriptive-norm initial-norm
    set shared-data? false
  ]



  reset-ticks
end

to go
  tick
  update-indices
  if data-sharing? [
    share-data
  ]

  generate-proposals
  award-grants

  if data-sharing? [
    update-utility
    update-norms
  ]


end

to generate-proposals
  ask teams [
    let mu ( 1 - sharing-incentive ) * resources + inv_effort * sharing-incentive
    set proposal-strength random-normal mu proposal-sigma
  ]
end

to award-grants
  ; base funding
  ask teams [
    set resources resources + base-gain
  ]

  ; if we mandate sharing, we need to remove non-eligible teams
  let eligible-teams teams
  if mandate-sharing? [
    set eligible-teams teams with [shared-data?]
  ]

  let n-grants n-teams * funded-share / 100

  set rank-list sort-on [(- proposal-strength)] eligible-teams ; need to invert proposal-strength, so that higher values are on top of the list
  set top-teams ifelse-value (length rank-list < n-grants) [rank-list] [ sublist rank-list 0 n-grants ] ; https://stackoverflow.com/a/40712061/3149349

  ; decrease resources for all (since writing grants costs resources), and
  let application-penalty-perc application-penalty / 100 ; convert back to percentage
  ask teams [ set resources resources * (1 - application-penalty-perc) ]
  ; add further one's for some (when receiving funding)
  let funding-per-team funder-resources / (funded-share / n-teams)
  foreach top-teams [x -> ask x [ set resources resources + funding-per-team ] ]
end



to update-utility
  ask teams [
    ifelse shared-data?
    [
      ifelse resources > resources-last-round
      [ increase-utility ]
      [ decrease-utility ]
    ]
    [
      ifelse resources > resources-last-round
      [ decrease-utility ]
      [ increase-utility ]
    ]
  ]
end

to increase-utility
  set individual-utility individual-utility + utility-change
  if individual-utility > 5 [set individual-utility 5]
end

to decrease-utility
  set individual-utility individual-utility - utility-change
  if individual-utility < -5 [set individual-utility -5]
end


to update-norms
  ask teams [
    let neighbours nw:turtles-in-radius 1
    let n-neighbours count neighbours
    let n-neighbours-sharing count neighbours with [shared-data?]
    set descriptive-norm n-neighbours-sharing / n-neighbours - .5
  ]
end


to share-data
  ask teams [
    set effort b_utility * individual-utility + b_norm * descriptive-norm
    set inv_effort 1 / (1 + exp ( - effort ))
    set shared-data? random-float 1 > 1 - inv_effort
  ]

  if sharing-costs? [
    ask teams with [shared-data?] [
      ; resources are redistributed as a consequence of data sharing
      ; the size depends on effort, but with a dampener, so only ever half of resources can get redistributed
      let r-to-redistribute resources * .5 * inv_effort ; map the effort back onto [0, 1] so it can serve as a multiplier

      ifelse not redistribute-costs? [
        ; control case for when resources are not redistributed, but simply subtracted from the team
        set resources resources - r-to-redistribute
        if resources < 0 [ set resources 0 ]
      ] [
        ; if we redistribute costs, we are here
        ; we still need to subtract the resources from each team
        set resources resources - r-to-redistribute
        if resources < 0 [ set resources 0 ]


        ; not all of the costs are translated directly to others.
        ; the combination with 'effort-multiplier' can be understood as indicating that with no effort, there is fewer resources
        ; to be redistributed than went into generating the data. Above efforts of .4, there is some surplus starting.
        ; in practical terms, this ratio prevents the total sum of resources from "running away" into exponential growth
        let resource-transfer-ratio .8 ; this was not initially conceptualised in the gdoc

        ; effort-multiplier: this sets to which degree invested effort creates a surplus for the community and/or the individual
        ; together with the resource-transfer-ratio as a base, and with effort/2, this determines how much resources are redistributed
        ; maybe this, in combination with values for 'originator-benefit' can be used to model different fields:
        ; in some there would be a high "resource transfer", meaning a strong competition effect, while in others this might be low
        let effort-multiplier .5 ; this is called "theta" in the gdoc
        set r-to-redistribute r-to-redistribute * (resource-transfer-ratio + effort-multiplier * effort)

        let r-to-self r-to-redistribute * originator-benefit
        let r-to-others r-to-redistribute - r-to-self

        ; enter dividends into pool
        set sharing-dividend-pool sharing-dividend-pool + r-to-self


        ask other teams [
          ; give all other teams something back. this is the pool that is split up
          set resources resources + r-to-others / (n-teams - 1)
        ]
      ]
    ]

    ask teams [
      ; ask all teams to pay themselves dividends, if they have anything in the pool
      let dividend-rate .3
      set resources resources + sharing-dividend-pool * dividend-rate
      ; update dividend pool (remove the dividends paid out)
      set sharing-dividend-pool sharing-dividend-pool * (1 - dividend-rate)
    ]

  ]
end

to update-indices
  ; update color to represent effort, and set resources for next round
  ask teams [
    set color 60 + 10 * (1 - inv_effort) ; dark colour represent high effort
    set resources-last-round resources
  ]
end


to-report max-resources
  report max [ resources ] of teams
end

to-report %-sharing
  report 100 * count teams with [shared-data?] / n-teams
end


; the initial computation for the gini index was adapted from the peer reviewer game, bianchi et al. DOI: 10.1007/s11192-018-2825-4 (https://www.comses.net/codebases/6b77a08b-7e60-4f47-9ebb-6a8a2e87f486/releases/1.0.0/)
; the below and now used implementation was provided by TurtleZero on Stackoverflow: https://stackoverflow.com/a/70524851/3149349
to-report gini [ samples ]
  let n length samples
  let indexes (range 1 (n + 1))
  let bias-function [ [ i yi ] -> (n + 1 - i) * yi ]
  let biased-samples (map bias-function indexes sort samples)
  let ratio sum biased-samples / sum samples
  let G (1 / n ) * (n + 1 - 2 * ratio)
  report G
end
@#$#@#$#@
GRAPHICS-WINDOW
270
10
514
255
-1
-1
7.152
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
32
100
204
133
proposal-sigma
proposal-sigma
0
1
0.25
.01
1
NIL
HORIZONTAL

BUTTON
102
18
165
51
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
38
18
101
51
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
566
13
808
195
proposal strength
NIL
NIL
-1.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 false "" "histogram [proposal-strength] of teams"

PLOT
569
199
769
349
resource distribution
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [resources] of teams"

MONITOR
271
310
365
355
max resources
max-resources
2
1
11

MONITOR
369
308
467
353
sum of resources
sum [resources] of teams
2
1
11

MONITOR
469
307
558
352
min resources
min [resources] of teams
2
1
11

SWITCH
35
266
167
299
data-sharing?
data-sharing?
0
1
-1000

SLIDER
35
62
207
95
n-teams
n-teams
1
500
100.0
1
1
NIL
HORIZONTAL

PLOT
985
197
1185
347
Effort (inverse logit)
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [inv_effort] of teams"

PLOT
1064
10
1340
198
% sharing data
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot %-sharing"

PLOT
780
200
980
350
Gini of resources
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot gini [resources] of teams"

SLIDER
33
303
205
336
utility-change
utility-change
0
.2
0.03
.01
1
NIL
HORIZONTAL

SWITCH
32
342
187
375
sharing-costs?
sharing-costs?
0
1
-1000

PLOT
807
11
1061
195
Mean effort
NIL
NIL
0.0
10.0
-1.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [effort] of teams"

SLIDER
36
187
208
220
initial-utility
initial-utility
-4
4
0.0
.1
1
NIL
HORIZONTAL

BUTTON
168
18
225
51
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1188
199
1388
349
sum of resources
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [resources] of teams"

SLIDER
32
414
204
447
originator-benefit
originator-benefit
0
.4
0.36
.01
1
NIL
HORIZONTAL

SWITCH
32
378
189
411
redistribute-costs?
redistribute-costs?
1
1
-1000

SWITCH
32
454
187
487
mandate-sharing?
mandate-sharing?
0
1
-1000

SLIDER
29
489
201
522
sharing-incentive
sharing-incentive
0
1
0.2
.01
1
NIL
HORIZONTAL

CHOOSER
342
585
480
630
network
network
"none" "random" "small-world"
0

SLIDER
166
573
338
606
b_utility
b_utility
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
165
609
337
642
b_norm
b_norm
0
1
0.51
0.01
1
NIL
HORIZONTAL

PLOT
577
354
833
534
Mean utility
NIL
NIL
0.0
10.0
-4.0
4.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [individual-utility] of teams"

SLIDER
35
224
207
257
initial-norm
initial-norm
-.5
.5
0.0
.1
1
NIL
HORIZONTAL

PLOT
831
356
1101
536
descriptive norms
NIL
NIL
-0.5
0.5
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [descriptive-norm] of teams"

MONITOR
270
260
368
305
max effort
max [effort] of teams
2
1
11

PLOT
577
536
839
688
Individual-utility
NIL
NIL
-5.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [individual-utility] of teams"

SLIDER
270
367
442
400
base-gain
base-gain
0
0.5
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
270
407
447
440
application-penalty
application-penalty
0
50
20.0
1
1
%
HORIZONTAL

SLIDER
271
445
443
478
funded-share
funded-share
1
100
15.0
1
1
%
HORIZONTAL

SLIDER
271
484
443
517
funder-resources
funder-resources
0
10
3.0
.1
1
NIL
HORIZONTAL

PLOT
840
535
1098
686
SD of utility
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot standard-deviation [individual-utility] of teams"

CHOOSER
37
137
175
182
effort-dist
effort-dist
"uniform" "left-skewed" "right-skewed"
2

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
