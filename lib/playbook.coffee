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



# How to play back the values of individual properties.
playbook =
  bufferContents: (value, targets) ->
    targets.codeMirror.setValue value

  cursorPosition: (value, targets) ->
    targets.codeMirror.setCursor value

  selectionRange: (value, targets) ->
    targets.codeMirror.setSelection value.from, value.to

  scrollPosition: (value, targets) ->
    destination = targets.codeMirror.getScrollInfo()
    targets.codeMirror.scrollTo value.x / value.width * destination.width,
                                value.y / value.height * destination.height

  evaluatedCode: (value, targets) ->
    turtle.run value, targets.turtleDiv

(exports ? this).playbook =
  playbook: playbook
