nydusify=./nydusify.sh
nydusd=/root/Programs/image-service/target/debug/nydusd
#target=localhost:5000/nginx:nydus-encrypted
target=nydus-dedup-registry.cn-hangzhou.cr.aliyuncs.com/mushu/nginx:encrypted-jwe

$nydusify mount \
--target $target \
--decrypt-keys /etc/mykey.pem \
--nydusd $nydusd
