poziceX = undefined
poziceY = undefined
uhel    = undefined

@go = (n) ->
  novaPoziceX = poziceX + n * Math.sin(uhel / 360 * Math.PI * 2)
  novaPoziceY = poziceY - n * Math.cos(uhel / 360 * Math.PI * 2)
  turtle.drawLine poziceX, poziceY, novaPoziceX, novaPoziceY
  poziceX = novaPoziceX
  poziceY = novaPoziceY

@right = (u) ->
  uhel = (uhel + u) % 360

@left = (u) ->
  right 360 - u

@repeat = (n, f) ->
  i = 0
  args = Array::slice.call arguments, 2

  while i < n
    f args...
    i++

(exports ? this).turtle =
  run: (code, canvas, shadow) ->
    @shadow = shadow

    poziceX = 0
    poziceY = 0
    uhel = 0

    turtle.paper.remove()  if turtle.paper

    paper = Raphael(canvas, 380, 480)
    turtle.paper = paper
    paper.rect(0, 0, 380, 480).attr fill: "#fff"
    eval code
    turtle.drawTurtle()

  drawLine: (fromX, fromY, toX, toY) ->
    turtle.paper.path("M#{fromX + 100} #{fromY + 100}L#{toX + 100} #{toY + 100}")
      .attr stroke: (if @shadow then "yellow" else "red")

  drawTurtle: ->
    im = turtle.paper.image "examples/zelva/zelva.png", poziceX + 90
                          , poziceY + 84, 20, 30
    im.rotate uhel
