create table letters (
    letter       varchar2(1 char) not null constraint letters_pk primary key,
    occurrences  integer          not null,
    is_vowel     integer          generated always as (case when letter in ('a', 'e', 'i', 'o', 'u') then 1 else 0 end) virtual
);
