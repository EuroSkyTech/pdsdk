use thiserror::Error;

#[cfg(mobi)]
uniffi::setup_scaffolding!();

#[cfg(wasm)]
use wasm_bindgen::prelude::*;

#[cfg(mobi)]
async fn sleep(millis: u32) {
    use smol::Timer;
    Timer::after(std::time::Duration::from_millis(millis as u64)).await;
}

#[cfg(wasm)]
async fn sleep(millis: u32) {
    use js_sys::Promise;
    use wasm_bindgen_futures::JsFuture;

    let promise = Promise::new(&mut |resolve, _| {
        web_sys::window()
            .unwrap()
            .set_timeout_with_callback_and_timeout_and_arguments_0(&resolve, millis as i32)
            .unwrap();
    });

    let _ = JsFuture::from(promise).await;
}

#[derive(Error, Debug)]
#[cfg_attr(mobi, derive(uniffi::Error))]
pub enum Error {
    // NOTE: just error w/o foreing types at this point
    #[error("no new hellos available")]
    Unavailable,

    #[error("timeout waiting for hello: {0}")]
    Timeout(String),
}

#[cfg(wasm)]
impl From<Error> for JsValue {
    fn from(err: Error) -> Self {
        JsValue::from_str(&err.to_string())
    }
}

#[cfg_attr(mobi, derive(uniffi::Object))]
#[cfg_attr(wasm, wasm_bindgen)]
pub struct World {
    attribute: String,
}

#[cfg_attr(mobi, uniffi::export)]
#[cfg_attr(wasm, wasm_bindgen)]
impl World {
    #[cfg_attr(mobi, uniffi::constructor)]
    #[cfg_attr(wasm, wasm_bindgen(constructor))]
    pub fn new(attribute: String) -> Self {
        Self { attribute }
    }

    /// Exports the attribute of this world instance.
    pub fn get_attribute(&self) -> String {
        self.attribute.clone()
    }
}

#[cfg(wasm)]
#[wasm_bindgen]
impl World {
    #[wasm_bindgen]
    pub async fn hello(&self) -> Result<String, Error> {
        sleep(1000).await;
        Ok(format!("Hello {} world!", self.attribute))
    }
}

#[cfg(mobi)]
#[uniffi::export]
#[async_trait::async_trait]
pub trait Hello: Send + Sync {
    async fn hello(&self) -> Result<String, Error>;
}

#[cfg(mobi)]
#[uniffi::export]
#[async_trait::async_trait]
impl Hello for World {
    async fn hello(&self) -> Result<String, Error> {
        sleep(1000).await;
        Ok(format!("Hello, {} world!", self.attribute))
    }
}

#[cfg_attr(mobi, uniffi::export)]
#[cfg_attr(wasm, wasm_bindgen)]
pub fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
