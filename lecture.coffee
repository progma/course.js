
loadText = (name, callback, errorHandler = null) ->
    $.ajax(
      url: name
      dataType: "text"
    ).done(callback)
     .error(errorHandler)


class Lecture
  constructor: (@name, @data, @div) ->
    @fullName = (@div.attr "id") + @name.replace "/", ""

    # This is where we keep notion about what to do if a user hit the back
    # arrow.
    @historyStack = new Array()

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
      sound.playSound slide, @data.mediaRoot, @fullName

  # Following three functions moves slides' DIVs to proper places.
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide  = slideName = @data.slides[0].name
      @currentSlides = [@currentSlide]

    slide = @findSlide slideName
    pageDesign.showSlide slide, order, isThereSecond, toRight
    @loadSlide slide

  hideSlide: (slideName, toLeft) ->
    slide = @findSlide slideName
    sound.stopSound slide if slide.soundObject
    pageDesign.hideSlide slide, toLeft

  moveSlide: (slideName, toLeft) ->
    slide = @findSlide slideName
    pageDesign.moveSlide slide, toLeft

  # Following two functions handle the first response to a user's click.
  forward: ->
    slide = @findSlide @currentSlide
    slideI = _.indexOf @data.slides, slide

    switch slide.go
      when "nextOne"
        slide.next = [@data.slides[slideI+1].name]
      when "nextTwo"
        slide.next = [@data.slides[slideI+1].name, @data.slides[slideI+2].name]
      when "move"
        slide.next = [@currentSlide, @data.slides[slideI+1].name]
      else
        if !slide.next?
          alert "Toto je konec kurzu."
          return

    @historyStack.push @currentSlides

    $.each @currentSlides, (i, slideName) =>
      if slideName == slide.next[0]
        @moveSlide slideName, true
      else
        @hideSlide slideName, true

    $.each slide.next, (i, slideName) =>
      if slideName != _.last @currentSlides
        @showSlide slideName, i, slide.next.length > 1, true
      @currentSlide = slideName

    @currentSlides = slide.next
    @placeArrows()

  back: ->
    if @historyStack.length == 0
      alert "Toto je začátek kurzu."
      return

    nextSlides = @historyStack.pop()
    beforeSlides = @currentSlides

    $.each @currentSlides, (i, slideName) =>
      if  nextSlides.length     > 1     and
          @currentSlides.length > 1     and
          slideName == nextSlides[1]
        @moveSlide slideName, false
      else
        @hideSlide slideName, false

    @currentSlides = nextSlides
    $.each @currentSlides, (i, slideName) =>
      if slideName != beforeSlides[0]
        @showSlide slideName, i, @currentSlides.length > 1, false
      @currentSlide = slideName

    @placeArrows()

  # Set arrows to their possition according to number of slides
  placeArrows: ->
    pageDesign.showArrows (if @currentSlides.length > 0 then 2 else 1)
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
