$(document).ready(->
  soundManager.setup url: "lib/soundManagerSwf"
  $("div[slidedata]").each (i, div) ->
    lectures.createLecture $(div)
)

class Lecture
  constructor: (@name, @data, @div) ->
    @fullName = @div.attr "id" + @name.replace "/", ""
    
  showSlide: (slideName, order, isThereSecond, toRight) ->
    if (!slideName)
      @currentSlide = @currentSlides = slideName = @data.slides[0].name

    slide = @getSlide(slideName)
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
  
    else if slide.type == "code"
      cm = new CodeMirror(slide.div.get(0),
        lineNumbers: true
      )
      cm.setSize 380, 200
      slide.cm = cm
      $("<button>",
        text: "Run"
        class: "btn"
        click: =>
          eval("#{slide.run}(cm.getValue(), document.getElementById('#{@fullName}#{slide.drawTo}'))")
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
  
  stopSound: (slide) ->
    soundManager.destruct()
  
  hideSlide: (slideName, toLeft) ->
    slide = @getSlide(slideName)
    slide.soundObject.stop()  if slide.soundObject
    if toLeft
      slide.div.animate { left: "-=100%" }, 1000, -> slide.div.css "display", "none"
    else
      slide.div.animate { left: "+=100%" }, 1000, -> slide.div.css "display", "none"
  
    slide.iconDiv.removeClass "slideIconActive"
  
  moveSlide: (slideName, lastOrder, toLeft) ->
    slide = @getSlide(slideName)
    slide.div.animate { "margin-left": "-=440px" }, 1000
  
  historyStack: new Array()
  
  forward: ->
    slide = @getSlide(@currentSlide)
    slideI = _.indexOf(@data.slides, slide)
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
      @showSlide slideName, i, slide.next.indexOf(" ") >= 0, true  if slideName != @currentSlides.split(" ")[@currentSlides.split(" ").length - 1]
      @currentSlide = slideName
  
    @currentSlides = slide.next
    @showArrows (if slide.next.indexOf(" ") >= 0 then 2 else 1)
  
  back: ->
    if @historyStack.length == 0
      alert "Toto je začátek kurzu."
      return
    $.each @currentSlides.split(" "), (key, slideName) =>
      @hideSlide slideName, false
  
    @currentSlides = @historyStack.pop()
    $.each @currentSlides.split(" "), (key, val) =>
      @showSlide val, false
      @currentSlide = val
  
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
  
  getSlide: (slideName) ->
    i = 0
  
    while i < @data.slides.length
      return @data.slides[i]  if @data.slides[i].name == slideName
      i++

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
      source: slide.text
    ,
      name: slide.name + "TurtleDen"
      type: html
      go: "move"
    ,
      name: slide.name + "Test"
      type: "test"
      code: slide.name + "TextPad"
      expected: slide.expected
      go: slide.go
    ]
      

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
      window.data = data
      
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