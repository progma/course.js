step = 5
timeInt = 100

startX    = 0
startY    = 0
startUhel = 0

activeTurtle = null

RT = (a) ->
  type: "rotate"
  angle: a

MV = (len) ->
  type: "go"
  length: len

class Turtle
  actions: []

  constructor: (@x = 0, @y = 0, @angle = 0) ->
    @im = turtle.paper.image "examples/zelva/zelva.png"
                           , startX + 90
                           , startY + 84
                           , 20, 30
    @im.rotate startUhel

  addAction: (a) ->
    @actions.push a

  runActions: ->
    return if @actions.length == 0

    switch @actions[0].type
      when "go"
        len = @actions[0].length
        [oldX, oldY] = [@x, @y]
        [newX, newY] = computeCoords @x, @y, len, @angle
        [@x, @y] = [newX, newY]

        trans = "...t0,#{-len}"
        customAction = -> drawLine oldX, oldY, newX, newY

      when "rotate"
        a = @actions[0].angle
        @angle = (@angle + a) % 360
        trans = "...r#{a}"
        customAction = ->

    @actions.shift()
    @im.animate transform: trans
              , 100
              , "linear"
              , =>
                customAction()
                @runActions()


computeCoords = (x,y,len,angle) ->
  newX = x + len * Math.sin(angle / 360 * Math.PI * 2)
  newY = y - len * Math.cos(angle / 360 * Math.PI * 2)
  [newX,newY]

@go = (n) ->
  activeTurtle.addAction (MV n)

@right = (u) ->
  activeTurtle.addAction (RT u)

@left = (u) ->
  right 360 - u

@repeat = (n, f) ->
  i = 0
  args = Array::slice.call arguments, 2

  while i < n
    f args...
    i++

drawLine = (fromX, fromY, toX, toY) ->
  turtle.paper.path("M#{fromX + 100} #{fromY + 100}L#{toX + 100} #{toY + 100}")
    .attr stroke: (if @shadow then "yellow" else "red")


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
