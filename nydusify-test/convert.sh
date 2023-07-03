WORKDIR=$(pwd)
nydusify=/root/Programs/image-service/contrib/nydusify/cmd/nydusify
nydus_image=/root/Programs/image-service/target/debug/nydus-image
target_prefix=nydus-dedup-registry.cn-hangzhou.cr.aliyuncs.com/mushu
image_list=(
	#alpine
	#busybox
	#centos
	#nginx
	#python
	#redis
	#mysql
	#node
	#gradle
	#ubuntu
)

usage() {
	cat << EOF
usage:
	-nydus
	-oci
EOF
}

convert_nydus() {
	for var in ${image_list[@]}
	do 
		OCICRYPT_KEYPROVIDER_CONFIG=$WORKDIR/ocicrypt.conf \
		$nydusify convert --source docker.io/library/$var:latest \
		--target $target_prefix/$var:encrypted \
		--encrypt-recipients provider:attestation-agent \
		--nydus-image $nydus_image
	done
}

convert_oci() {
	for var in ${image_list[@]}
	do
		OCICRYPT_KEYPROVIDER_CONFIG=$WORKDIR/ocicrypt.conf \
		skopeo copy --encryption-key provider:attestation-agent \
		docker://library/$var:latest \
		docker://$target_prefix/$var:encrypted-oci
	done
}

main(){
	local op=$1
	
	if [ -z "$op" ];then
		usage
		exit 0
	fi

	if [ $op = nydus ];then
		convert_nydus ${@:2}
	elif [ $op = oci ];then
		convert_oci ${@:2}
	else
		usage
		exit 1
	fi
}

main $@
