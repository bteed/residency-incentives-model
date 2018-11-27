globals [
  cash ;; int : the sum of revenues to date less the sum of expenses to date
  npv-residents ;; list of floats : a list of the npv of each resident, reported immediately before death
  years-stayed ;; list of floats : a list of how many years each resident stayed, reported immediately before death
  govt-dcf ;; list of floats : discounted cashflows to the govt at each tick
  dcf-stability ;; list of floats : standard deviation of govt-dcf over the past 5(?) years at each tick
  total-responses ;; int : the total number of people who have immigrated to date
]

breed [residents resident]
residents-own [
  rev-per-month ;; int : the amount a resident contributes to government revenue per period
  cost-per-month ;; int : the amount a resident costs the government per period
  my-cashflows ;; list of ints : the net cashflow from a resident at each period
  ticks-resident ;; list of ints : a list of the ticks during which the resident existed
  is-abuser? ;; boolean : if true, resident will emigrate immediately when incentives stop
]

to setup
  clear-all

  set npv-residents ( list )
  set years-stayed ( list )
  set govt-dcf ( list )
  set dcf-stability ( list )

  reset-ticks
end

to go

  set govt-dcf lput 0 govt-dcf

  ask residents [
    incent
    maybe-emigrate
    reside
  ]

  set cash cash + govt-cashflow

  immigrate ( random-poisson ( response-rate / 12 ) )

  pay-bills

  if ( ticks > 60 ) [
    let tick-stability ( standard-deviation sublist govt-dcf ( ticks - 60 ) ticks )
    set dcf-stability lput tick-stability dcf-stability
    if ( tick-stability < ( max dcf-stability / 100 ) ) [ stop ]
  ]

  tick
end

to incent
  let base-cost ( resident-cost / 12 )
  let incentive-cost ( incent-amt / over-n-months )

  ifelse ( n-ticks-resident <= over-n-months ) [
    set cost-per-month ( base-cost + incentive-cost )
  ] [
    set cost-per-month base-cost
  ]
end

to immigrate [ n ]
  ask n-of n patches [
    sprout-residents 1 [
      set shape "circle"
      set color white
      set rev-per-month resident-value / 12
      set cost-per-month resident-cost / 12
      set my-cashflows ( list 0 )
      set ticks-resident ( list ticks )
      set is-abuser? ( random-float 1 < ( pct-abusers / 100 ) )
    ]
    set total-responses total-responses + 1
  ]
end

to reside

  let r monthly-discount-rate annual-discount-rate
  let my-dcf ( rev-per-month - cost-per-month ) / ( 1 + r ) ^ ticks

  set my-cashflows lput ( my-dcf ) my-cashflows
  set govt-dcf replace-item ticks govt-dcf ( last govt-dcf + my-dcf )

  set ticks-resident lput ticks ticks-resident
end

to maybe-emigrate
  let legit-emigrate? random-poisson ( 1 / (exp-years-resident * 12) ) >= 1
  let skip-town? ( is-abuser? = true and n-ticks-resident > over-n-months )
  if ( legit-emigrate? or skip-town? ) [
    set npv-residents lput ( npv my-cashflows n-ticks-resident ) npv-residents
    set years-stayed lput ( n-years-resident )  years-stayed
    die
  ]
end

to-report mean-residency
  ifelse ( any? residents) [
    report mean [ n-years-resident ] of residents
  ] [
    report 0
  ]
end

to-report govt-cashflow
  report sum [ rev-per-month ] of residents -  sum [ cost-per-month ] of residents
end

to-report dcf [ cashflows n-periods ]
  let r monthly-discount-rate annual-discount-rate
  report ( map [ [ c t ] -> c / (1 + r) ^ t ] cashflows range n-periods )
end

to-report npv [cashflows n-periods ]
  report sum dcf cashflows n-periods
end

to-report mean-npv
  ifelse ( not empty? npv-residents) [
    report mean npv-residents
  ] [
    report 0
  ]
end

to-report mean-years-stayed
  ifelse ( not empty? years-stayed) [
    report mean years-stayed
  ] [
    report 0
  ]
end

to-report monthly-discount-rate [ r ]
  let r-annual r / 100
  let r-monthly ( ( 1 + r-annual ) ^ ( 1 / 12 ) ) - 1
  report r-monthly
end

to-report n-ticks-resident
  report length ticks-resident
end

to-report n-years-resident
  report n-ticks-resident / 12
end

to plot-green-red [ x y ]
  let plot-color green
  if ( y < 0 ) [ set plot-color red ]
  set-plot-pen-color plot-color
  plotxy x y
end

to pay-bills
  let monthly-bills fixed-costs / 12
  let r monthly-discount-rate annual-discount-rate

  set govt-dcf replace-item ticks govt-dcf ( last govt-dcf - ( monthly-bills / ( 1 + r ) ^ ticks ) )
end

to auto-stop
  if ( ticks > 60 ) [
    let tick-stability ( standard-deviation sublist govt-dcf ( ticks - 60 ) ticks )
    set dcf-stability lput tick-stability dcf-stability
    if ( tick-stability < ( max dcf-stability / 20 ) ) [ stop ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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
1
1
1
ticks
30.0

BUTTON
103
55
178
88
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
13
55
94
88
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

PLOT
933
19
1133
169
population
year
n
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plotxy \n  ticks / 12\n  count residents "
"pen-1" 1.0 0 -2674135 true "" "plotxy \n  ticks / 12\n  count residents with [ is-abuser? ]"

SLIDER
2
98
175
131
response-rate
response-rate
1
10
10.0
1
1
/y
HORIZONTAL

SLIDER
2
140
174
173
exp-years-resident
exp-years-resident
1
10
5.0
1
1
y
HORIZONTAL

MONITOR
933
178
1013
223
population
count residents
17
1
11

MONITOR
999
395
1075
440
mean years
mean-residency
1
1
11

PLOT
933
233
1133
383
years resident - rolling mean
year
years resident
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plotxy\n  ticks / 12\n  mean-residency "
"pen-1" 1.0 0 -7500403 false "plotxy plot-x-min exp-years-resident" "plotxy \n  plot-x-max \n  exp-years-resident"

PLOT
932
450
1132
600
years resident - distribution
years resident
n residents
0.0
20.0
0.0
10.0
true
false
"" "ifelse (empty? years-stayed ) [\n  set-plot-x-range 0 10\n] [\n  set-plot-x-range 0 ( ( precision ( max years-stayed ) -1 ) + 10 )\n]"
PENS
"default" 5.0 1 -16777216 true "" "set-histogram-num-bars 20\nhistogram years-stayed"
"mean" 1.0 0 -2674135 true "" "plot-pen-reset\nplotxy mean-years-stayed plot-y-min\nplotxy mean-years-stayed plot-y-max"

SLIDER
4
450
194
483
annual-discount-rate
annual-discount-rate
0
20
5.0
1
1
%
HORIZONTAL

INPUTBOX
14
192
97
252
resident-value
25000.0
1
0
Number

INPUTBOX
102
192
186
252
resident-cost
15000.0
1
0
Number

PLOT
661
15
861
165
govt-dcf
year
cashflow
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "clear-plot\n( foreach ( range ticks ) govt-dcf [ [ x y ] -> plot-green-red x / 12 y ] )"
"pen-1" 1.0 0 -7500403 true "" "plotxy plot-x-min 0\nplotxy plot-x-max 0"

MONITOR
661
175
771
220
npv of govt-dcf
sum govt-dcf
0
1
11

INPUTBOX
12
324
87
384
incent-amt
10000.0
1
0
Number

INPUTBOX
97
326
188
386
over-n-months
12.0
1
0
Number

SLIDER
8
396
180
429
pct-abusers
pct-abusers
0
100
50.0
1
1
%
HORIZONTAL

MONITOR
1051
178
1133
223
pct abusers
count residents with [ is-abuser?  = true ] / count residents
2
1
11

INPUTBOX
102
254
185
314
fixed-costs
100000.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

The model is intended to calculate, based on a range of parameters, the present value of discounted future cashflows attributable to a government program to incentivize new residents to move into a jurisdiction. 

## HOW IT WORKS

The only agents are residents. Residents immigrate at a poisson-distributed rate of `response-rate` (i.e. response to the incentive program) per year. While present, a resident contributes `resident-value` per year to government cashflows and consumes a baseline of `resident-cost` worth of government services per year. 

The residency incentive program provides new immigrants a total of `incent-amt` over the resident's first `over-n-months` of residency. 

`pct-abusers` percent of the new immigrants are interested only in the incentive and will emigrate as soon as they stop receiving the incentive. Otherwise, residents emigrate with a poisson-distributed probability such that each resident is expected to have one "emigration event" every `exp-years-resident` years.

Each tick of the model represents one month. At each tick, residents contribute (positively or negatively) to the total government discounted cashflow at that tick. The discounted cashflow is calculated monthly at a discount rate of `annual-discount-rate` with time 0 being first month of the ***program***, not of the resident's period of residency. For that reason, cashflows early in the program contribute significantly more to the total net present value than later cashflows.

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
NetLogo 6.0.4
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
