defaultTotalTime = 4000       # ms
rotationTime = 0.2            # one degree rotation time = rotationTime * one step time
msForStep = undefined         # will be computed

shadowTraceColor = "yellow"
normalTraceColor = "red"

turtleImageCorrection =
  x: 10
  y: 16

activeTurtle = null

RT = (a) ->
  type: "rotate"
  angle: a

MV = (len) ->
  type: "go"
  length: len

class Turtle
  constructor: (@startX = 100, @startY = 100, @angle = 0, @totalTime = defaultTotalTime) ->
    # Stack of actions to perform
    @actions = []

    @x = 0
    @y = 0

    @im = turtle.paper.image "examples/zelva/zelva.png"
                           , @startX - turtleImageCorrection.x
                           , @startY - turtleImageCorrection.y
                           , 20, 30
    @im.rotate @angle

  addAction: (a) ->
    @actions.push a

  countTime: ->
    totalSteps = _.reduce @actions, (memo, action) ->
      memo += action.length                   if action.length?
      memo += (rotationTime * action.angle)   if action.angle?
      memo
    , 0
    msForStep = totalTime / totalSteps
    console.log { totalSteps, msForStep }

  runActions: ->
    return if @actions.length == 0

    currentAction = @actions[0]
    switch currentAction.type
      when "go"
        len = currentAction.length
        [oldX, oldY] = [@x, @y]
        [@x, @y] = computeCoords @x, @y, len, @angle

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, @x, @y

      when "rotate"
        a = currentAction.angle
        @angle += a
        trans = "...r#{a}"

    @actions.shift()
    
    aniTime = msForStep * (currentAction.length ? (rotationTime * currentAction.angle))
    @im.animate transform: trans
              , aniTime
              , "linear"
              , => @runActions()


computeCoords = (x,y,len,angle) ->
  newX = x + len * Math.sin(angle / 360 * Math.PI * 2)
  newY = y - len * Math.cos(angle / 360 * Math.PI * 2)
  [newX,newY]

@go = (steps) ->
  activeTurtle.addAction (MV steps)

@right = (angle) ->
  activeTurtle.addAction (RT angle)

@left = (angle) ->
  right -angle

@repeat = (n, f) ->
  i = 0
  args = Array::slice.call arguments, 2

  while i < n
    f args...
    i++

drawLine = (fromX, fromY, toX, toY) ->
  timeNeeded = msForStep * Math.sqrt((fromX-toX)*(fromX-toX)+(fromY-toY)*(fromY-toY))
  turtle.paper.path("M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}")
    .attr(stroke: (if turtle.shadow then shadowTraceColor else normalTraceColor))
    .animate { path: "M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{toX + activeTurtle.startX} #{toY + activeTurtle.startY}" }, timeNeeded

(exports ? this).turtle =
  run: (code, canvas, shadow) ->
    @shadow = shadow
    turtle.paper.remove()  if turtle.paper

    paper = Raphael(canvas, 380, 480)
    turtle.paper = paper
    paper.rect(0, 0, 380, 480).attr fill: "#fff"

    activeTurtle = new Turtle()
    eval code
    activeTurtle.countTime()
    activeTurtle.runActions()
