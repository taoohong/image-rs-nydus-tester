use anyhow::{anyhow, Result};
use image_rs::image::ImageClient;
use log::{error, info};
use std::{path::Path, fs, process::Command, io::Write, env};

const AA_PATH: &str = "/usr/local/bin/attestation-agent";

const CONTAINER_BASE: &str = "/var/container_base";
const WORK_DIR: &str = "/var/lib/image-rs";
const OCICRYPT_CONFIG_PATH: &str = "/tmp/ocicrypt_config.json";

const AA_KEYPROVIDER_URI: &str =
    "unix:///run/confidential-containers/attestation-agent/keyprovider.sock";
const AA_GETRESOURCE_URI: &str =
    "unix:///run/confidential-containers/attestation-agent/getresource.sock";

pub async fn image_pull(image: &str, cid: &str) -> Result<String> {
    let mut cid = cid.to_string();

    if cid.is_empty() {
        let v: Vec<&str> = image.rsplit('/').collect();
        if !v[0].is_empty() {
            // ':' have special meaning for umoci during upack
            cid = v[0].replace(":", "_");
        } else {
            return Err(anyhow!("Invalid image name. {}", image));
        }
    } else {
        verify_cid(&cid)?;
    }

    info!("generated cid {}", cid);

    let mut image_client = ImageClient::default();

    let bundle_path = Path::new(CONTAINER_BASE).join(&cid);
    if !Path::new(WORK_DIR).exists() {
        std::fs::create_dir_all(Path::new(WORK_DIR))?;
    }
    
    if !bundle_path.exists() {
        std::fs::create_dir_all(&bundle_path)?;
    }

    info!(
        "pull image {:?}, cid: {:?}, bundle path {:?}",
        image, cid, bundle_path
    );
    // Image layers will store at KATA_CC_IMAGE_WORK_DIR, generated bundles
    // with rootfs and config.json will store under CONTAINER_BASE/cid.
    let res = image_client
        .pull_image(image, &bundle_path, &None, &None)
        .await;

    match res {
        Ok(image) => {
            info!(
                "pull and unpack image {:?}, cid: {:?}, with image-rs succeed. ",
                image, cid
            );
        }
        Err(e) => {
            error!(
                "pull and unpack image {:?}, cid: {:?}, with image-rs failed with {:?}. ",
                image,
                cid,
                e.to_string()
            );
            return Err(e);
        }
    };

    Ok(image.to_owned())
}

pub async fn encrypted_image_pull(image: &str, cid: &str) -> Result<String> {
    init_attestation_agent()?;
    let aa_kbc_params = "cc_kbc::http://172.18.0.1:8080";
    let decrypt_config = format!("provider:attestation-agent:{}", aa_kbc_params);
    env::set_var("OCICRYPT_KEYPROVIDER_CONFIG", OCICRYPT_CONFIG_PATH);

    let mut cid = cid.to_string();

    if cid.is_empty() {
        let v: Vec<&str> = image.rsplit('/').collect();
        if !v[0].is_empty() {
            // ':' have special meaning for umoci during upack
            cid = v[0].replace(":", "_");
        } else {
            return Err(anyhow!("Invalid image name. {}", image));
        }
    } else {
        verify_cid(&cid)?;
    }

    info!("generated cid {}", cid);

    let mut image_client = ImageClient::default();

    let bundle_path = Path::new(CONTAINER_BASE).join(&cid);
    if !Path::new(WORK_DIR).exists() {
        std::fs::create_dir_all(Path::new(WORK_DIR))?;
    }
    
    if !bundle_path.exists() {
        std::fs::create_dir_all(&bundle_path)?;
    }

    info!(
        "pull image {:?}, cid: {:?}, bundle path {:?}",
        image, cid, bundle_path
    );
    // Image layers will store at KATA_CC_IMAGE_WORK_DIR, generated bundles
    // with rootfs and config.json will store under CONTAINER_BASE/cid.
    let res = image_client
        .pull_image(image, &bundle_path, &None, &Some(&decrypt_config))
        .await;

    match res {
        Ok(image) => {
            info!(
                "pull and unpack image {:?}, cid: {:?}, with image-rs succeed. ",
                image, cid
            );
        }
        Err(e) => {
            error!(
                "pull and unpack image {:?}, cid: {:?}, with image-rs failed with {:?}. ",
                image,
                cid,
                e.to_string()
            );
            return Err(e);
        }
    };

    Ok(image.to_owned())
}

// A container ID must match this regex:
//
//     ^[a-zA-Z0-9][a-zA-Z0-9_.-]+$
//
pub fn verify_cid(id: &str) -> Result<()> {
    let mut chars = id.chars();

    let valid = match chars.next() {
        Some(first)
            if first.is_alphanumeric()
                && id.len() > 1
                && chars.all(|c| c.is_alphanumeric() || ['.', '-', '_'].contains(&c)) =>
        {
            true
        }
        _ => false,
    };

    match valid {
        true => Ok(()),
        false => Err(anyhow!("invalid container ID: {:?}", id)),
    }
}

// If we fail to start the AA, ocicrypt won't be able to unwrap keys
// and container decryption will fail.
fn init_attestation_agent() -> Result<()> {
    let config_path = OCICRYPT_CONFIG_PATH;

    // The image will need to be encrypted using a keyprovider
    // that has the same name (at least according to the config).
    let ocicrypt_config = serde_json::json!({
        "key-providers": {
            "attestation-agent":{
                "ttrpc":AA_KEYPROVIDER_URI
            }
        }
    });

    let mut config_file = fs::File::create(config_path)?;
    config_file.write_all(ocicrypt_config.to_string().as_bytes())?;

    // The Attestation Agent will run for the duration of the guest.
    Command::new(AA_PATH)
        .arg("--keyprovider_sock")
        .arg(AA_KEYPROVIDER_URI)
        .arg("--getresource_sock")
        .arg(AA_GETRESOURCE_URI)
        .env("AA_SAMPLE_ATTESTER_TEST", "1")
        .spawn()?;
    Ok(())
}
