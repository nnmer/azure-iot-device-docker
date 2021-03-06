#!/bin/bash

cd ./scripts

checkExecStatus(){
    if [ $? -ne 0 ]; then
        echo ERROR, see the log.
        read Press any key to continue
        exit $?
    fi
}

sh ./certGen.sh create_root_and_intermediate
checkExecStatus

echo The root X.509 certificates is saved to: $(pwd)/build/certs/azure-iot-test-only.root.ca.cert.pem
echo ""

echo Put the verification code, obtained from Azure:
read verificationCode
sh ./certGen.sh create_verification_certificate $verificationCode

echo Verification certificates is saved to: $(pwd)/build/certs/verification-code.cert.pem
echo ""