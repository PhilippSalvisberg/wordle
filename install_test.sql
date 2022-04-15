set define off
set echo off
spool install_test.log

prompt ================================================================================================================
prompt install test packages
prompt ================================================================================================================

@test/package/test_game_ot.pks
@test/package/test_game_ot.pkb
@test/package/test_guess_ot.pks
@test/package/test_guess_ot.pkb
@test/package/test_initial_load.pks
@test/package/test_initial_load.pkb
@test/package/test_util.pks
@test/package/test_util.pkb
@test/package/test_wordle.pks
@test/package/test_wordle.pkb

prompt ================================================================================================================
prompt execute utPLSQL tests (suitepath wordle only to slow initial load tests)
prompt ================================================================================================================

set serveroutput on size unlimited
execute ut.run(':wordle');
