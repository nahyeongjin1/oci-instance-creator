#!/bin/bash

LOG_FILE="$HOME/oci-instance.log"
SUCCESS_FLAG="$HOME/.oci-instance-created"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/xxxxx"  # FIXME: 본인 웹훅 URL로 변경

# FIXME: 설정값 - 본인 환경에 맞게 수정
COMPARTMENT_ID="ocid1.tenancy.oc1..xxxxx"
AVAILABILITY_DOMAIN="qibq:AP-CHUNCHEON-1-AD-1"
SUBNET_ID="ocid1.subnet.oc1..xxxxx"
IMAGE_ID="ocid1.image.oc1..xxxxx"
INSTANCE_NAME="my-instance"
SSH_KEY_FILE="$HOME/.ssh/oci_key.pub"  # SSH 공개키 파일 경로

# 이미 성공했으면 종료
if [ -f "$SUCCESS_FLAG" ]; then
    exit 0
fi

echo "$(date): Attempting to create instance..." >> "$LOG_FILE"

RESULT=$(oci compute instance launch \
    --compartment-id "$COMPARTMENT_ID" \
    --availability-domain "$AVAILABILITY_DOMAIN" \
    --shape "VM.Standard.A1.Flex" \
    --shape-config '{"ocpus": 4, "memoryInGBs": 24}' \
    --subnet-id "$SUBNET_ID" \
    --source-details "{\"sourceType\":\"image\",\"imageId\":\"$IMAGE_ID\",\"bootVolumeSizeInGBs\":200}" \
    --assign-public-ip true \
    --ssh-authorized-keys-file "$SSH_KEY_FILE" \
    --display-name "$INSTANCE_NAME" \
    2>&1)

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && echo "$RESULT" | grep -q "ocid1.instance"; then
    echo "$(date): SUCCESS!" >> "$LOG_FILE"
    echo "$RESULT" >> "$LOG_FILE"
    touch "$SUCCESS_FLAG"

    # Discord 알림
    curl -s -H "Content-Type: application/json" \
        -d "{\"content\":\"🎉 **OCI 인스턴스 생성 성공!**\n\n$(date)\"}" \
        "$DISCORD_WEBHOOK"
else
    # 에러 상세 로그 기록
    echo "$(date): Failed (exit code: $EXIT_CODE)" >> "$LOG_FILE"
    echo "$RESULT" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
fi
