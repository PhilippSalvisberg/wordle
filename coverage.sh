time $HOME/github/utPLSQL/utPLSQL-cli/bin/utplsql run wh/wh@fillmore/odb.docker \
-source_path=main -owner=wh \
-p=':wordle' \
-test_path=test \
-f=ut_coverage_sonar_reporter     -o=coverage.xml \
-f=ut_coverage_html_reporter      -o=coverage.html \
-f=ut_sonar_test_reporter         -o=test_results.xml \
-f=ut_junit_reporter              -o=junit_test_results.xml \
-f=ut_documentation_reporter      -o=test_results.log -s
