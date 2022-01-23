set define off
set echo off
spool uninstall.log

prompt ================================================================================================================
prompt uninstall optional tests packages
prompt ================================================================================================================

drop package test_initial_load;
drop package test_wordle;

prompt ================================================================================================================
prompt uninstall all other objects
prompt ================================================================================================================

drop view full_autoplay_results;
drop package wordle;
drop package initial_load;
drop type word_ct;
drop table char_in_words purge;
drop table words purge;
drop table chars purge;
