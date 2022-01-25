create table chars (
    character    varchar2(1 char) not null constraint chars_pk primary key,
    occurrences  integer          not null,
    is_vowel     integer          generated always as (case when character in ('a', 'e', 'i', 'o', 'u') then 1 else 0 end) virtual
);
