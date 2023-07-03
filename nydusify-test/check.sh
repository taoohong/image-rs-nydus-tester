nydusify=/root/Programs/image-service/contrib/nydusify/cmd/nydusify
nydus_image=/root/Programs/image-service/target/debug/nydus-image
nydusd=/root/Programs/image-service/target/debug/nydusd
image_ref=localhost:5000/nginx:nydus-encrypted
source=registry.openanolis.cn/openanolis/nginx:1.14.1-8.6

rm -rf output/*

$nydusify convert \
--source $source \
--target $image_ref \
--nydus-image $nydus_image \
--encrypt-recipients jwe:/etc/mypubkey.pem

$nydusify check \
--source $source \
--target $image_ref \
--nydus-image $nydus_image \
--decrypt-keys /etc/mykey.pem \
--nydusd $nydusd
