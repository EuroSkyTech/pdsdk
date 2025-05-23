use async_std::future;
use std::time::Duration;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("no new hellos available")]
    Unavailable,

    #[error("timeout waiting for hello")]
    Timeout(#[from] future::TimeoutError),
}

pub struct World {
    attribute: String,
}

impl World {
    pub fn new(attribute: String) -> Self {
        Self { attribute }
    }
}

pub trait Hello<T> {
    type Error;
    fn hello(&self) -> impl Future<Output = Result<T, Self::Error>>;
}

impl Hello<String> for World {
    type Error = Error;
    async fn hello(&self) -> Result<String, Self::Error> {
        future::timeout(Duration::from_secs(1), future::pending()).await?;
        Ok(format!("Hello, {} world!", self.attribute))
    }
}

#[uniffi::export]
pub fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}

uniffi::setup_scaffolding!();