# 도구 설치 가이드

이 실습을 진행하기 위해 다음 도구들이 필요합니다.

## 필수 도구

- **Docker**: 컨테이너 이미지 다운로드 및 실행
- **Trivy**: 컨테이너 취약점 스캔
- **Syft**: SBOM (Software Bill of Materials) 생성
- **Grype**: SBOM 기반 취약점 분석

## macOS 설치

### Homebrew 설치 확인
```bash
brew --version
```

### Docker 설치
```bash
# Docker Desktop 다운로드 및 설치
# https://www.docker.com/products/docker-desktop
```

### Trivy 설치
```bash
brew install aquasecurity/trivy/trivy
```

### Syft 설치
```bash
brew install syft
```

### Grype 설치
```bash
brew install grype
```

## Ubuntu/Debian 설치

### Docker 설치
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
# 로그아웃 후 다시 로그인 필요
```

### Trivy 설치
```bash
sudo apt-get update
sudo apt-get install wget apt-transport-https gnupg lsb-release

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -

echo deb https://aquasecurity.github.io/trivy-repo/deb/ $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list

sudo apt-get update
sudo apt-get install trivy
```

### Syft 설치
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
```

### Grype 설치
```bash
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

## 설치 확인

모든 도구가 제대로 설치되었는지 확인하세요:

```bash
# Docker 확인
docker --version
docker ps

# Trivy 확인
trivy --version

# Syft 확인
syft version

# Grype 확인
grype version
```

## 문제 해결

### Trivy 설치 오류
- Homebrew tap 추가: `brew tap aquasecurity/trivy`
- 또는 직접 바이너리 다운로드: https://github.com/aquasecurity/trivy/releases

### Syft/Grype 설치 오류
- `/usr/local/bin`에 쓰기 권한이 없는 경우:
  ```bash
  sudo mkdir -p /usr/local/bin
  sudo chown $USER /usr/local/bin
  ```

### Docker 권한 오류 (Linux)
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## 선택적 도구

### Cosign (SBOM 서명용)
```bash
# macOS
brew install cosign

# Linux
wget -O cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign
sudo mv cosign /usr/local/bin/
```

### jq (JSON 파싱용)
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```
