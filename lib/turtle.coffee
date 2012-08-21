timeInt = 300

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
  constructor: (@startX = 100, @startY = 100, @angle = 0) ->
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

  runActions: ->
    return if @actions.length == 0

    switch @actions[0].type
      when "go"
        len = @actions[0].length
        [oldX, oldY] = [@x, @y]
        [@x, @y] = computeCoords @x, @y, len, @angle

        trans = "...t0,#{-len}"
        drawLine oldX, oldY, @x, @y

      when "rotate"
        a = @actions[0].angle
        @angle += a
        trans = "...r#{a}"

    @actions.shift()
    @im.animate transform: trans
              , timeInt
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
  turtle.paper.path("M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}")
    .attr(stroke: (if turtle.shadow then shadowTraceColor else normalTraceColor))
    .animate { path: "M#{fromX + activeTurtle.startX} #{fromY + activeTurtle.startY}L#{toX + activeTurtle.startX} #{toY + activeTurtle.startY}" }, timeInt

(exports ? this).turtle =
  run: (code, canvas, shadow) ->
    @shadow = shadow
    turtle.paper.remove()  if turtle.paper

    paper = Raphael(canvas, 380, 480)
    turtle.paper = paper
    paper.rect(0, 0, 380, 480).attr fill: "#fff"

    activeTurtle = new Turtle()
    eval code
    activeTurtle.runActions()
