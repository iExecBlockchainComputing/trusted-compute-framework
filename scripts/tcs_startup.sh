#! /bin/bash

# Copyright 2019 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

enclave_manager="${TCF_HOME}/examples/enclave_manager/tcf_enclave_manager/enclave_manager.py"
listener="${TCF_HOME}/examples/common/python/connectors/direct/tcs_listener/tcs_listener.py"
# Read Listener port from config file
listener_port=`grep listener_port ${TCF_HOME}/config/tcs_config.toml | awk {'print $3'}`

lmdb_server="${TCF_HOME}/examples/common/python/shared_kv/remote_lmdb/lmdb_listener.py"

start_tcs_components()
{
    # if remote_url is set, bootstrap the LMDB server
    lmdb_remote_url=$(grep ^remote_url ${TCF_HOME}/config/tcs_config.toml)
    if [ -n "${lmdb_remote_url}" ]; then
        echo "start the lmdb server"
        python3 ${lmdb_server} &
        sleep 3s
        echo "lmdb server started"
    fi

    echo "Starting Enclave manager.."
    python3 $enclave_manager &
    echo "Manager started"

    sleep 5s

    echo "Starting Listener.."
    python3 $listener --bind_uri $listener_port &
    echo "Listener started"

    if [ "$YES" != "1" ] ; then
        while true; do
        echo "If you wish to exit the program, press y and enter"
        read -t 5 yn
        case $yn in
            y )
                echo "Program is Successfully Ended"
                pkill -f "$listener"
                pkill -f "$enclave_manager"
                pkill -f "${lmdb_server}"
                exit;;
            * ) echo " ";;
        esac
        done
    fi
}


while getopts "y" OPTCHAR ; do
    case $OPTCHAR in
        y )
            YES=1
            ;;
        \? )
            BN=$(basename $0)
            echo "$BN: Start TCS" 1>&2
            echo "Usage: $BN [-y|-?]" 1>&2
            echo "Where:" 1>&2
            echo "-y    do not prompt to end program" 1>&2
            exit 2
            ;;
    esac
done
shift `expr $OPTIND - 1`


start_tcs_components
