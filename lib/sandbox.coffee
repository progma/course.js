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


$ ->
  errorDiv = $ "<div>", class: "errorOutput"
  errorDiv.appendTo $ "body"

  myCodeMirror = CodeMirror.fromTextArea $('#editorArea').get(0),
            lineNumbers: true

  # Eval nemerime pri eventech, ale sbirame pri kliknuti tlacitka 'Eval!'.
  $('#evalButton').click ->
    currentCode = myCodeMirror.getValue()

    errorDiv.html ""
    output = document.getElementById "turtleSpace"
    turtle.settings.defaultTotalTime = 2000
    result = turtle.run currentCode, output, true

    unless result == true
      console.log @lastResult.errObj
      errorDiv.html @lastResult.reason

    console.log "turtle.lastDegreeSequence: #{turtle.lastDegreeSequence}"
