create or replace package initial_load is
   procedure load;
   procedure cleanup;
   procedure reload;
end initial_load;
/
