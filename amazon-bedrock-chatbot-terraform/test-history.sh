#!/bin/bash

curl -X POST \
  https://$APIGW_DOMAIN/dev/history \
  -H 'Content-Type: application/json' \
  -d '{
    "userId": "shkim4u",
    "allowTime": "2024-01-15 12:27:24"
  }'

export WSS_DOMAIN=87trln7xf1.execute-api.ap-northeast-2.amazonaws.com
wscat -c wss://$WSS_DOMAIN/dev

export CONNECTION_URL_COMAIN=87trln7xf1.execute-api.ap-northeast-2.amazonaws.com
# connection_url: https://87trln7xf1.execute-api.ap-northeast-2.amazonaws.com/dev/@connections

# https://docs.aws.amazon.com/ko_kr/apigateway/latest/developerguide/apigateway-how-to-call-websocket-api-connections.html
클라이언트에게 콜백 메시지를 전송하려면 다음을 사용합니다.

POST https://{api-id}.execute-api.us-east-1.amazonaws.com/{stage}/@connections/{connection_id}

Postman을 사용하거나 다음 예와 같이 awscurl를 호출 하여 이 요청을 테스트할 수 있습니다.
awscurl --service execute-api -X POST -d "hello world" https://{prefix}.execute-api.us-east-1.amazonaws.com/{stage}/@connections/{connection_id}

다음 예제와 같이 명령을 URL 인코딩해야 합니다.
awscurl --service execute-api -X POST -d "hello world" https://aabbccddee.execute-api.us-east-1.amazonaws.com/prod/%40connections/R0oXAdfD0kwCH6w%3D
!!!Use This!!!
awscurl --service execute-api -X POST -d "hello world" https://$WSS__DOMAIN/dev/%40connections/RrS0kd0uIE0CJdA=
awscurl --service execute-api --region ap-northeast-2 -X POST -d "hello world" https://$WSS_DOMAIN/dev/%40connections/RrS0kd0uIE0CJdA\=
위에서 connection_id는 wscat을 연결한 후 얻을 수 있음.

클라이언트의 가장 최신 연결 상태를 얻으려면 다음을 사용합니다.
GET https://{api-id}.execute-api.us-east-1.amazonaws.com/{stage}/@connections/{connection_id}

클라이언트의 연결을 해제하려면 다음을 사용합니다.

DELETE https://{api-id}.execute-api.us-east-1.amazonaws.com/{stage}/@connections/{connection_id}

{
    "user_id": "shkim4u",
    "request_id": "69fb00a6-24ed-4041-b4f8-013d7dc796bd",
    "request_time": "2024-01-17 17:40:44",
    "type": "text",
    "body": "Testing"
}

===

람다 직접 호출 테스트
event:
{"requestContext": {
    "routeKey": "$default", "messageId": "RsI83cCDIE0CIqg=", "eventType": "MESSAGE", "extendedRequestId": "RsI83FhYIE0FvxQ=", "requestTime": "17/Jan/2024:15:14:00 +0000", "messageDirection": "IN", "stage": "dev", "connectedAt": 1705503499229, "requestTimeEpoch": 1705504440469, "identity": {"sourceIp": "218.233.108.149"}, "requestId": "RsI83FhYIE0FvxQ=", "domainName": "z7aqfmpd0c.execute-api.ap-northeast-2.amazonaws.com", "connectionId": "RsGpzfNaoE0CIqg=", "apiId": "z7aqfmpd0c"}, "body": "__ping__", "isBase64Encoded": False}

{
  "requestContext": {
    "routeKey": "$default",
    "messageId": "RsI83cCDIE0CIqg=",
    "eventType": "MESSAGE",
    "extendedRequestId": "RsI83FhYIE0FvxQ=",
    "requestTime": "17/Jan/2024:15:14:00 +0000",
    "messageDirection": "IN",
    "stage": "dev",
    "connectedAt": "1705503499229",
    "requestTimeEpoch": "1705504440469",
    "identity": {
      "sourceIp": "218.233.108.149"
    },
    "requestId": "RsI83FhYIE0FvxQ=",
    "domainName": "z7aqfmpd0c.execute-api.ap-northeast-2.amazonaws.com",
    "connectionId": "RsGpzfNaoE0CIqg=",
    "apiId": "z7aqfmpd0c"
  },
  "body": "__ping__",
  "isBase64Encoded": "False"
}
