
-- Select all tasks on production in the service
select * from [reporting].[task] t
--where t.task_type in ('EBI_EVENT', 'EBI_VALIDATION') -- filter by Query (Event) and Compare Query (Validation)

-- select all executions on production
select * from reporting.execution

-- all users
select * from reporting.[user] 
