/* jshint ignore:start */
#includepath "../_includes/"
#include "importpanel.jsxinc";
#include "prodsys.jsxinc";
/* jshint ignore:end */

function onImportClick(aktivSak, artikkeltype, importImages) {
  log(aktivSak);
}

config.DEBUG = true;
importPanel(onImportClick);
//~ for (var n = 10; n < 200 ; n += 80) {
//~   response = prodsys.get(null, {limit: n});
//~   log(response.status);
//~   log(response.error ? response.error.message : response.json.results.length);
//~   log(response.body.length);
//~ }
