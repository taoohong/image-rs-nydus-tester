nydus_image=/root/Programs/image-service/target/debug/nydus-image
dir=create
source=test4

# rm -rf $dir/*

$nydus_image create -t dir-rafs \
--bootstrap $dir/bootstrap-4 \
-D $dir \
--log-level debug \
$source
