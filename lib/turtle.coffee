defaultTotalTime = 4000       # ms
rotationTime = 0.2            # one degree rotation time = rotationTime * one step time

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
    
    @graph = new EmbeddedGraphWithGo(@x, @y)

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
    @msForStep = @totalTime / totalSteps

  runActions: (callback) ->
    if @actions.length == 0
      callback()
      return

    currentAction = @actions[0]
    aniTime = @msForStep * (currentAction.length ? (rotationTime * currentAction.angle))
    switch currentAction.type
      when "go"
        len = currentAction.length
        [oldX, oldY] = [@x, @y]
        [@x, @y] = computeCoords @x, @y, len, @angle

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, @x, @y, aniTime
        
        @graph.go oldX, oldY, @x, @y

      when "rotate"
        a = currentAction.angle
        @angle += a
        trans = "...r#{a}"

    @actions.shift()
    
    @im.animate transform: trans
              , aniTime
              , "linear"
              , => @runActions(callback)

class EmbeddedGraphWithGo
  constructor: (startX, startY) ->
    @vertices = []
    @vertices.push
      x: startX
      y: startY
      edges: []

  findVertex: (x, y) ->
    _.find @vertices, (v) -> Math.abs(v.x - x) < 0.0001 and Math.abs(v.y - y) < 0.0001

  go: (oldX, oldY, newX, newY) ->
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
  
  degreeSequence: ->
    (_.map @vertices, (v) -> v.edges.length).sort()


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

drawLine = (fromX, fromY, toX, toY, aniTime) ->
  turtle.paper.path("M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}")
    .attr(stroke: (if turtle.shadow then shadowTraceColor else normalTraceColor))
    .animate { path: "M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{toX + activeTurtle.startX} #{toY + activeTurtle.startY}" }, aniTime

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
    activeTurtle.runActions ->
      console.log activeTurtle.graph.degreeSequence()
