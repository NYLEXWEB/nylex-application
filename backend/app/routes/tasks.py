from typing import List, Optional, Dict, Any
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.core.database import get_database
from app.core.security import get_current_active_user
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse
from app.utils.id_generator import generate_entity_id
from app.services.audit_service import log_audit_event
from app.services.notification_service import create_notification

router = APIRouter(prefix="/tasks", tags=["Tasks"])

@router.get("", response_model=List[TaskResponse])
async def list_tasks(
    project_id: Optional[str] = None,
    assigned_to: Optional[str] = None,
    status: Optional[str] = None,
    priority: Optional[str] = None,
    due_today: Optional[bool] = False,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    query: Dict[str, Any] = {}
    if project_id:
        query["projectId"] = project_id
    if assigned_to and assigned_to != "All":
        query["assignedTo"] = assigned_to
    if status and status != "All":
        query["status"] = status
    if priority and priority != "All":
        query["priority"] = priority
    if due_today:
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        query["dueDate"] = today_str

    tasks = await db.tasks.find(query).sort("dueDate", 1).to_list(200)
    return [TaskResponse(**t) for t in tasks]

@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_in: TaskCreate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    task_id = await generate_entity_id("TSK", "tasks")
    now = datetime.now(timezone.utc).isoformat()

    project = await db.projects.find_one({"id": task_in.projectId})
    if not project:
        raise HTTPException(status_code=400, detail="Referenced project not found.")

    assigned_name = None
    target_user_id = task_in.assignedTo or current_user["id"]
    u = await db.users.find_one({"id": target_user_id})
    if u:
        assigned_name = u.get("name")

    task_doc = task_in.model_dump()
    task_doc.update({
        "id": task_id,
        "projectName": project.get("projectName"),
        "assignedTo": target_user_id,
        "assignedToName": assigned_name,
        "createdBy": current_user["id"],
        "createdAt": now,
        "updatedAt": now,
    })

    await db.tasks.insert_one(task_doc)

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="CREATE_TASK",
        entity_type="TASK",
        entity_id=task_id,
        description=f"Created task '{task_in.title}' in project '{project.get('projectName')}'."
    )

    if target_user_id != current_user["id"]:
        await create_notification(
            user_id=target_user_id,
            title="Task Assigned",
            message=f"You have been assigned task '{task_in.title}' in {project.get('projectName')}.",
            notification_type="TASK_ASSIGNED",
            related_entity_type="TASK",
            related_entity_id=task_id,
        )

    return TaskResponse(**task_doc)

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    task = await db.tasks.find_one({"id": task_id})
    if not task:
        raise HTTPException(status_code=404, detail="Task not found.")
    return TaskResponse(**task)

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    update_data: TaskUpdate,
    current_user: dict = Depends(get_current_active_user)
):
    db = get_database()
    existing = await db.tasks.find_one({"id": task_id})
    if not existing:
        raise HTTPException(status_code=404, detail="Task not found.")

    update_fields = {k: v for k, v in update_data.model_dump().items() if v is not None}
    now = datetime.now(timezone.utc).isoformat()
    update_fields["updatedAt"] = now

    if "assignedTo" in update_fields and update_fields["assignedTo"]:
        u = await db.users.find_one({"id": update_fields["assignedTo"]})
        update_fields["assignedToName"] = u.get("name") if u else None

    res = await db.tasks.find_one_and_update(
        {"id": task_id},
        {"$set": update_fields},
        return_document=True
    )

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="UPDATE_TASK",
        entity_type="TASK",
        entity_id=task_id,
        description=f"Updated task '{res.get('title')}' status to {res.get('status')}."
    )

    return TaskResponse(**res)

@router.put("/{task_id}/complete")
async def complete_task(task_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    now = datetime.now(timezone.utc).isoformat()
    res = await db.tasks.find_one_and_update(
        {"id": task_id},
        {"$set": {"status": "Completed", "updatedAt": now}},
        return_document=True
    )
    if not res:
        raise HTTPException(status_code=404, detail="Task not found.")

    await log_audit_event(
        user_id=current_user["id"],
        user_name=current_user["name"],
        action="COMPLETE_TASK",
        entity_type="TASK",
        entity_id=task_id,
        description=f"Completed task '{res.get('title')}'."
    )
    return {"message": "Task marked as completed."}

@router.put("/{task_id}/reopen")
async def reopen_task(task_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    now = datetime.now(timezone.utc).isoformat()
    res = await db.tasks.find_one_and_update(
        {"id": task_id},
        {"$set": {"status": "In Progress", "updatedAt": now}},
        return_document=True
    )
    if not res:
        raise HTTPException(status_code=404, detail="Task not found.")
    return {"message": "Task reopened."}

@router.delete("/{task_id}")
async def delete_task(task_id: str, current_user: dict = Depends(get_current_active_user)):
    db = get_database()
    await db.tasks.delete_one({"id": task_id})
    return {"message": "Task deleted."}
