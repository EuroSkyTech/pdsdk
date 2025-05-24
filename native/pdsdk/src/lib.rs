use std::time::Duration;

use async_std::{future, task};
use thiserror::Error;

uniffi::setup_scaffolding!();

#[derive(uniffi::Error, Error, Debug)]
pub enum Error {
    // NOTE: just error w/o foreing types at this point
    #[error("no new hellos available")]
    Unavailable,

    #[error("timeout waiting for hello: {0}")]
    Timeout(String),
}

impl From<future::TimeoutError> for Error {
    fn from(error: future::TimeoutError) -> Self {
        Error::Timeout(error.to_string())
    }
}

#[derive(uniffi::Object)]
pub struct World {
    attribute: String,
}

#[uniffi::export]
impl World {
    #[uniffi::constructor]
    pub fn new(attribute: String) -> Self {
        Self { attribute }
    }

    /// Exports the attribute of this world instance.
    pub fn get_attribute(&self) -> String {
        self.attribute.clone()
    }
}

#[uniffi::export]
#[async_trait::async_trait]
pub trait Hello: Send + Sync {
    async fn hello(&self) -> Result<String, Error>;
}

#[uniffi::export]
#[async_trait::async_trait]
impl Hello for World {
    async fn hello(&self) -> Result<String, Error> {
        task::sleep(Duration::from_secs(1)).await;
        Ok(format!("Hello, {} world!", self.attribute))
    }
}

#[uniffi::export]
pub fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
