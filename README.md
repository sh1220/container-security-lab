# Minimal Image 보안 분석

Nginx 기반 이미지의 보안 분석을 통해 Minimal Image의 장점을 체험하는 실습입니다.

## 📋 사전 요구사항

- Docker 설치 및 실행 중
- 다음 도구들 설치:
  ```bash
  # macOS
  brew install aquasecurity/trivy/trivy
  brew install syft
  brew install grype
  
  # Ubuntu/Debian
  sudo apt install trivy
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
  ```

자세한 설치 방법은 `requirements.md`를 참고하세요.

## 🚀 빠른 시작

### 방법 1: 자동 실행 (권장)
```bash
chmod +x run-experiment.sh
./run-experiment.sh
```

### 방법 2: 단계별 실행

#### 1️⃣ 이미지 다운로드 및 크기 비교
```bash
docker pull nginx:latest
docker pull nginx:alpine
docker pull vulhub/nginx:1.13.2  # vulhub 취약점 테스트 이미지 (의도적 취약점 포함)
docker images | grep -E "(nginx|vulhub)"
```

#### 2️⃣ Trivy 취약점 스캔
```bash
trivy image nginx:latest > results/latest-report.txt
trivy image nginx:alpine > results/alpine-report.txt
trivy image vulhub/nginx:1.13.2 > results/old-version-report.txt  # 취약점 예시
```

#### 3️⃣ SBOM 생성
```bash
# JSON 형식 SBOM (세 이미지 모두)
syft nginx:latest -o json > results/sbom-nginx-latest.json
syft nginx:alpine -o json > results/sbom-nginx-alpine.json
syft vulhub/nginx:1.13.2 -o json > results/sbom-vulhub-nginx.json

# Table 형식 SBOM (세 이미지 모두)
syft nginx:latest -o table > results/sbom-nginx-latest-table.txt
syft nginx:alpine -o table > results/sbom-nginx-alpine-table.txt
syft vulhub/nginx:1.13.2 -o table > results/sbom-vulhub-nginx-table.txt
```

#### 4️⃣ SBOM 기반 취약점 분석
```bash
grype sbom:results/sbom-nginx-latest.json > results/vulns-from-sbom-latest.txt
grype sbom:results/sbom-nginx-alpine.json > results/vulns-from-sbom-alpine.txt
grype sbom:results/sbom-vulhub-nginx.json > results/vulns-from-sbom-vulhub.txt
```

#### 5️⃣ 결과 비교
```bash
chmod +x compare-results.sh
./compare-results.sh
```

## 📊 예상 결과

| 항목 | nginx:latest | nginx:alpine | vulhub/nginx:1.13.2 (취약점 예시) |
|------|-------------|--------------|------------------------|
| 이미지 크기 | ~187MB | ~39MB | ~100MB |
| Critical 취약점 | ~0-5개 | ~0-3개 | ~10-30개 ⚠️ |
| SBOM 패키지 수 | ~120개 | ~40개 | ~100개 |

**참고**: 
- `vulhub/nginx:1.13.2`는 vulhub 프로젝트의 취약점 테스트 이미지로 **의도적으로 취약점이 포함**되어 있어 보안 스캔 실습에 최적화되어 있습니다

## 📁 결과 파일

모든 결과는 `results/` 디렉토리에 저장됩니다:

**Trivy 취약점 리포트:**
- `latest-report.txt`: nginx:latest 취약점 리포트
- `alpine-report.txt`: nginx:alpine 취약점 리포트
- `old-version-report.txt`: vulhub/nginx:1.13.2 취약점 리포트

**SBOM 파일:**
- **JSON 형식:**
  - `sbom-nginx-latest.json`: nginx:latest SBOM
  - `sbom-nginx-alpine.json`: nginx:alpine SBOM
  - `sbom-vulhub-nginx.json`: vulhub/nginx:1.13.2 SBOM
- **Table 형식:**
  - `sbom-nginx-latest-table.txt`: nginx:latest SBOM (표 형식)
  - `sbom-nginx-alpine-table.txt`: nginx:alpine SBOM (표 형식)
  - `sbom-vulhub-nginx-table.txt`: vulhub/nginx:1.13.2 SBOM (표 형식)

**SBOM 기반 취약점 분석:**
- `vulns-from-sbom-latest.txt`: nginx:latest SBOM 기반 취약점
- `vulns-from-sbom-alpine.txt`: nginx:alpine SBOM 기반 취약점
- `vulns-from-sbom-vulhub.txt`: vulhub/nginx:1.13.2 SBOM 기반 취약점

**요약:**
- `comparison-summary.txt`: 비교 요약

## 🔍 결과 확인 팁

### 취약점 개수 확인
```bash
grep -c "CRITICAL" results/latest-report.txt
grep -c "CRITICAL" results/alpine-report.txt
```

### SBOM 패키지 목록 확인
```bash
cat results/sbom-nginx-alpine-table.txt
```

### JSON SBOM 구조 확인 (jq 필요)
```bash
cat results/sbom-nginx-alpine.json | jq '.artifacts[] | {name, version, type}'
```

## 🧠 추가 실습 아이디어

1. **Cosign으로 SBOM 서명**
   ```bash
   cosign generate-key-pair
   cosign sign --key cosign.key results/sbom-nginx-alpine.json
   ```

2. **CI/CD 통합 예시**: `.github/workflows/security-scan.yml` 참고

3. **다른 이미지 비교**: `node:latest` vs `node:alpine` 등

## 📚 참고 자료

- [Trivy 공식 문서](https://aquasecurity.github.io/trivy/)
- [Syft 공식 문서](https://github.com/anchore/syft)
- [Grype 공식 문서](https://github.com/anchore/grype)

## 🎯 실습 목표

이 실습을 통해 다음을 학습할 수 있습니다:

1. **Minimal Image의 장점 이해**
   - 이미지 크기 감소
   - 공격 표면 감소
   - 빌드/배포 속도 향상

2. **보안 스캔 도구 활용**
   - Trivy를 통한 컨테이너 취약점 스캔
   - 취약점 리포트 분석

3. **SBOM (Software Bill of Materials) 이해**
   - 공급망 가시성 확보
   - 패키지 구성 파악
   - SBOM 기반 취약점 분석

4. **DevSecOps 워크플로우 체험**
   - 자동화된 보안 스캔
   - 결과 비교 및 분석