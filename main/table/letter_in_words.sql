create table letter_in_words (
   letter       varchar2(1 char) not null constraint letter_in_words_letters_fk references letters,
   word         varchar2(5 char) not null constraint letter_in_words_words_fk references words,
   occurrences  integer          not null,
   constraint letter_in_words_pk primary key (word, letter),
   constraint letter_in_words_uk unique (letter, word)
);
