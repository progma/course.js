$(document).ready(->
  soundManager.setup url: "lib/soundManagerSwf"
  $("div[slidedata]").each (i, div) ->
    lectures.createLecture $(div)
  window.lectures = lectures    # nice to have in debugging process
)

class Lecture
  constructor: (@name, @data, @div) ->
    @fullName = (@div.attr "id") + @name.replace "/", ""
    
  # Loads content to one slide.  
  loadSlide: (slide) ->
    slide.div.html ""
    if slide.type == "html" and slide.source?
      $.ajax(
        url: @name + "/" + slide.source
        dataType: "text"
      ).done (data) =>
        slide.div.html data
        @continueLoad slide
      .error =>
        slide.div.html "<center>There was an unusual accident during the load.</center>"
        
    # TODO :  move this particular type of slide out of the general library
    else if slide.type == "turtleDen"
      turtle.run "", document.getElementById(@fullName + slide.name)
  
    else if slide.type == "code"
      textDiv = $("<div>");
      textDiv.appendTo slide.div;
      if slide.text?
        $.ajax(
          url: @name + "/" + slide.text
          dataType: "text"
        ).done (data) =>
          textDiv.html data
          textDiv.height "80px"
    
      cm = new CodeMirror(slide.div.get(0),
        lineNumbers: true
      )
      if slide.code
        $.ajax(
          url: @name + "/" + slide.code
          dataType: "text"
        ).done (data) => cm.setValue(data)
      
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
      
      @continueLoad slide
      
    else if slide.type == "test"
      slide.div.html("Testing happens here.")
  
  continueLoad: (slide) ->
    if slide.sound?
      @playSound slide, slide.sound, slide.talk
  
  # Plays sound and, moreover, plugs saved events to the proper place.
  playSound: (slide, soundName, talkName) ->
    slide.soundObject = soundManager.createSound
      id: soundName
      url: @data.mediaRoot + "/" + soundName
      
    $.getJSON @data.mediaRoot + "/" + talkName, (recordingTracks) ->
      $.each recordingTracks, (name, track) ->
        $.map track, (event) ->
          slide.soundObject.onPosition event.time, ->
            playbook[name] event.value,
              codeMirror: slide.cm
              turtleDiv: document.getElementById('#{@fullName}#{slide.drawTo}')
  
      slide.soundObject.play()
  
  # Only visible slides should be able to play sounds.
  stopSound: (slide) ->
    soundManager.destruct()


  # Following three functions moves slides' DIVs to proper places. 
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide = @currentSlides = slideName = @data.slides[0].name

    slide = @findSlide(slideName)
    slide.iconDiv.addClass "slideIconActive"
    slide.div.css "margin-left", (if isThereSecond then ((if order == 0 then "-440px" else "1px")) else "-210px")
    slide.div.css "display", "block"
    if toRight
      slide.div.css "left", "150%"
      slide.div.animate { left: "-=100%" }, 1000
    else
      slide.div.css "left", "-50%"
      slide.div.animate { left: "+=100%" }, 1000
    @loadSlide slide
  
  hideSlide: (slideName, toLeft) ->
    slide = @findSlide(slideName)
    slide.soundObject.stop()  if slide.soundObject
    slide.div.animate { left: if toLeft then "-=100%" else "+=100%" }, 1000, -> slide.div.css "display", "none"
    slide.iconDiv.removeClass "slideIconActive"
  
  moveSlide: (slideName, lastOrder, toLeft) ->
    slide = @findSlide slideName
    slide.div.animate { "margin-left": if toLeft then "-=440px" else "+=440px" }, 1000
  
  
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
        @moveSlide slideName, i, true
      else
        @hideSlide slideName, true
  
    $.each slide.next.split(" "), (i, slideName) =>
      @showSlide slideName, i, slide.next.indexOf(" ") >= 0, true  if slideName != _.last @currentSlides.split " "
      @currentSlide = slideName
  
    @currentSlides = slide.next
    @showArrows (if slide.next.indexOf(" ") >= 0 then 2 else 1)
  
  back: ->
    if @historyStack.length == 0
      alert "Toto je začátek kurzu."
      return
      
    nextSlides = @historyStack.pop()
    beforeSlides = @currentSlides
    $.each @currentSlides.split(" "), (i, slideName) =>
      if nextSlides.indexOf(" ") >= 0 and @currentSlides.indexOf(" ") >= 0 and slideName == nextSlides.split(" ")[1]
        @moveSlide slideName, i, false
      else
        @hideSlide slideName, false
  
    @currentSlides = nextSlides
    $.each @currentSlides.split(" "), (i, slideName) =>
      @showSlide slideName, i, @currentSlides.indexOf(" ") >= 0    if slideName != beforeSlides.split(" ")[0]
      @currentSlide = slideName
  
    @showArrows (if @currentSlides.indexOf(" ") >= 0 then 2 else 1)
  
  
  # Arrows!
  hideArrows: (slidesNo) ->
    $("#" + @fullName + "backArrow").fadeOut 200
    $("#" + @fullName + "forwardArrow").fadeOut 200
  
  showArrows: (slidesNo) ->
    if slidesNo == 2
      $("#" + @fullName + "backArrow").css "margin-left", "-490px"
      $("#" + @fullName + "forwardArrow").css "margin-left", "430px"
    else if slidesNo == 1
      $("#" + @fullName + "backArrow").css "margin-left", "-260px"
      $("#" + @fullName + "forwardArrow").css "margin-left", "220px"
    $("#" + @fullName + "backArrow").fadeIn 200
    $("#" + @fullName + "forwardArrow").fadeIn 200
  
  
  # Finds the slide with a given name. 
  findSlide: (slideName) ->
    i = 0
  
    while i < @data.slides.length
      return @data.slides[i]  if @data.slides[i].name == slideName
      i++

# We use abbreviations in the course description file: one object for two or more slides.
# This is where we translate them to basic slides. 
TurtleSlidesHelper =
  turtleTalk: (slide) ->
    [
      name: slide.name + "TextPad"
      type: "code"
      talk: slide.talk
      sound: slide.sound
      run: "turtle.run"
      drawTo: slide.name + "TurtleDen"
    ,
      name: slide.name + "TurtleDen"
      type: "html"
      source: "screen.html"
      go: slide.go
    ]
  
  turtleTask: (slide) -> 
    [
      name: slide.name + "TextPad"
      type: "code"
      text: slide.text
      code: slide.code
      drawTo: slide.name + "TurtleDen"
    ,
      name: slide.name + "TurtleDen"
      type: "turtleDen"
      go: "move"
    ,
      name: slide.name + "Test"
      type: "test"
      code: slide.name + "TextPad"
      expected: slide.expected
      go: slide.go
    ]
      

# In this object we keep the list of all lectures on a page and, moreover,
# this is where we create them.
lectures =
  ls: new Array() # list of lectures on the page
  createLecture: (theDiv) ->
    slideList = $("<div>", { class: "slideList" })
    innerSlides = $("<div>", { class: "innerSlides" })
    name = theDiv.attr("slidedata")
    $.getJSON(name + "/desc.json", (data) =>
      data.slides = _.reduce data.slides, (memo, slide)->
        if TurtleSlidesHelper[slide.type]?
          memo = memo.concat TurtleSlidesHelper[slide.type](slide)
        else
          memo.push slide
        return memo
      , []
      
      newLecture = new Lecture name, data, theDiv
      $.each newLecture.data["load"], (key, val) -> $.getScript name + "/" + val

      $("<div>",
        id: newLecture.fullName + "backArrow"
        class: "arrow-w"
        click: -> newLecture.back()
        mouseover: -> $(this).animate { opacity: "+=0.4" }, 500
        mouseout: -> $(this).animate { opacity: "-=0.4" }, 500
      ).appendTo innerSlides
      $.each newLecture.data["slides"], (i, slide) ->
        slideIcon = $("<div>",
          id: "iconOf" + newLecture.fullName + slide.name
          class: "slideIcon"
          style: (if slide.icon then "background-image: url('" + name + "/" + slide.icon + "')" else "background-image: url('icons/" + slide.type + ".png')")
        ).appendTo(slideList)
        slideDiv = $("<div>",
          id: newLecture.fullName + slide.name
          class: "slide"
          style: "display: none"
        )
        slide["div"] = slideDiv
        slide["iconDiv"] = slideIcon
        slideDiv.appendTo innerSlides

      $("<div>",
        id: newLecture.fullName + "forwardArrow"
        class: "arrow-e"
        click: -> newLecture.forward()
        mouseover: -> $(this).animate { opacity: "+=0.4" }, 500
        mouseout: -> $(this).animate { opacity: "-=0.4" }, 500
      ).appendTo innerSlides
      slideList.appendTo theDiv
      innerSlides.appendTo theDiv
      @ls.push newLecture
      newLecture.showSlide `undefined`, 0, false, true
    ).error ->
      slideList.html "<p style='position: relative; top: 0.5em'>Course at '" + name + "' == not available."
      slideList.appendTo theDiv