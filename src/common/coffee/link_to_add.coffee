# The contents of this file are subject to the Common Public Attribution
# License Version 1.0 (the “License”); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://1clickBOM.com/LICENSE. The License is based on the Mozilla Public
# License Version 1.1 but Sections 14 and 15 have been added to cover use of
# software over a computer network and provide for limited attribution for the
# Original Developer. In addition, Exhibit A has been modified to be consistent
# with Exhibit B.
#
# Software distributed under the License is distributed on an
# "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
# the License for the specific language governing rights and limitations under
# the License.
#
# The Original Code is 1clickBOM.
#
# The Original Developer is the Initial Developer. The Original Developer of
# the Original Code is Kaspar Emanuel.
{browser} = require './browser'
{messenger} = require('./messenger')
extend = exports.extend = (object, properties) ->
  for key, val of properties
    object[key] = val
  object

#Halp? ordering? missing? op-amps? I bet 'resistor networks' are rarely bought on octopart
categories_descriptions = {
'D' : 'D: diodes (including LEDs)',
'BT' : 'BT: battery',
'R' : 'R: resistor',
'C' : 'C: general capacitor',
'SW' : 'SW: switch',
'P' : 'P: multi-pin connector',
'J' : 'J: simple connector (video/audio/etc.)',
'Q' : 'Q: transistor',
'Y' : 'Y: crystal',
'T' : 'T: transformer',
'OTHER' : 'OTHER: catch-all for special part',
'RN' : 'RN: resistor network',
'XC' : 'XC: decoupling capacitor',
'L' : 'L: inductors and ferrite',
'FB': 'FB: ferrite bead',
'U' : 'U: ICs',
'RG' : 'RG: power regulators (like LDOs)',
'FC' : 'FC: fiducial',
}
#'TP' : 'TP: test points',
#'H' : 'H: holes/vias (sometimes it makes sense to include specific components on the schematic to designate corresponding holes on the layout, like in DDR routing)',


offers = document.querySelectorAll(".col-sku a")
#offers += document.querySelectorAll('.offertable-links-skucol') #This is from an item page, rather than search result.

selectinputs = []

updateSelects = (inputs)->
  for selectinput in inputs
    selectinput.onchange (e) ->
      console.log("got her")
      console.log(e.value)

for offer in offers
  span = document.createElement('span')
  span.style.textAlign = 'right'
  select = document.createElement('select')
  offer_id = offer.innerText || offer.textContent
  select.id = offer_id
  select.name = offer_id
  selectinputs.push(select)

  #if selected?(offer)
  #options = {'' : '-- Remove --'}
  options = {'' : '-- To add: Choose a reference category --'}
  options = extend(options, categories_descriptions)

  label = document.createElement('label')
  label.htmlFor = offer.innerHTML
  label.innerHTML = "<img src='"+chrome.extension.getURL('images/logo38.png')+"' alt='1clickBOM' />"
  span.appendChild(label)

  for value, description of options
    option = document.createElement("option")
    #TODO: populate if this part has an actuall ref, rather than a category. If a ref were supplied (e.g., LED5 rather than LED) 
    option.value = value
    option.text = description
    select.appendChild(option)
  span.appendChild(select)

  span.innerHTML = '('+span.innerHTML+')'
  offer.parentNode.appendChild(span)

  #TODO: add ajax spinner. library?
  select.onchange = (e) ->
    setTimeout(() -> 
      debugger
      updateSelects(selectinputs)
      name = e.target.name
      if e.value == ''
        messenger.send('removeByRef', e.value)
      else
        messenger.send('setRefForPartNumber', name, e.value)
    , 1000
    )
