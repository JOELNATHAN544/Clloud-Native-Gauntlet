use axum::{http::StatusCode, Json};
use uuid::Uuid;

use crate::{auth, models::{LoginRequest, LoginResponse, User}};

pub async fn login(
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    // Mock authentication for Day 5 (Keycloak integration in Day 8)
    if payload.username == "admin" && payload.password == "password" {
        let user = User {
            id: Uuid::new_v4(),
            username: payload.username,
            email: "admin@example.com".to_string(),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        
        let token = auth::create_token(user.id.to_string(), "your-secret-key")
            .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
        
        Ok(Json(LoginResponse { token, user }))
    } else {
        Err(StatusCode::UNAUTHORIZED)
    }
}
