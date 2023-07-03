nydus_image=/root/Programs/image-service/target/debug/nydus-image
dir=create

# rm -rf $dir/*

$nydus_image merge \
--bootstrap $dir/bootstrap-merged  \
-D $dir \
--log-level trace \
$dir/bootstrap-1 \
$dir/bootstrap-2 \
$dir/bootstrap-3 \
$dir/bootstrap-4
