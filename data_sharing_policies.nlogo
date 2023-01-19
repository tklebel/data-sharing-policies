extensions [ nw ]

globals [
  rank-list
  top-teams
  bottom-teams
]

turtles-own [
  resources
  resources-last-round
  total-funding ; record how much funding each group has accrued over time
  proposal-strength
  effort
  inv_effort ; the inv_logit of the effort (mapping it back onto [0, 1]
  individual-utility
  descriptive-norm
  shared-data?
  funded? ;whether they got funding in this round
  sharing-dividend-pool
  initial-resources
]


to setup
  clear-all

  ask patches [set pcolor white]

  (ifelse
    network = "random"      [ nw:generate-random turtles links n-teams 0.02 ]
    network = "small-world" [ nw:generate-watts-strogatz turtles links n-teams 3 .2 ]
                            [ create-turtles n-teams ]
  )

  ask turtles [
    set shape "circle"
    set color 65
    ; radius for the circle
    fd 24
    ; create resource distribution
    set resources (ifelse-value
      resources-dist = "uniform" [ random-float 1 ]
      resources-dist = "right-skewed" [ gamma-dist 2 7 ]
      resources-dist = "left-skewed" [ gamma-dist 7 2 ]
    )
    set resources-last-round resources
    set initial-resources resources
    ; we want random numbers in the interval [-4, 4], but netlogo can't do that directly, so we re-center twice
    ; alternatively, we could do some beta distribution (as above)
    set individual-utility ( random-float (max-initial-utility + 4 )) - 4
    set descriptive-norm initial-norm
    set shared-data? false
  ]
  reset-ticks
end


to go
  tick
  update-indices
  if data-sharing? [ share-data ]
  generate-proposals
  award-grants
  if data-sharing? [
    update-utility
    update-norms
  ]
end


to update-indices
  ; update color to represent effort, and set resources for next round
  ask turtles [
    set color 60 + 10 * (1 - inv_effort) ; dark colour represent high effort
    set resources-last-round resources
    set funded? false
  ]
end

to share-data
  ask turtles [
    set effort b_utility * individual-utility + ifelse-value network = "none" [ 0 ] [ b_norm * descriptive-norm ]
    set inv_effort 1 / (1 + exp ( - effort ))
    set shared-data? random-float 1 > 1 - inv_effort

    if debug? [
      type "i am turtle " print who
      type "my effort is " print effort
      type "my probability of sharing data is " print inv_effort
      type ifelse-value shared-data? [ "i shared data" ] [ "i did NOT share data" ]
    ]

    set resources resources - (1 / (n-teams * 10)) * inv_effort ; costs are up to 10% of base funding budget
  ]
end

to generate-proposals
  ; normalise resources. this is necessary so that effort and resources are on the same scale
  ; find max resources
  let min-resources min [resources] of turtles
  let range-resources max [ resources ] of turtles - min-resources
  ask turtles [
    ; https://stats.stackexchange.com/a/70807/42950
    let norm-resources (resources - min-resources) / range-resources
    let mu ( 1 - sharing-incentive ) * norm-resources + inv_effort * sharing-incentive
    set proposal-strength random-normal mu proposal-sigma

    if debug? [
      type "i am turtle " print who
      type "my resources are " print resources
      type "my normalised resources are " print norm-resources
      type "the strength of my proposal is " print proposal-strength
    ]

  ]
end

to award-grants

  ; base funding + decrease resources for all (since writing grants costs resources),
  ask turtles [
    set resources (resources + 1 / n-teams) * (1 - application-penalty)
  ]

  let n-grants n-teams * funded-share
  set rank-list sort-on [(- proposal-strength)] turtles ; need to invert proposal-strength, so that higher values are on top of the list
  set top-teams ifelse-value (length rank-list < n-grants) [ rank-list ] [ sublist rank-list 0 n-grants ] ; https://stackoverflow.com/a/40712061/3149349

  if debug? [
    type "the ranking of teams is " print rank-list
    type "the top teams are " print top-teams
  ]

  ; add further one's for some (when receiving funding)
  let funding-per-team third-party-funding-ratio / n-grants
  foreach top-teams [a-team ->
    ask a-team [
      set resources resources + funding-per-team
      set funded? true
      set total-funding total-funding + funding-per-team
    ]
  ]

  if debug? [
    ask turtles [
      type "i am team " print who
      type "last round my resources were " print resources-last-round
      type "the strength of my proposal is " print proposal-strength type "(max is " print max [ proposal-strength ] of turtles type ")"
      type ifelse-value funded? [ "my proposal was funded" ] [ "my proposal was NOT funded" ]
      type "now my resources are " print resources
    ]
  ]
end

to update-utility
  ask turtles [
    ifelse (shared-data? and resources > resources-last-round) or (not shared-data? and not (resources > resources-last-round))
    [ set individual-utility individual-utility + utility-change
      if individual-utility > 5 [ set individual-utility 5 ]
    ]
    [ set individual-utility individual-utility - utility-change
      if individual-utility < -5 [ set individual-utility -5 ]
    ]
  ]
end

to update-norms
  ask turtles [
    set descriptive-norm ifelse-value any? link-neighbors
    [ count link-neighbors with [ shared-data? ] / count link-neighbors - 0.5] [ -0.5 ]
    ; rescale norm. this is to ensure it is on the same scale as the utility
    set descriptive-norm descriptive-norm * 10
  ]
end


; reporters --------------------

to-report upper-quartile [ dist ]
  let med median dist
  let upper filter [ x -> x > med ] dist
  report ifelse-value empty? upper [ med ] [ median upper ]
end

to-report lower-quartile [ dist ]
  let med median dist
  let lower filter [ x -> x < med ] dist
  report ifelse-value empty? lower [ med ] [ median lower ]
end

to-report gamma-dist [ alpha-1 alpha-2 ]
  let x random-gamma alpha-1 1
  report x / (x + random-gamma alpha-2 1)
end

; the initial computation for the gini index was adapted from the peer reviewer game, bianchi et al. DOI: 10.1007/s11192-018-2825-4 (https://www.comses.net/codebases/6b77a08b-7e60-4f47-9ebb-6a8a2e87f486/releases/1.0.0/)
; the below and now used implementation was provided by TurtleZero on Stackoverflow: https://stackoverflow.com/a/70524851/3149349
to-report gini [ samples ]
  ; if we have only zeros, directly return 0
  ifelse sum samples = 0 [
    report 0
  ][
    let n length samples
    let indexes (range 1 (n + 1))
    let bias-function [ [ i yi ] -> (n + 1 - i) * yi ]
    let biased-samples (map bias-function indexes sort samples)
    let ratio sum biased-samples / sum samples
    let G (1 / n ) * (n + 1 - 2 * ratio)
    report G
  ]
end

to-report mean-funding-within [ agentset ]
  report precision mean [ total-funding ] of agentset 2
end
@#$#@#$#@
GRAPHICS-WINDOW
257
10
502
256
-1
-1
4.65
1
10
1
1
1
0
0
0
1
-25
25
-25
25
0
0
1
ticks
30.0

SLIDER
36
100
208
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
36
18
99
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
"default" 0.05 1 -16777216 false "" "histogram [proposal-strength] of turtles"

PLOT
569
199
769
349
resource distribution
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
"default" 0.05 1 -16777216 true "" "histogram [resources] of turtles"

MONITOR
271
310
365
355
max resources
max [ resources ] of turtles
2
1
11

MONITOR
369
308
467
353
sum of resources
sum [resources] of turtles
2
1
11

MONITOR
469
307
558
352
min resources
min [resources] of turtles
2
1
11

SWITCH
39
266
171
299
data-sharing?
data-sharing?
0
1
-1000

SLIDER
39
62
211
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
"default" 0.05 1 -16777216 true "" "histogram [inv_effort] of turtles"

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
"default" 1.0 0 -16777216 true "" "plot count turtles with [ shared-data? ] / count turtles * 100"

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
"default" 1.0 0 -16777216 true "" "plot gini [resources] of turtles"

SLIDER
37
303
209
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
"default" 1.0 0 -16777216 true "" "plot mean [effort] of turtles"

SLIDER
40
187
212
220
max-initial-utility
max-initial-utility
-4
4
4.0
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
"default" 1.0 0 -16777216 true "" "plot sum [resources] of turtles"

SLIDER
282
378
454
411
sharing-incentive
sharing-incentive
0
1
0.6
.01
1
NIL
HORIZONTAL

CHOOSER
412
511
550
556
network
network
"none" "random" "small-world"
0

SLIDER
236
499
408
532
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
235
535
407
568
b_norm
b_norm
0
1
1.0
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
"default" 1.0 0 -16777216 true "" "plot mean [individual-utility] of turtles"

SLIDER
39
224
211
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
-5.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.05 1 -16777216 true "" "histogram [descriptive-norm] of turtles"

MONITOR
270
260
368
305
max effort
max [effort] of turtles
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
"default" 0.1 1 -16777216 true "" "histogram [individual-utility] of turtles"

SLIDER
42
382
219
415
application-penalty
application-penalty
0
1
0.05
0.05
1
NIL
HORIZONTAL

SLIDER
284
420
456
453
funded-share
funded-share
0
1
0.85
0.05
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
"default" 1.0 0 -16777216 true "" "plot standard-deviation [individual-utility] of turtles"

CHOOSER
41
137
179
182
resources-dist
resources-dist
"uniform" "left-skewed" "right-skewed"
0

SLIDER
43
344
219
377
third-party-funding-ratio
third-party-funding-ratio
0
5
2.0
.1
1
NIL
HORIZONTAL

PLOT
1102
355
1406
533
Total-funding
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"q1" 1.0 0 -2674135 true "" "plot mean-funding-within turtles with [initial-resources < lower-quartile [initial-resources] of turtles ]"
"q2" 1.0 0 -14439633 true "" "plot mean-funding-within turtles with [initial-resources >= lower-quartile [initial-resources] of turtles and initial-resources < median [initial-resources] of turtles]"
"q3" 1.0 0 -14070903 true "" "plot mean-funding-within turtles with [initial-resources >= median [initial-resources] of turtles and initial-resources < upper-quartile [initial-resources] of turtles]"
"q4" 1.0 0 -7858858 true "" "plot mean-funding-within turtles with [initial-resources >= upper-quartile [initial-resources] of turtles ]"

SWITCH
42
451
145
484
debug?
debug?
1
1
-1000

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
<experiments>
  <experiment name="baseline" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>gini [resources] of teams</metric>
    <metric>gini [total-funding] of teams</metric>
    <metric>mean [effort] of teams</metric>
    <metric>%-sharing</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q4"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q4"]</metric>
    <enumeratedValueSet variable="initial-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_norm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sharing-incentive">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="application-penalty">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resources-dist">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proposal-sigma">
      <value value="0.25"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-teams">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="third-party-funding-ratio">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-change">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_utility">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;none&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funded-share">
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharing?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="max-initial-utility" first="-4" step="2" last="4"/>
  </experiment>
  <experiment name="vary_incentives" repetitions="50" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>gini [resources] of teams</metric>
    <metric>gini [total-funding] of teams</metric>
    <metric>mean [effort] of teams</metric>
    <metric>%-sharing</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q4"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q4"]</metric>
    <enumeratedValueSet variable="initial-norm">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_norm">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="sharing-incentive" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="application-penalty">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resources-dist">
      <value value="&quot;uniform&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proposal-sigma">
      <value value="0.25"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-teams">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="third-party-funding-ratio">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-change">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_utility">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;none&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funded-share">
      <value value="15"/>
      <value value="50"/>
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharing?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-initial-utility">
      <value value="-3"/>
      <value value="0"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="full_sweep" repetitions="60" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>gini [resources] of teams</metric>
    <metric>gini [total-funding] of teams</metric>
    <metric>mean [effort] of teams</metric>
    <metric>%-sharing</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>mean-funding-within teams with [initial-resources-quantile = "q4"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q1"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q2"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q3"]</metric>
    <metric>data-sharing-within teams with [initial-resources-quantile = "q4"]</metric>
    <enumeratedValueSet variable="initial-norm">
      <value value="-0.5"/>
      <value value="0"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_norm">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="sharing-incentive" first="0" step="0.2" last="1"/>
    <enumeratedValueSet variable="application-penalty">
      <value value="5"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resources-dist">
      <value value="&quot;uniform&quot;"/>
      <value value="&quot;left-skewed&quot;"/>
      <value value="&quot;right-skewed&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="proposal-sigma">
      <value value="0.25"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-teams">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="third-party-funding-ratio">
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="utility-change">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="b_utility">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network">
      <value value="&quot;none&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;small-world&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="funded-share">
      <value value="15"/>
      <value value="50"/>
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="data-sharing?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-initial-utility">
      <value value="-3"/>
      <value value="0"/>
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
