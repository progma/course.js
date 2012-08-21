
# Plays sound and, moreover, plugs saved events to the proper place.
playSound = (slide, mediaRoot, fullName) ->
  unless slide.soundObject?
    createSoundManager slide, mediaRoot, fullName

  slide.soundObject.play()

createSoundManager = (slide, mediaRoot, fullName) ->
  slide.soundObject = soundManager.createSound
    id : slide.sound
    url: mediaRoot + "/" + slide.sound

  $.getJSON mediaRoot + "/" + slide.talk, (recordingTracks) ->
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
      addEventsToManager slide, t, recordingTracks[t], fullName

addEventsToManager = (slide, name, track, fullName) ->
  $.map track, (event) =>
    slide.soundObject.onPosition event.time, ->
      playbook.playbook[name] event.value,
        codeMirror: slide.cm
        turtleDiv: document.getElementById("#{fullName}#{slide.drawTo}")


# Only visible slides should be able to play sounds.
stopSound = (slide) ->
  # slide.soundObject.destruct()
  slide.soundObject.stop()


(exports ? this).sound =
  playSound: playSound
  stopSound: stopSound
