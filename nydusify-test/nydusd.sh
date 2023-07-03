nydusd=/root/Programs/image-service/target/debug/nydusd 

$nydusd \
--config nydusd_config.json \
--mountpoint mnt \
--bootstrap output/nydus_bootstrap \
--log-level debug
