##
## Imports
##
ex = (exports ? this).examine

##
## Constants
##
defaultTotalTime = 4000    # ms
rotationTime     = 0.2     # one degree rotation time = rotationTime * one step time

shadowTraceColor = "yellow"
normalTraceColor = "red"

turtleImageCorrection =
  x: 10
  y: 16

activeTurtle = null

# Rotate event
RT = (a) ->
  type: "rotate"
  angle: a

# Move event
MV = (len) ->
  type: "go"
  length: len

class Turtle
  constructor: (@startX = 100, @startY = 100, @angle = 0,
                @totalTime = defaultTotalTime) ->

    # Stack of actions to perform
    @actions = []

    # Graph for actual relative coordinates
    @graph = new EmbeddedGraphWithGo(0, 0, @angle)

    @im = turtle.paper.image "examples/zelva/zelva.png"
                           , @startX - turtleImageCorrection.x
                           , @startY - turtleImageCorrection.y
                           , 20, 30
    @im.rotate @angle

  addAction: (a) ->
    @actions.push a

  countTime: ->
    totalSteps = _.reduce @actions, (memo, action) ->
      memo += action.length                           if action.length?
      memo += (rotationTime * Math.abs(action.angle)) if action.angle?
      memo
    , 0
    @msForStep = @totalTime / totalSteps

  runActions: (callback, pos = undefined) ->
    if @actions.length == 0
      callback()
      return

    unless pos?
      pos = new Position 0, 0, @angle

    currentAction = @actions[0]
    aniTime = @msForStep *
      (currentAction.length ? (rotationTime * Math.abs(currentAction.angle)))

    switch currentAction.type
      when "go"
        len = currentAction.length
        [oldX, oldY] = [pos.x, pos.y]
        [newX, newY] = pos.go len

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, newX, newY, aniTime

      when "rotate"
        a = currentAction.angle
        pos.rotate a
        trans = "...r#{a}"

    @actions.shift()

    @im.animate transform: trans
              , aniTime
              , "linear"
              , => @runActions(callback, pos)

class Position
  constructor: (@x, @y, @angle) ->

  go: (steps) ->
    [@x, @y] = computeCoords @x, @y, steps, @angle

  rotate: (a) ->
    @angle += a

class EmbeddedGraphWithGo
  constructor: (startX, startY, startAngle) ->
    @vertices = []
    @vertices.push
      x: startX
      y: startY
      edges: []

    # Actual position
    @pos = new Position startX, startY, startAngle

  findVertex: (x, y) ->
    _.find @vertices, (v) -> Math.abs(v.x - x) < 0.0001 and Math.abs(v.y - y) < 0.0001

  go: (steps) ->
    [oldX, oldY] = [@pos.x, @pos.y]
    [newX, newY] = @pos.go steps

    oldV = @findVertex(oldX, oldY)
    newV = @findVertex(newX, newY)

    if !newV?
      newV =
        x: newX
        y: newY
        edges: []
      @vertices.push newV

    oldV.edges.push newV
    newV.edges.push oldV

  rotate: (a) ->
    @pos.rotate a

  degreeSequence: ->
    (_.map @vertices, (v) -> v.edges.length).sort()


computeCoords = (x,y,len,angle) ->
  newX = x + len * Math.sin(angle / 360 * Math.PI * 2)
  newY = y - len * Math.cos(angle / 360 * Math.PI * 2)
  [newX,newY]

go = (steps) ->
  activeTurtle.addAction (MV steps)
  activeTurtle.graph.go steps

right = (angle) ->
  activeTurtle.addAction (RT angle)
  activeTurtle.graph.rotate angle

left = (angle) ->
  right -angle

repeat = (n, f) ->
  i = 0
  args = Array::slice.call arguments, 2

  while i < n
    f args...
    i++

drawLine = (fromX, fromY, toX, toY, aniTime) ->
  atSX = activeTurtle.startX
  atSY = activeTurtle.startY

  turtle.paper.path("M#{fromX + atSX} #{fromY + atSY}L#{fromX + atSX} #{fromY + atSY}")
    .attr(stroke: (if turtle.shadow then shadowTraceColor else normalTraceColor))
    .animate { path: "M#{fromX + atSX} #{fromY + atSY}L#{toX + atSX} #{toY + atSY}" }, aniTime

(exports ? this).turtle =
  lastDegreeSequence: undefined

  run: (code, canvas, shadow) ->
    @shadow = shadow
    turtle.paper.remove()  if turtle.paper

    paper = Raphael(canvas, 380, 480)
    turtle.paper = paper
    paper.rect(0, 0, 380, 480).attr fill: "#fff"

    activeTurtle = new Turtle()

    @result = ex.test
      code: code
      environment:
        go: go
        right: right
        left: left
        repeat: repeat

    try
      activeTurtle.countTime()
      @lastDegreeSequence = activeTurtle.graph.degreeSequence()
      activeTurtle.runActions (->)
    catch e
      @lastDegreeSequence = undefined
      console.log "Problem while turtle drawing."
      console.log e.toString()
    finally
      return @result
