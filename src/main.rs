use crate::image::{image_pull, encrypted_image_pull};
use anyhow::Result;
use log::{error, info};
use std::{collections::HashMap, time::Instant, vec};

mod image;

#[tokio::main]
async fn main() -> Result<()>{
    env_logger::init();
    single_test().await?; 
    loop {}
}


async fn single_test() -> Result<()> {
    let images = vec![
        "nydus-dedup-registry.cn-hangzhou.cr.aliyuncs.com/mushu/busybox:encrypted",
        //"docker.io/busybox:latest"
    ];
    for image in images {
        let start = Instant::now(); 
        info!("pulling nydus image {}", image);
        if let Err(e) = encrypted_image_pull(image, "").await {
            error!("pull nydus image {} failed, {:?}", image, e)
        }

        let duration = start.elapsed();
        info!("pulling nydus image {} cast {:?}", image, duration);
    }
    Ok(())
}
