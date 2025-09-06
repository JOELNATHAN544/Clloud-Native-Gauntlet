use axum::{http::StatusCode, Json};
use uuid::Uuid;

use crate::{auth, keycloak::KeycloakClient, models::{LoginRequest, LoginResponse, User}};

pub async fn login(
    Json(payload): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, StatusCode> {
    // Initialize Keycloak client
    let keycloak_client = KeycloakClient::new(
        "http://keycloak.local:8080".to_string(),
        "cloud-gauntlet".to_string(),
        "rust-api".to_string(),
        None, // No client secret for public client
    );

    // Try to authenticate with Keycloak
    match keycloak_client.get_token(&payload.username, &payload.password).await {
        Ok(token_response) => {
            // Get user info from Keycloak
            match keycloak_client.get_user_info(&token_response.access_token).await {
                Ok(user_info) => {
                    let user = User {
                        id: Uuid::parse_str(&user_info.sub).unwrap_or_else(|_| Uuid::new_v4()),
                        username: user_info.preferred_username,
                        email: user_info.email.unwrap_or_else(|| "no-email@example.com".to_string()),
                        created_at: chrono::Utc::now(),
                        updated_at: chrono::Utc::now(),
                    };
                    
                    Ok(Json(LoginResponse { 
                        token: token_response.access_token, 
                        user 
                    }))
                }
                Err(_) => {
                    // Fallback to mock user if userinfo fails
                    let user = User {
                        id: Uuid::new_v4(),
                        username: payload.username,
                        email: "user@example.com".to_string(),
                        created_at: chrono::Utc::now(),
                        updated_at: chrono::Utc::now(),
                    };
                    
                    Ok(Json(LoginResponse { 
                        token: token_response.access_token, 
                        user 
                    }))
                }
            }
        }
        Err(_) => {
            // Fallback to mock authentication for development
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
    }
}
