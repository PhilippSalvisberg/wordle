create or replace package test_initial_load is
   --%suite(initial_load)
   --%suitepath(install)

   --%test(load all tables when empty)
   --%tags(slow)
   procedure load;

   --%test(delete data in all tables)
   --%tags(slow)
   procedure cleanup;

   --%test(delete and load all tables)
   --%tags(slow)
   procedure reload;
end test_initial_load;
/
