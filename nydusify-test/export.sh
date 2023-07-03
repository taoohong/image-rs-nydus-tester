nydus_image=/root/Programs/image-service/target/debug/nydus-image
dir=create
bootstrap=$dir/bootstrap-merged 

rm -r unpack_output
$nydus_image export -B $bootstrap -D $dir --log-level trace --output unpack_output --block
