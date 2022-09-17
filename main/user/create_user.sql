-- create user wh as DBA user (wh is an acronym for Wordle Helper)
-- the user must not be named wordle to avoid conflicts with PL/SQL naming resolution
-- during tests a PLS-00302 is thrown when the user is named wordle (same as package)
-- it looks like a restriction of anydata.convertcollection
create user wh identified by wh;

-- privileges to install all objects and run tests
grant connect, resource, unlimited tablespace to wh;

-- privileges to run the debugger
grant debug connect session, debug any procedure to wh;
grant execute on dbms_debug_jdwp to wh;
begin
   sys.dbms_network_acl_admin.append_host_ace(
      host => '*',
      ace  => sys.xs$ace_type(
                 privilege_list => sys.xs$name_list('JDWP'),
                 principal_name => 'wh',
                 principal_type => sys.xs_acl.ptype_db
              )
   );
end;
/
