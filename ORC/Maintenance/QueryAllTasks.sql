
-- Select all tasks on production in the service
select * from [reporting].[task] t
--where t.task_type in ('EBI_EVENT', 'EBI_VALIDATION') -- filter by Query (Event) and Compare Query (Validation)

-- select all executions on production
select * from reporting.execution

-- all users
select * from reporting.[user] 



-- all schedules
select st.object_group_id, st.name, st.enabled, st.schedule_description
from exmondg.q_schedule_trigger st
inner join exmondg.q_object_group og ON st.object_group_id = og.object_group_id and og.version_id = st.object_group_version_id



-- all tasks in an object group

select ogi.object_group_id, ogi.object_type, ogi.object_id, ctv_task.title
from exmondg.q_object_group_item ogi
left join exmondg.t_task_version ctv_obj ON ogi.object_group_id=ctv_obj.task_id and ctv_obj.task_type='EBI_OBJECT_GROUP' and ctv_obj.version_id=ogi.version_id and ctv_obj.uat='DEV'
left join exmondg.t_task_version ctv_task ON ogi.object_type=ctv_task.task_type and ogi.object_id=ctv_task.task_id and ctv_task.uat='DEV'
where ogi.object_type not in ('OBJ_GROUP_STEP')

-- Query to get all tasks with their queries, connections, owners, and system names
select tv.task_id, tv.task_type, tv.title, s.system_name,  tv.*,
    queries.ds1_query, queries.ds2_query, 
    c1.connection_name as ds1_connection_name, c1.host_type as ds1_host_type, 
    c2.connection_name as ds2_connection_name, c2.host_type as ds2_host_type,
    queries.saved_date, u.email as owner_email, queries.exception_email_cc,
    e.start_date, e.success_ind, e.row_count, e.duration_seconds
from exmondg.t_task_version tv
left join (
    select event_id as task_id, 'EBI_EVENT' as task_type, e.version_id, e.saved_date, e.owner_user_id, e.exception_email_cc, e.sql_command as ds1_query, e.connection_guid as ds1_connection, null as ds2_query, null as ds2_connection
    from exmondg.p_event e
    union all

    select v.validation_id as task_id, 'EBI_VALIDATION' as task_type, v.version_id, v.saved_date, v.owner_user_id, v.exception_email_cc, ds1.query as ds1_query, ds1.connection_guid as ds1_connection, ds2.query as ds2_query, ds2.connection_guid as ds2_connection
    from exmondg.q_validation v
    left join exmondg.q_validation_dataset ds1 ON v.validation_id = ds1.validation_id and v.version_id = ds1.validation_version_id and ds1.dataset_id=1
    left join exmondg.q_validation_dataset ds2 ON v.validation_id = ds2.validation_id and v.version_id = ds2.validation_version_id and ds2.dataset_id=2 

) queries ON tv.task_id = queries.task_id and tv.task_type = queries.task_type and tv.version_id = queries.version_id
left join exmondg.a_system s ON tv.system_id = s.system_id
left join (select max(connection_name) as connection_name, connection_guid, max(host_type) as host_type from exmondg.c_connection group by connection_guid) c1 ON queries.ds1_connection = c1.connection_guid
left join (select max(connection_name) as connection_name, connection_guid, max(host_type) as host_type from exmondg.c_connection group by connection_guid) c2 ON queries.ds2_connection = c2.connection_guid
left join exmondg.c_user u ON queries.owner_user_id = u.user_id
left join (
    select task_id, task_type, max(exec_id) as max_exec_id
    from reporting.execution
    group by task_id, task_type
) latest_exec ON latest_exec.task_id = tv.task_id and latest_exec.task_type = tv.task_type
left join reporting.execution e ON e.exec_id = latest_exec.max_exec_id
where tv.task_type in ('EBI_EVENT','EBI_VALIDATION')

