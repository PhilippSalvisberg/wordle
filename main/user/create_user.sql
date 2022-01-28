-- example, create user as DBA user
-- the user must not be named wordle to avoid conflicts with PL/SQL naming resolution
-- during tests a PLS-00302 is thrown when the user is named wordle (same as package)
-- it looks like a restriction of anydata.convertcollection
create user wordle2 identified by wordle2;

-- privileges to install all objects and run tests
grant connect, resource, create view, unlimited tablespace to wordle2;

-- privileges to run the debugger
grant debug connect session, debug any procedure to wordle2;
grant execute on dbms_debug_jdwp to wordle2;
begin
    dbms_network_acl_admin.append_host_ace (
    host =>'*',
    ace  => sys.xs$ace_type(
                privilege_list => sys.xs$name_list('JDWP') ,
                principal_name => 'wordle2',
                principal_type => sys.xs_acl.ptype_db
            )
    );
end;
/
