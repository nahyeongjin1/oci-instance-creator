# OCI Free Tier Instance Creator

Oracle Cloud Free Tier A1 인스턴스를 자동으로 확보하기 위한 스크립트입니다.

## ⚠️ OCI Free Tier A1의 현실

OCI Free Tier A1 Flex는 스펙이 너무 좋아서 전 세계에서 경쟁이 치열합니다.

| 항목   | OCI Free Tier A1 | 타사 무료 티어       |
| ------ | ---------------- | -------------------- |
| CPU    | 4 OCPU (ARM)     | 보통 1 vCPU          |
| RAM    | 24GB             | 보통 1GB             |
| 저장소 | 200GB            | 보통 30GB            |
| 기간   | **영구 무료**    | 1년 한정 또는 제한적 |

`Out of host capacity` 에러가 기본이고, 자동화 스크립트로 반복 시도해야 확보할 수 있습니다.

## 📌 방법 비교: GitHub Actions vs VM/로컬 크론잡

이 레포지토리에는 두 가지 방법이 준비되어 있습니다.

| 방법           | 실행 간격                 | 안정성 | 권장 여부 |
| -------------- | ------------------------- | ------ | --------- |
| GitHub Actions | 최소 5분 (지연/누락 있음) | ⭐⭐   | △         |
| VM/로컬 크론잡 | 1분                       | ⭐⭐⭐ | ✅        |

### GitHub Actions가 권장되지 않는 이유

- **cron 최소 간격이 5분**: 경쟁이 치열한 상황에서 불리
- **실행 지연/누락 빈번**: 실제로는 7분~30분 간격으로 실행되기도 함
- **60일 비활성화**: Repository에 활동이 없으면 자동으로 workflow 비활성화

**결론**: 가능하면 VM이나 로컬에서 1분 간격 크론잡으로 돌리는 것이 유리합니다.

---

## 사전 준비: OCI API Key 생성

두 방법 모두 OCI API Key가 필요합니다.

### 1. API Key 생성

1. [OCI 콘솔](https://cloud.oracle.com) 로그인
2. 우측 상단 프로필 → **User settings**
3. **Tokens and keys** → **Add API key**
4. **Generate API key pair** 선택 → **Download private key** → **Add**
5. Configuration preview 내용 복사해두기

### 2. 필요한 정보

| 항목                | 가져오는 곳                                                  |
| ------------------- | ------------------------------------------------------------ |
| User OCID           | API Key 생성 시 Configuration preview                        |
| Fingerprint         | API Key 생성 시 Configuration preview                        |
| Tenancy OCID        | API Key 생성 시 Configuration preview                        |
| Private Key         | 다운로드한 `.pem` 파일                                       |
| Subnet OCID         | OCI 콘솔 → Networking → VCN → Subnets → OCID 복사            |
| Image OCID          | OCI 콘솔 → Compute → Images → 원하는 이미지 OCID             |
| Availability Domain | OCI 콘솔 → Compute → Instances → Create instance → AD 확인   |
| SSH 공개키          | 로컬 PC의 `~/.ssh/id_rsa.pub` (없으면 `ssh-keygen`으로 생성) |

---

## 방법 1: VM/로컬 크론잡 (권장)

### Step 1: OCI CLI 설치

```bash
# 설치
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)" -- --accept-all-defaults

# PATH 적용
source ~/.bashrc

# 설치 확인
oci --version
```

### Step 2: OCI 인증 설정

```bash
# 디렉토리 생성
mkdir -p ~/.oci

# config 파일 생성
cat > ~/.oci/config << 'EOF'
[DEFAULT]
user=ocid1.user.oc1..xxxxx
fingerprint=aa:bb:cc:dd:...
tenancy=ocid1.tenancy.oc1..xxxxx
region=ap-chuncheon-1
key_file=~/.oci/key.pem
EOF

# Private key 저장
cat > ~/.oci/key.pem << 'EOF'
-----BEGIN PRIVATE KEY-----
(다운로드한 .pem 파일 내용 붙여넣기)
-----END PRIVATE KEY-----
EOF

# 권한 설정
chmod 600 ~/.oci/config ~/.oci/key.pem

# 연결 테스트
oci iam region list --output table
```

### Step 3: Discord Webhook 설정 (알림용)

1. 알림을 받고자 하는 Discord 서버 우클릭 → 서버 설정 → 연동
2. **연동** → **웹후크** → **새 웹후크**
3. 이름 설정 (예: OCI Alert) → **웹후크 URL 복사**

### Step 4: 스크립트 설정

```bash
# 스크립트 다운로드
curl -o ~/oci-create.sh https://raw.githubusercontent.com/nahyeongjin1/oci-instance-creator/main/scripts/oci-create.sh
chmod +x ~/oci-create.sh

# 스크립트 내 설정값 수정
nano ~/oci-create.sh
```

수정해야 할 변수들:

| 변수                  | 설명                                            |
| --------------------- | ----------------------------------------------- |
| `DISCORD_WEBHOOK`     | Discord 웹훅 URL                                |
| `COMPARTMENT_ID`      | Tenancy OCID                                    |
| `AVAILABILITY_DOMAIN` | 가용 도메인 (예: `qibq:AP-CHUNCHEON-1-AD-1`)    |
| `SUBNET_ID`           | Subnet OCID                                     |
| `IMAGE_ID`            | Image OCID                                      |
| `INSTANCE_NAME`       | 생성할 인스턴스 이름                            |
| `SSH_PUBLIC_KEY`      | SSH 공개키 (로컬 PC의 `~/.ssh/id_rsa.pub` 내용) |

### Step 5: 스크립트 테스트

```bash
# 실행
~/oci-create.sh

# 로그 확인
cat ~/oci-instance.log
```

### Step 6: 크론잡 등록

```bash
# 크론탭 편집
crontab -e

# 맨 아래에 추가 (1분마다 실행)
* * * * * ~/oci-create.sh
```

### 모니터링

```bash
# 실시간 로그 확인
tail -f ~/oci-instance.log

# 시도 횟수 확인
wc -l ~/oci-instance.log

# 성공 여부 확인
ls ~/.oci-instance-created 2>/dev/null && echo "성공!" || echo "진행 중"
```

---

## 방법 2: GitHub Actions

> ⚠️ cron 실행이 지연/누락될 수 있어 **권장하지 않음**. 다른 방법이 없을 때만 사용하세요.

### GitHub Secrets 설정

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

### 워크플로우 설정

`.github/workflows/create-instance.yml`에서 필요시 수정:

- `availability-domain`: 본인 리전의 AD
- `shape-config`: OCPU/메모리 설정
- `cron`: 실행 주기

## 사용법

1. **수동 실행**: Actions 탭 → Run workflow
2. **자동 실행**: 기본 5분마다 자동 실행 (지연 가능)

## 성공 후

1. **크론잡 제거** (VM/로컬 방식)

```bash
   crontab -e
   # 해당 라인 삭제
```

2. **워크플로우 비활성화** (GitHub Actions 방식)

   - Actions → ... → Disable workflow

3. **인스턴스 확인**

   - OCI 콘솔 → Compute → Instances
   - Public IP 확인 후 SSH 접속 테스트

---

## 팁

- **시간대**: 새벽~아침(KST) 시간대에 성공 확률이 높음
- **리전**: 서울보다 춘천이 그나마 경쟁이 덜함 (그래도 어려움)
- **인내**: 며칠 걸릴 수 있으니 느긋하게 기다리기

---

## 참고

- [OCI Free Tier 공식 문서](https://www.oracle.com/cloud/free/)
