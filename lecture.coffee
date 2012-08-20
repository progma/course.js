
loadText = (name, callback, errorHandler = null) ->
    $.ajax(
      url: name
      dataType: "text"
    ).done(callback)
     .error(errorHandler)


class Lecture
  constructor: (@name, @data, @div) ->
    @fullName = (@div.attr "id") + @name.replace "/", ""

  # Loads content to one slide.
  loadSlide: (slide) ->
    slide.div.html ""

    if slide.type == "html" and slide.source?
      loadText @name + "/" + slide.source
      , (data) =>
        slide.div.html data
        @loadSound slide
      , => slide.div.html pageDesign.loadProblem

    # TODO:  move this particular type of slide out of the general library
    else if slide.type == "turtleDen"
      loadText @name + "/" + slide.expected,(data) =>
        turtle.run data, document.getElementById(@fullName + slide.name), true

    else if slide.type == "code"
      textDiv = $("<div>")
      textDiv.appendTo slide.div

      if slide.text?
        loadText @name + "/" + slide.text, (data) =>
          textDiv.html data
          textDiv.height "80px"

      cm = new CodeMirror slide.div.get(0), lineNumbers: true

      if slide.code
        loadText @name + "/" + slide.code, (data) => cm.setValue data

      cm.setSize 380, 360
      slide.cm = cm

      $("<button>",
        text: "Run"
        class: "btn"
        click: =>
          # TODO :  this should be more universal
          turtle.run cm.getValue(), document.getElementById(@fullName + slide.drawTo)
          if !@data.userCode?
            @data.userCode = {}
          @data.userCode[slide.name] = slide.cm.getValue()
      ).appendTo slide.div

      @loadSound slide

    else if slide.type == "test"
      slide.div.html pageDesign.testResultPage

  loadSound: (slide) ->
    if slide.sound?
      sound.playSound slide, slide.sound, slide.talk, @data.mediaRoot

  # Following three functions moves slides' DIVs to proper places.
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide = @currentSlides = slideName = @data.slides[0].name

    slide = @findSlide(slideName)
    pageDesign.showSlide slide, order, isThereSecond, toRight
    @loadSlide slide

  hideSlide: (slideName, toLeft) ->
    slide = @findSlide(slideName)
    sound.stopSound slide if slide.soundObject
    pageDesign.hideSlide slide, toLeft

  moveSlide: (slideName, toLeft) ->
    slide = @findSlide slideName
    pageDesign.moveSlide slide, toLeft

  # This is where we keep notion about what to do if a user hit the back arrow.
  historyStack: new Array()

  # Following two functions handle the first response to a user's click.
  forward: ->
    slide = @findSlide @currentSlide
    slideI = _.indexOf @data.slides, slide

    if slide.go == "nextOne"
      slide.next = @data.slides[slideI+1].name
    else if slide.go == "nextTwo"
      slide.next = @data.slides[slideI+1].name + " " + @data.slides[slideI+2].name
    else if slide.go == "move"
      slide.next = @currentSlide + " " + @data.slides[slideI+1].name
    else if !slide.next?
      alert "Toto je konec kurzu."
      return

    @historyStack.push @currentSlides
    $.each @currentSlides.split(" "), (i, slideName) =>
      if slideName == slide.next.split(" ")[0]
        @moveSlide slideName, true
      else
        @hideSlide slideName, true

    $.each slide.next.split(" "), (i, slideName) =>
      @showSlide slideName
               , i
               , slide.next.indexOf(" ") >= 0
               , true  if slideName != _.last @currentSlides.split " "
      @currentSlide = slideName

    @currentSlides = slide.next
    pageDesign.showArrows (if slide.next.indexOf(" ") >= 0 then 2 else 1), @fullName

  back: ->
    if @historyStack.length == 0
      alert "Toto je začátek kurzu."
      return

    nextSlides = @historyStack.pop()
    beforeSlides = @currentSlides
    $.each @currentSlides.split(" "), (i, slideName) =>
      if  nextSlides.indexOf(" ")     >= 0     and
          @currentSlides.indexOf(" ") >= 0     and
          slideName == nextSlides.split(" ")[1]
        @moveSlide slideName, false
      else
        @hideSlide slideName, false

    @currentSlides = nextSlides
    $.each @currentSlides.split(" "), (i, slideName) =>
      @showSlide slideName, i, @currentSlides.indexOf(" ") >= 0    if slideName != beforeSlides.split(" ")[0]
      @currentSlide = slideName

    pageDesign.showArrows (if @currentSlides.indexOf(" ") >= 0 then 2 else 1)
                        , @fullName

  # Previews!
  showPreview: (slide) ->
    slide.iconDiv.offset().left

  hidePreview: (slide) ->


  # Finds the slide with a given name.
  findSlide: (slideName) ->
    i = 0

    while i < @data.slides.length
      return @data.slides[i]  if @data.slides[i].name == slideName
      i++

(exports ? this).lecture =
  Lecture: Lecture
