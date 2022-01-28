create or replace package test_initial_load is
   --%suite(initial_load)
   --%suitepath(install)

   --%test(load all tables when empty)
   --%tag(slow)
   procedure load;

   --%test(delete data in all tables)
   --%tag(slow)
   procedure cleanup;

   --%test(delete and load all tables)
   --%tag(slow)
   procedure reload;
end test_initial_load;
/
