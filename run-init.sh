#!/bin/bash

cd ./scripts

checkExecStatus(){
    if [ $? -ne 0 ]; then
        echo ERROR, see the log.
        read Press any key to continue
        exit $?
    fi
}

./certGen.sh create_root_and_intermediate
checkExecStatus

echo The root X.509 certificates is saved to: ./scripts/certs/azure-iot-test-only.root.ca.cert.pem
echo ""

echo Put the verification code, obtained from Azure:
read verificationCode
./certGen.sh create_verification_certificate $verificationCode

echo Verification certificates is saved to: ./scripts/certs/verification-code.cert.pem
echo ""