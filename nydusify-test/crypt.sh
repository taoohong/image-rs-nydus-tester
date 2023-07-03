#!/bin/sh

WORKDIR=$(pwd)
NYDUSIFY=/root/Programs/image-service/contrib/nydusify/cmd/nydusify
nydus_image=/root/Programs/image-service/target/debug/nydus-image
nydusd=/root/Programs/image-service/target/debug/nydusd
AA_DIR=/root/Programs/attestation-agent
KP_DIR=$AA_DIR/coco_keyprovider
KP=$AA_DIR/target/release/coco_keyprovider
source=registry.openanolis.cn/openanolis/nginx:1.14.1-8.6
#target=localhost:5000/nginx:encrypted
#target=nydus-dedup-registry.cn-hangzhou.cr.aliyuncs.com/mushu/nginx:encrypted-jwe
target=nydus-dedup-registry.cn-hangzhou.cr.aliyuncs.com/mushu/nginx:encrypted

usage() {
    cat << EOT
    Usage:
    - ./crypt.sh prepare_key_provider 
    - ./crypt.sh prepare_attestation_agent
    - ./crypt.sh convert 
    - ./crypt.sh check 
    - ./crypt.sh start_key_provider 
    - ./crypt.sh start_attestation_agent 
EOT
    exit
}

prepare_key_provider() {
   pushd $KP_DIR 
   cargo build --release
   popd
}

prepare_attestation_agent() {
   pushd $AA_DIR
   make KBC=offline_fs_kbc && make install
   popd
}

start_key_provider() {
    RUST_LOG=coco_keyprovider $KP  --socket 127.0.0.1:51000 &> key_provider.log &
    KP_PID=$!
    echo "[$KP_PID] coco key provider started successfully!"
}

stop_key_provider() {
    kill -9 $KP_PID
    echo "[$KP_PID] stop key provider successfully!"
}

start_attestation_agent() {
    RUST_LOG=attestation_agent attestation-agent --keyprovider_sock 127.0.0.1:52000 &> aa.log &
    AA_PID=$!
    echo "[$AA_PID] aa with offline fs kbc started successfully!"
}

stop_attestation_agent() {
    kill -9 $AA_PID
    echo "[$AA_PID] stop attestation agent successfully!"
}

convert(){
    start_key_provider
    echo "Convert busybox to encrypted Nydus image and push to docker hub"
    OCICRYPT_KEYPROVIDER_CONFIG=ocicrypt.conf \
    $NYDUSIFY convert --source $source \
	--target $target \
	--nydus-image $nydus_image \
    --encrypt-recipients  provider:attestation-agent
	#--encrypt-recipients jwe:/etc/mypubkey.pem \

    if [ $? != 0 ]; then
	stop_key_provider
	exit 1
    fi
    stop_key_provider
    echo "Convert successfully!"
}

check() {
    start_attestation_agent
    echo "Check encrypted Nydus image"
    # OCICRYPT_KEYPROVIDER_CONFIG=ocicrypt2.conf \
    $NYDUSIFY check --source $source \
    	--target $target \
	--decrypt-keys /etc/mykey.pem \
    	--nydus-image $nydus_image \
	--nydusd $nydusd
#	--decrypt-keys provider:attestation-agent:offline_fs_kbc::null
    if [ $? != 0 ];then
	stop_attestation_agent
	exit 1
    fi
    stop_attestation_agent
    echo "Check successfully!"
}

main() {
    local dir=$(cd "$(dirname "$0")";pwd)
    local operation=$1
    if [ -z "$operation" ]; then
	usage
    fi

    if [ "$operation" = "convert" ] ;then
       convert ${@:2}
    elif [ "$operation" = "check" ] ;then
        check ${@:2}
    elif [ "$operation" = "prepare_key_provider" ] ;then
	prepare_key_provider
    elif [ "$operation" = "prepare_attestation_agent" ] ;then
        prepare_attestation_agent	    
    elif [ "$operation" = "start_key_provider" ];then
	start_key_provider
    elif [ "$operation" = "start_attestation_agent" ];then
	start_attestation_agent
    else
	usage
	echo "[FAILED] Unknown operation $operation"
    fi
}

main "$@"



