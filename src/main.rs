use crate::image::{image_pull, encrypted_image_pull};
use anyhow::Result;
use log::{error, info};
use std::{collections::HashMap, time::Instant, vec};

mod image;

#[tokio::main]
async fn main() {
    env_logger::init();
    single_test().await;
    loop {}
}


async fn single_test() -> Result<()> {
    let images = vec![
        //"eci-overlay-image-store-registry.cn-hangzhou.cr.aliyuncs.com/eci_overlagy_image_ns/ubuntu:20.04"
        // "eci-nydus-registry.cn-hangzhou.cr.aliyuncs.com/v6/java:latest-test_nydus", 
        "taoohong/alpine:nydus-encrypted",
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

async fn test_diff() -> Result<()>{
    let mut images: HashMap<&str, (&str, &str)> = HashMap::new();
    
    // images.insert(
    //     "python", 
    //     (
    //         "eci-overlay-image-store-registry.cn-hangzhou.cr.aliyuncs.com/eci_overlagy_image_ns/python:3.10",
    //         "eci-nydus-registry.cn-hangzhou.cr.aliyuncs.com/test/python:latest_nydus",
    //     )
    // );

    // images.insert(
    //     "ubuntu", 
    //     (
    //         "eci-overlay-image-store-registry.cn-hangzhou.cr.aliyuncs.com/eci_overlagy_image_ns/ubuntu:20.04",
    //         "eci-nydus-registry.cn-hangzhou.cr.aliyuncs.com/test/ubuntu:latest_nydus",
    //     )
    // );

    images.insert(
        "golang",
        (
            "eci-overlay-image-store-registry.cn-hangzhou.cr.aliyuncs.com/eci_overlagy_image_ns/golang:1.17",
            "eci-nydus-registry.cn-hangzhou.cr.aliyuncs.com/test/golang:latest_nydus",
        )
    );
    for (key, value) in images {
        let mut start = Instant::now();
        info!("pulling normal {} image {}", key, value.0);
        if let Err(e) = image_pull(value.0, "").await {
            error!("pull normal image {} failed, {:?}", key, e)
        }

        let mut duration = start.elapsed();
        info!("pulling normal image {} cast {:?}", key, duration);

        start = Instant::now();
        info!("pulling nydus {} image {}", key, value.1);
        if let Err(e) = image_pull(value.1, "").await {
            error!("pull nydus image {} failed, {:?}", key, e)
        }

        duration = start.elapsed();
        info!("pulling nydus image {} cast {:?}", key, duration);
    }

    Ok(())
}
