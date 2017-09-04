// vim: set ft=javascript:
#include "../_includes/config.jsxinc"; // diverse konfigurasjonsverdier
#include "../_includes/dokTools.jsxinc"; // diverse nyttige verktøyfunksjoner
#include "../_includes/prodsys.jsxinc"; // kommunikasjon med prodsys
#include "../_includes/json2.jsxinc"; // json library

main();

function main() {
  config.DEBUG=true;
  try {
    test_prodsys_list();
    // test_http_methods();
  } catch (e) {
    log(e);
  }
}

function assert(bool, msg) {
  if (! bool) 
    throw new Error('ASSERTION ERROR: ' + (msg || 'no message'));
}

function test_prodsys_list() {
  var status = config.api.STATUS;
  var response = prodsys.list({status: status.fromDesk})
  assert(response.status === 200, 'OK')
  log('results: ' +response.json.results.length + '\n');

  response = prodsys.list({status: [status.toDesk, status.atDesk]})
  assert(response.status === 200, 'OK')
  log('results: ' +response.json.results.length + '\n');
}

function test_get_all_stories() {
  var data = prodsys.get();
  var results = data.json && data.json.results || [];
  for (var i = 0; i < results.length; i++) 
    log(results[i]);
}

function test_http_methods() {
  var data = {
    mappe: 'anmeldelser',
    arbeidstittel: 'ny sak',
    produsert: 3,
    tekst: '@tit: ny sak!\n@bl: Test testesn',
  };
  var response;
  // http.dummy = true;
  response = prodsys.post(data);
  assert(response.status === 201, 'expected http status 201 CREATED, got ' + response.status);
  var pk = response.json.prodsak_id;
  response = prodsys.delete(pk);
  assert(response.status === 201, 'expected http status 204 DELETED, got ' + response.status);
  response = prodsys.get(pk);
  assert(response.status === 404, 'expected http status 404 NOT FOUND, got ' + response.status);
}