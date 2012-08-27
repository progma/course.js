# course.js library
# Copyright 2012 Tomas Jakl, Lukas Lansky, David Marek, Jiri Marsik
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



slide      = undefined
jsonTracks = undefined
codeMirror = undefined
turtleDiv  = undefined

# Order matters!
tracks = [
  "evaluatedCode"
  "scrollPosition"
  "selectionRange"
  "scrollPosition"
  "bufferContents"
]

# Plays sound and, moreover, plugs saved events to the proper place.
playSound = (sl, mediaRoot, fullName) ->
  slide = sl
  
  unless slide.soundObject?
    createSoundManager slide, mediaRoot, fullName

  slide.soundObject.play(
    whileplaying: updateSeekbar
  )
  pageDesign.addPlayer slide.div, pauseSound, seekSound

createSoundManager = (slide, mediaRoot, fullName) ->
  slide.soundObject = soundManager.createSound
    id : slide.sound
    url: mediaRoot + "/" + slide.sound

  $.getJSON mediaRoot + "/" + slide.talk, (recordingTracks) ->
    jsonTracks = recordingTracks
    for t in tracks
      addEventsToManager slide, t, recordingTracks[t], fullName

addEventsToManager = (slide, name, track, fullName) ->
  $.map track, (event) =>
    slide.soundObject.onPosition event.time, ->
      playbook.playbook[name] event.value,
        codeMirror: codeMirror=slide.cm
        turtleDiv: turtleDiv=document.getElementById("#{fullName}#{slide.drawTo}")


pauseSound = (e) ->
  if slide.soundObject.paused
    slide.soundObject.play()
  else
    slide.soundObject.pause()

seekSound  = (e) ->
  xcord = e.pageX - slide.div.offset().left  # 22-420
  pos   = (xcord - 22) / 400 * slide.soundObject.duration
  slide.soundObject.setPosition pos
  
  for track in tracks
    for event in jsonTracks[track]
      if event.time < slide.soundObject.position
        theEvent = event
    continue unless theEvent?
    
    playbook.playbook[track] theEvent.value,
      codeMirror: codeMirror
      turtleDiv: turtleDiv
  
updateSeekbar = ->
  perc = slide.soundObject.position * 100 / slide.soundObject.duration
  slide.div.find(".inseek").width(perc + "%")

# Only visible slides should be able to play sounds.
stopSound = (slide) ->
  # slide.soundObject.destruct()
  slide.soundObject.stop()


(exports ? this).sound =
  playSound: playSound
  stopSound: stopSound
