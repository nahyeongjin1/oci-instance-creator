# OCI Free Tier Instance Creator

GitHub Actions를 사용해 Oracle Cloud Free Tier A1 인스턴스를 자동으로 생성하는 스크립트입니다.

## ⚠️ 주의사항

GitHub Actions의 scheduled workflow는 다음과 같은 제한이 있습니다:

- **실행이 지연되거나 건너뛸 수 있음** (특히 사용량이 많은 시간대)
- 정확히 5분마다 실행되지 않을 수 있음
- Repository에 60일간 활동이 없으면 자동으로 비활성화됨

급하게 인스턴스가 필요하다면 로컬에서 직접 스크립트를 실행하는 것을 권장합니다.

## 설정 방법

### 1. OCI API Key 생성

1. [OCI 콘솔](https://cloud.oracle.com) 로그인
2. 우측 상단 프로필 → **User settings**
3. **Tokens and keys** → **Add API key**
4. **Generate API key pair** 선택 → **Download private key** → **Add**
5. Configuration preview 내용 복사해두기

### 2. GitHub Secrets 설정

Repository → Settings → Secrets and variables → Actions → **New repository secret**

| Secret Name       | 값                       | 가져오는 곳                                       |
| ----------------- | ------------------------ | ------------------------------------------------- |
| `OCI_USER`        | `ocid1.user.oc1..xxx`    | API Key 생성 시 Configuration preview             |
| `OCI_FINGERPRINT` | `aa:bb:cc:dd:...`        | API Key 생성 시 Configuration preview             |
| `OCI_TENANCY`     | `ocid1.tenancy.oc1..xxx` | API Key 생성 시 Configuration preview             |
| `OCI_KEY`         | Private key 전체 내용    | 다운로드한 `.pem` 파일 내용                       |
| `OCI_SUBNET`      | `ocid1.subnet.oc1...`    | OCI 콘솔 → Networking → VCN → Subnets → OCID 복사 |
| `OCI_IMAGE`       | `ocid1.image.oc1...`     | OCI 콘솔 → Compute → Images → 원하는 이미지 OCID  |
| `SSH_PUBLIC_KEY`  | `ssh-rsa AAAA...`        | `~/.ssh/id_rsa.pub` 내용                          |

### 3. 워크플로우 설정

`.github/workflows/create-instance.yml`에서 필요시 수정:

- `availability-domain`: 본인 리전의 AD
- `shape-config`: OCPU/메모리 설정
- `cron`: 실행 주기

## 사용법

1. **수동 실행**: Actions 탭 → Run workflow
2. **자동 실행**: 기본 5분마다 자동 실행

## 성공 후

1. **워크플로우 즉시 비활성화**: Actions → ... → Disable workflow
2. OCI 콘솔에서 인스턴스 확인
3. Public IP로 SSH 접속 테스트
