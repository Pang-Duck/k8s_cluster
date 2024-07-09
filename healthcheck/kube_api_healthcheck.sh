#!/usr/bin/env bash

# API 서버 엔드포인트 설정
API_SERVER="https://kubernetes.default.api:6443"

# 인증 토큰 설정 (필요한 경우)
TOKEN="YOUR_TOKEN"

# API 서버 상태 확인
#STATUS_CODE=$(curl -k -H "Authorization: Bearer $TOKEN" -X GET $API_SERVER/livez)
STATUS_CODE=$(curl -k -X GET $API_SERVER/livez)

# healthz는 depracted되었기 때문에 readyz, livez 사용

# 상태 코드 확인
if [ "$STATUS_CODE" -eq 200 ]; then
    echo "API 서버는 정상적으로 작동하고 있습니다."
else
    echo "API 서버 상태: 오류 (상태 코드: $STATUS_CODE)"
    exit 1
fi
