create or replace package test_initial_load is
   --%suite

   --%test(load all tables when empty) 
   procedure load;

   --%test(delete data in all tables)
   procedure cleanup;

   --%test(delete and load all tables)
   procedure reload;
end test_initial_load;
/
