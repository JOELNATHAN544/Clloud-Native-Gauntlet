use axum::{http::StatusCode, Json};
use uuid::Uuid;

use crate::models::{CreateTaskRequest, Task};

// Mock data for now - will be replaced with database queries
pub async fn list_tasks() -> Json<Vec<Task>> {
    let mock_tasks = vec![
        Task {
            id: Uuid::new_v4(),
            title: "Complete Cloud-Native Gauntlet".to_string(),
            description: Some("Finish the 12-day challenge".to_string()),
            completed: false,
            user_id: Uuid::new_v4(),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        },
        Task {
            id: Uuid::new_v4(),
            title: "Deploy to K3s".to_string(),
            description: Some("Get the cluster running".to_string()),
            completed: true,
            user_id: Uuid::new_v4(),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        },
    ];

    Json(mock_tasks)
}

pub async fn create_task(Json(payload): Json<CreateTaskRequest>) -> Result<Json<Task>, StatusCode> {
    let task = Task {
        id: Uuid::new_v4(),
        title: payload.title,
        description: payload.description,
        completed: false,
        user_id: Uuid::new_v4(), // Mock user ID
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
    };

    Ok(Json(task))
}
