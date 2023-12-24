import json
import os
import time

import requests


def send_to_slack_channel(**kwargs):
    webhook_url = kwargs.get('webhook_url')
    channel = kwargs.get('channel')
    icon_emoji = kwargs.get('icon_emoji')
    text = kwargs.get('text')
    # vulnerability_index = kwargs.get('vulnerability_index')

    vulnerability_infos = kwargs.get('vulnerability_infos')

    attachments = []

    # Assign all the "pretext" element of vulnerability_infos to attachments.
    for vulnerability_info in vulnerability_infos:
        # Get current timestamp.
        timestamp = int(time.time())
        attachments.append(
            {
                "fallback": "요청 실패 시 보낼 메시지",
                "color": "#2eb886",
                "pretext": vulnerability_info.get('pretext'),
                "author_name": "CWE: (TODO) 취약점의 Author 이름",
                "author_link": "https://<여기에 CWE Author URL 입력>",
                "author_icon": "https://<여기에 적절한 아이콘 링크 URL 입력>",
                "title": vulnerability_info.get('title'),
                "title_link": vulnerability_info.get('title_link'),
                "text": "보안 취약점 및 권장 조치 사항 (AI가 생성한 내용)",
                "fields": vulnerability_info.get('fields'),
                "image_url": "http://<여기에 본문 이미지 URL 입력>",
                "thumb_url": "http://<여기에 본문 이미지 Thumbnail URL 입력>",
                "footer": "AWS CodeBuild",
                "footer_icon": "https://<여기에 적절한 Footer Icon URL 입력. 예: AWS CodeBuild Artifact URL 등>",
                "ts": timestamp
            }
        )

    # attachments = [
    #     {
    #         "fallback": "요청 실패 시 보낼 메시지",
    #         "color": "#2eb886",
    #         "pretext": f"보안 취약점 정보 [{vulnerability_index}]: (TODO) 소스 코드 위치 등",
    #         "author_name": "CWE: (TODO) 취약점의 Author 이름",
    #         "author_link": "https://<여기에 CWE Author URL 입력>",
    #         "author_icon": "https://<여기에 적절한 아이콘 링크 URL 입력>",
    #         "title": "보안 취약점 개요",
    #         "title_link": "https://<여기에 CWE 참조 URL 혹은 Amazon Bedrock에서 참조로 제시한 URL 입력>",
    #         "text": "보안 취약점 및 권장 조치 사항 (AI 모델이 생성한 내용)",
    #         "fields": [
    #             {
    #                 "title": "필드 1",
    #                 "value": "값 1",
    #                 "short": "false"
    #             },
    #             {
    #                 "title": "필드 2",
    #                 "value": test_text,
    #                 "short": "false"
    #             }
    #         ],
    #         "image_url": "http://<여기에 본문 이미지 URL 입력>",
    #         "thumb_url": "http://<여기에 본문 이미지 Thumbnail URL 입력>",
    #         "footer": "AWS CodeBuild",
    #         "footer_icon": "https://<여기에 적절한 Footer Icon URL 입력. 예: AWS CodeBuild Artifact URL 등>",
    #         "ts": timestamp
    #     },
    #     {
    #         "fallback": "요청 실패 시 보낼 메시지",
    #         "color": "#2eb886",
    #         "pretext": f"보안 취약점 정보 [{vulnerability_index}]: (TODO) 소스 코드 위치 등",
    #         "author_name": "CWE: (TODO) 취약점의 Author 이름",
    #         "author_link": "https://<여기에 CWE Author URL 입력>",
    #         "author_icon": "https://<여기에 적절한 아이콘 링크 URL 입력>",
    #         "title": "보안 취약점 개요",
    #         "title_link": "https://<여기에 CWE 참조 URL 혹은 Amazon Bedrock에서 참조로 제시한 URL 입력>",
    #         "text": "보안 취약점 및 권장 조치 사항 (AI 모델이 생성한 내용)",
    #         "fields": [
    #             {
    #                 "title": "필드 1",
    #                 "value": "값 1",
    #                 "short": "false"
    #             },
    #             {
    #                 "title": "필드 2",
    #                 "value": "값 2",
    #                 "short": "false"
    #             }
    #         ],
    #         "image_url": "http://<여기에 본문 이미지 URL 입력>",
    #         "thumb_url": "http://<여기에 본문 이미지 Thumbnail URL 입력>",
    #         "footer": "AWS CodeBuild",
    #         "footer_icon": "https://<여기에 적절한 Footer Icon URL 입력. 예: AWS CodeBuild Artifact URL 등>",
    #         "ts": timestamp
    #     }
    # ]

    payload = {
        "channel": channel,
        "icon_emoji": icon_emoji,
        "attachments": attachments,
        "text": text,
    }

    response = requests.post(
        webhook_url, data=json.dumps(payload),
        headers={'Content-Type': 'application/json'}
    )


if __name__ == '__main__':
    test_text = """
네, 이 코드에는 명령 인젝션 취약점이 있습니다.

rt.exec() 메서드에 사용자 입력값인 cmd 변수가 직접 전달되고 있기 때문입니다.

공격자가 cmd 변수에 악의적인 명령을 전달할 경우 시스템 명령이 실행될 수 있습니다.

이를 방지하기 위해서는 다음과 같이 조치할 수 있습니다.

1. 사용자 입력값에 대한 유효성 검증 수행
- 정규식 등을 사용하여 cmd 값이 유효한지 확인

2. rt.exec() 대신 ProcessBuilder를 사용
- ProcessBuilder allows to specify command in a List

예시:

```java
List<String> command = new ArrayList<>();
command.add("ls");
command.add("-l");

ProcessBuilder processBuilder = new ProcessBuilder(command);
Process process = processBuilder.start();
```

3. 사용자 입력값을 명령어와 분리
- 사용자 입력값이 직접 명령어에 포함되지 않도록 분리

이를 통해 명령 인젝션 공격을 방지할 수 있습니다. 입력 값 검증과 별도로 처리하는 것이 좋습니다.
"""

    vulnerability_infos = [
        {
            "pretext": "보안 취약점 정보 [0]: (TODO) 소스 코드 위치 등",
            "title": "보안 취약점 개요",
            "title_link": "https://<여기에 CWE 참조 URL 혹은 Amazon Bedrock에서 참조로 제시한 URL 입력>",
            "fields": [
                {
                    "title": "취약점",
                    "value": "값 1",
                    "short": "false"
                },
                {
                    "title": "권장 조치 사항",
                    "value": test_text,
                    "short": "false"
                }
            ]
        },
        {
            "pretext": "보안 취약점 정보 [1]: (TODO) 소스 코드 위치 등",
            "title": "보안 취약점 개요",
            "title_link": "https://<여기에 CWE 참조 URL 혹은 Amazon Bedrock에서 참조로 제시한 URL 입력>",
            "fields": [
                {
                    "title": "취약점",
                    "value": "값 1",
                    "short": "false"
                },
                {
                    "title": "권장 조치 사항",
                    "value": test_text,
                    "short": "false"
                }
            ]
        }
    ]

    dev_slack_webhook_url = os.environ.get("DEV_SLACK_WEBHOOK_URL", None)
    send_to_slack_channel(
        webhook_url=dev_slack_webhook_url,
        channel="sanghyoun-security-alerts",
        icon_emoji=":warning:",
        text="어플리케이션 보안 취약점: (TODO) 스캔 시간, Application 이름, Committer, CommitId 등",
        vulnerability_infos=vulnerability_infos
    )
