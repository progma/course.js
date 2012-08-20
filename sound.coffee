
# Plays sound and, moreover, plugs saved events to the proper place.
playSound = (slide, soundName, talkName, mediaRoot) ->
  slide.soundObject = soundManager.createSound
    id: soundName
    url: mediaRoot + "/" + soundName

  addEventsToManager = (name, track) ->
    $.map track, (event) =>
      slide.soundObject.onPosition event.time, =>
        playbook.playbook[name] event.value,
          codeMirror: slide.cm
          turtleDiv: document.getElementById("#{@fullName}#{slide.drawTo}")

  $.getJSON mediaRoot + "/" + talkName, (recordingTracks) =>
    # Dirty hack.
    # Order matters!
    tracks = [
      "evaluatedCode"
      "scrollPosition"
      "selectionRange"
      "scrollPosition"
      "bufferContents"
    ]
    for t in tracks
      addEventsToManager t, recordingTracks[t]

  slide.soundObject.play()


# Only visible slides should be able to play sounds.
stopSound = (slide) ->
  # slide.soundObject.destruct()
  slide.soundObject.stop()


(exports ? this).sound =
  playSound: playSound
  stopSound: stopSound
