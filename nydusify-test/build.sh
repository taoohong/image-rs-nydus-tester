nydusify=/root/Programs/image-service/contrib/nydusify/cmd/nydusify
nydus_image=/root/Programs/image-service/target/debug/nydus-image
source=/usr/bin
target=build

$nydusify build --source-dir $source \
--output-dir $target \
--name buildtest \
--encrypt-recipients  jwe:/tmp/mypubkey.pem \
--nydus-image $nydus_image
