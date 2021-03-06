/* jshint ignore:start */
#target "indesign"
#targetengine "session"
#include ../_includes/index.jsxinc
/* jshint ignore:end */

var strekStil = config.objektstiler.spaltestrek

mekkStreker = function(minTekstramme) {
  var spalter = minTekstramme.textFramePreferences.textColumnCount
  var spaltemellomrom = minTekstramme.textFramePreferences.textColumnGutter
  var bounds = minTekstramme.geometricBounds
  inset = minTekstramme.textFramePreferences.insetSpacing
  if (typeof inset == 'number') {
    inset = [inset, inset, inset, inset]
  }
  bounds = [
    bounds[0] + inset[0],
    bounds[1] + inset[1],
    bounds[2] - inset[2],
    bounds[3] - inset[3]
  ]
  var bredde = bounds[3] - bounds[1]
  var spaltebredde = (bredde - (spalter - 1) * spaltemellomrom) / spalter
  var streker = app.activeDocument.graphicLines.everyItem().getElements() || []
  var myLabel = 'textFrameid: ' + minTekstramme.id
  for (var i = 0; i < streker.length; i++) {
    if (streker[i].label == myLabel) {
      streker[i].remove()
    }
  }

  for (i = 0; i < spalter + 1; i++) {
    var x =
      bounds[1] + i * (spaltebredde + spaltemellomrom) - spaltemellomrom / 2
    var minStrek = minTekstramme.parent.graphicLines.add(
      undefined,
      undefined,
      undefined,
      {
        appliedObjectStyle: strekStil
      }
    )
    minStrek.label = myLabel
    minStrek.paths[0].pathPoints[0].anchor = [x, bounds[0]]
    minStrek.paths[0].pathPoints[1].anchor = [x, bounds[2]]
  }
}

if (app.selection.length === 0) {
  alert('Spaltestreker\rVelg en eller flere tekstrammer')
} else {
  strekStil = dokTools.velgStil(app.activeDocument, 'object', strekStil)
  for (var i = 0; i < app.selection.length; i++) {
    var myObject = app.selection[i]
    if (myObject instanceof TextFrame) {
      mekkStreker(myObject)
    }
  }
}
