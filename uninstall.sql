set define off
set echo off
spool uninstall.log

prompt ================================================================================================================
prompt uninstall optional tests packages
prompt ================================================================================================================

drop package test_initial_load;
drop package test_wordle;
drop package test_guess_ot;
drop package test_game_ot;
drop package test_util;

prompt ================================================================================================================
prompt uninstall all other objects
prompt ================================================================================================================

drop package wordle;
drop package util;
drop package initial_load;
drop type game_ct force;
drop type game_ot force;
drop type guess_ct force;
drop type guess_ot force;
drop type text_ct force;
drop table letter_in_words purge;
drop table words purge;
drop table letters purge;
