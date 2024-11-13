drop table if exists subject_student;
create table if not exists subject_student
(
    subject_id
    bigint
    not
    null,
    student_id
    bigint
    not
    null,
    constraint
    pkey_subject_student
    primary
    key
(
    subject_id,
    student_id
)
    );

drop table if exists subject;
create table if not exists subject
(
    id
    bigserial,
    name
    text,
    constraint
    pkey_subject
    primary
    key
(
    id
)
    );

drop table if exists student;
create table if not exists student
(
    id
    bigserial,
    name
    text,
    constraint
    pkey_student
    primary
    key
(
    id
)
    );


drop table if exists exam;
create table if not exists exam
(
    id
    bigserial,
    subject_id
    bigint,
    name
    text,
    constraint
    pkey_exam
    primary
    key
(
    id
)
    );

drop table if exists question;
create table if not exists question
(
    id
    bigserial,
    exam_id
    bigint,
    question
    text,
    correct_answer
    text,
    constraint
    pkey_question
    primary
    key
(
    id
)
    );

drop table if exists exam_result;
create table if not exists exam_result
(
    id
    bigserial,
    student_id
    bigint,
    question_id
    bigint,
    is_correct
    boolean
    default
    true,
    constraint
    pkey_exam_result
    primary
    key
(
    id
)
    );

insert into subject_student (subject_id, student_id)
values (1, 1),
       (1, 2);
d

with exam_data as (select subject.id   as subject_id,
                          subject.name as subject_name,
                          exam.id      as exam_id,
                          exam.name    as exam_name,
                          jsonb_agg(
                                  jsonb_build_object(
                                          'id', question.id,
                                          'question', question.question,
                                          'is_correct', exam_result.is_correct
                                  )
                          )            as details
                   from exam
                            join subject on exam.subject_id = subject.id
                            join question on exam.id = question.exam_id
                            join exam_result on question.id = exam_result.question_id
                   group by subject.id, exam.id),
     exam_detail as (select exam_result.student_id,
                            student.name,
                            exam_data.exam_id,
                            exam_data.exam_name,
                            count(question.question)                           as total_question,
                            count(CasE WHEN exam_result.is_correct THEN 1 END) as total_correct,
                            exam_data.details
                     from exam_result
                              join student on exam_result.student_id = student.id
                              join question on question.id = exam_result.question_id
                              join exam_data on exam_data.exam_id = question.exam_id
                     group by exam_result.student_id, student.name, exam_data.exam_id, exam_data.exam_name,
                              exam_data.details),
     ex_result as (select exam_detail.student_id,
                          exam_detail.exam_id,
                          exam_detail.exam_name,
                          json_agg(
                                  json_build_object(
                                          'total_correct', exam_detail.total_correct,
                                          'total_question', exam_detail.total_question,
                                          'details', exam_detail.details
                                  )
                          ) as result
                   from exam_detail
                   group by exam_detail.student_id, exam_detail.exam_id, exam_detail.exam_name),
     exams as (select ex_result.student_id,
                      json_agg(
                              json_build_object(
                                      'id', ex_result.exam_id,
                                      'name', ex_result.exam_name,
                                      'result', ex_result.result
                              )
                      ) as exams
               from ex_result
               group by ex_result.student_id),
     student_exams_result as (select subject_student.subject_id,
                                     json_agg(
                                             json_build_object(
                                                     'id', subject_student.student_id,
                                                     'name', student.name,
                                                     'exams', exams.exams
                                             )
                                     ) as students
                              from subject_student
                                       join student on subject_student.student_id = student.id
                                       join exams on exams.student_id = subject_student.student_id
                              group by subject_student.subject_id),
     subject_result as (select subject.id as subject_id,
                               json_agg(
                                       json_build_object(
                                               'id', subject.id,
                                               'name', subject.name,
                                               'students', student_exams_result.students
                                       )
                               )          as subjects
                        from subject
                                 join student_exams_result on student_exams_result.subject_id = subject.id
                        group by subject.id)
select subject_result.subjects
from subject_result;





