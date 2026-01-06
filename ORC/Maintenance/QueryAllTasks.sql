
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
