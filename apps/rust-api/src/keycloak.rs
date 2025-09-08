use anyhow::Result;
use jsonwebtoken::{decode, Algorithm, DecodingKey, Validation};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakTokenResponse {
    pub access_token: String,
    pub token_type: String,
    pub expires_in: u64,
    pub refresh_token: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakUserInfo {
    pub sub: String,
    pub preferred_username: String,
    pub email: Option<String>,
    pub name: Option<String>,
    pub given_name: Option<String>,
    pub family_name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakJwtHeader {
    pub alg: String,
    pub typ: String,
    pub kid: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakJwtPayload {
    pub sub: String,
    pub iss: String,
    pub aud: String,
    pub exp: u64,
    pub iat: u64,
    pub auth_time: u64,
    pub session_state: String,
    pub acr: String,
    pub realm_access: Option<RealmAccess>,
    pub resource_access: Option<HashMap<String, ResourceAccess>>,
    pub scope: String,
    pub sid: String,
    pub email_verified: Option<bool>,
    pub name: Option<String>,
    pub preferred_username: Option<String>,
    pub given_name: Option<String>,
    pub family_name: Option<String>,
    pub email: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RealmAccess {
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ResourceAccess {
    pub roles: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakCerts {
    pub keys: Vec<KeycloakKey>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KeycloakKey {
    pub kid: String,
    pub kty: String,
    pub alg: String,
    #[serde(rename = "use")]
    pub key_use: String,
    pub n: String,
    pub e: String,
}

pub struct KeycloakClient {
    client: Client,
    base_url: String,
    realm: String,
    client_id: String,
    client_secret: Option<String>,
}

impl KeycloakClient {
    pub fn new(
        base_url: String,
        realm: String,
        client_id: String,
        client_secret: Option<String>,
    ) -> Self {
        Self {
            client: Client::new(),
            base_url,
            realm,
            client_id,
            client_secret,
        }
    }

    pub async fn get_token(&self, username: &str, password: &str) -> Result<KeycloakTokenResponse> {
        let mut form_data = vec![
            ("grant_type", "password"),
            ("client_id", &self.client_id),
            ("username", username),
            ("password", password),
        ];

        if let Some(ref secret) = self.client_secret {
            form_data.push(("client_secret", secret));
        }

        let url = format!(
            "{}/realms/{}/protocol/openid-connect/token",
            self.base_url, self.realm
        );

        let response = self.client.post(&url).form(&form_data).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!(
                "Keycloak token request failed: {}",
                error_text
            ));
        }

        let token_response: KeycloakTokenResponse = response.json().await?;
        Ok(token_response)
    }

    pub async fn get_user_info(&self, access_token: &str) -> Result<KeycloakUserInfo> {
        let url = format!(
            "{}/realms/{}/protocol/openid-connect/userinfo",
            self.base_url, self.realm
        );

        let response = self
            .client
            .get(&url)
            .bearer_auth(access_token)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!(
                "Keycloak userinfo request failed: {}",
                error_text
            ));
        }

        let user_info: KeycloakUserInfo = response.json().await?;
        Ok(user_info)
    }

    pub async fn get_public_key(&self) -> Result<String> {
        let url = format!(
            "{}/realms/{}/protocol/openid-connect/certs",
            self.base_url, self.realm
        );

        let response = self.client.get(&url).send().await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow::anyhow!(
                "Keycloak certs request failed: {}",
                error_text
            ));
        }

        let certs: KeycloakCerts = response.json().await?;

        // For simplicity, we'll use the first key
        // In production, you should match the 'kid' from the JWT header
        if let Some(key) = certs.keys.first() {
            // Convert RSA public key components to PEM format
            // This is a simplified approach - in production, use a proper JWT library
            // that can handle JWK to PEM conversion
            Ok(format!(
                "-----BEGIN PUBLIC KEY-----\n{}\n-----END PUBLIC KEY-----",
                key.n
            ))
        } else {
            Err(anyhow::anyhow!("No public keys found"))
        }
    }

    pub fn validate_token(&self, token: &str, public_key: &str) -> Result<KeycloakJwtPayload> {
        let mut validation = Validation::new(Algorithm::RS256);
        validation.set_audience(&[&self.client_id]);
        validation.set_issuer(&[&format!("{}/realms/{}", self.base_url, self.realm)]);

        let token_data = decode::<KeycloakJwtPayload>(
            token,
            &DecodingKey::from_rsa_pem(public_key.as_bytes())?,
            &validation,
        )?;

        Ok(token_data.claims)
    }
}
