use axum::{
    extract::Request,
    http::{HeaderMap, StatusCode},
    middleware,
    response::Response,
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod auth;
mod keycloak;
mod models;
mod routes;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // CORS configuration
    let cors = CorsLayer::permissive();

    // Build our application with a route
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/api/auth/login", post(routes::auth::login))
        .route("/api/tasks", get(routes::tasks::list_tasks))
        .route("/api/tasks", post(routes::tasks::create_task))
        .route_layer(middleware::from_fn(auth_middleware))
        .layer(cors);

    // Run it
    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    tracing::info!("listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn health_check() -> &'static str {
    "OK"
}

async fn auth_middleware(
    headers: HeaderMap,
    request: Request,
    next: middleware::Next,
) -> Result<Response, StatusCode> {
    // Skip auth for health check and login endpoints
    let path = request.uri().path();
    if path == "/health" || path == "/api/auth/login" {
        return Ok(next.run(request).await);
    }

    // Extract Authorization header
    let auth_header = headers
        .get("Authorization")
        .and_then(|header| header.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    // Check if it's a Bearer token
    if !auth_header.starts_with("Bearer ") {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let token = &auth_header[7..]; // Remove "Bearer " prefix

    // For now, we'll do basic token validation
    // In production, you'd validate against Keycloak's public key
    if token.is_empty() {
        return Err(StatusCode::UNAUTHORIZED);
    }

    // TODO: Add proper Keycloak JWT validation here
    // For now, we'll accept any non-empty token

    Ok(next.run(request).await)
}
