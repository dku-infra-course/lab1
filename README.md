# labs

단국대학교 「인프라 설계 및 구축」 주차별 실습 코드 저장소.

## 이 저장소와 실습 가이드의 관계

- **실습 가이드(HTML)** 는 강의 자료로 배포된다. 화면 캡처, 개념 설명, 단계별 서술, 검증 체크포인트, 연습 문제가 들어 있다.
- **이 저장소** 는 그 가이드에서 사용하는 **명령과 설정의 원본** 이다. 가이드를 보면서 손으로 타이핑하는 대신, 여기서 파일을 복사하거나 스크립트를 실행한다.
- 따라서 **순서와 설명은 가이드를 따르고, 내용(설정값·명령)은 이 저장소를 기준** 으로 한다. 두 곳이 다르면 이 저장소를 최신으로 본다.

| 주차 | 폴더 | 실습 가이드 파일 | 주제 |
|---|---|---|---|
| 1주차 | `week01-environment/` | `실습_W1_환경준비.html` | Solid Cloud 콘솔, 격리 네트워크, 첫 VM, 포트포워딩 |
| 2주차 | `week02-linux-network/` | `실습_W2_리눅스네트워크.html` | 서버 스펙 확인, 리눅스 기본, 네트워크 확인, Apache |
| 3주차 | `week03-ha-keepalived/` | `실습_W3_이중화.html` | Keepalived VIP Failover (Active/Backup) |
| 4주차 | `week04-loadbalancer/` | `실습_W4_로드밸런싱.html` | Nginx 리버스 프록시와 로드밸런싱 |
| 5주차 | `week05-cache/` | `실습_W5_캐시.html` | Redis 애플리케이션 캐시, Nginx/Squid 웹 캐시 |

## 사용법

```bash
git clone https://github.com/hyungwook-0221/dku-infra-labs.git
cd dku-infra-labs
ls -1
```

해당 주차 폴더로 이동해 그 폴더의 `README.md` 를 먼저 읽는다.

```bash
cd week03-ha-keepalived
cat README.md
```

셸 스크립트는 실행 권한이 없는 상태로 배포된다. 실행 전에 권한을 준다.

```bash
chmod +x *.sh
./install-keepalived.sh web01
```

## 환경값 치환 규칙

학생마다 달라지는 값은 파일 안에 `{{...}}` 형태의 자리표시자로 두었다. 사용 전에 본인 환경 값으로 바꾼다.

| 자리표시자 | 의미 | 실습 기본 관례값 |
|---|---|---|
| `{{WEB01_IP}}` | 웹 서버 1 사설 IP | `192.168.0.10` |
| `{{WEB02_IP}}` | 웹 서버 2 사설 IP | `192.168.0.11` |
| `{{LB_IP}}` | 로드밸런서(Nginx) VM 사설 IP | `192.168.0.20` |
| `{{VIP}}` | 가상 IP (Keepalived / IPVS) | `192.168.0.100` |
| `{{WEBSERVER_IP}}` | 5주차 백엔드 서버 사설 IP | `192.168.0.10` |
| `{{CACHE_IP}}` | 5주차 캐시 서버 사설 IP | `192.168.0.20` |
| `{{IFACE}}` | 네트워크 인터페이스 이름 | `ens3` (`ip link` 로 확인) |
| `{{PUBLIC_IP}}` | 가상 라우터 공용 IP | 계정마다 다름 (본인 화면에서 직접 확인해 채운다) |
| `{{STUDENT_ID}}` | 학번 (VM·네트워크 이름에 사용) | 본인 학번 |
| `{{REDIS_PASSWORD}}` | Redis `requirepass` 값 | 직접 정한 강한 값 |
| `{{SERVER_LABEL}}` | 4주차 백엔드 구분용 페이지 문구 | `Web Server 01` / `Administrator Page` |

### 치환 방법 1: 편집기로 직접 수정

```bash
vim week03-ha-keepalived/keepalived-web01.conf   # {{VIP}}, {{IFACE}} 등을 찾아 수정
```

### 치환 방법 2: 스크립트 인자로 전달

각 주차의 `install-*.sh` / `verify-*.sh` 는 필요한 값을 인자나 환경 변수로 받는다. 각 폴더 README의 실행 순서를 참고한다.

## 네트워크 관례

3주차 이후 실습은 하나의 격리 네트워크(`192.168.0.0/24`) 안에서 진행한다.

```
192.168.0.10   web01 / webserver01 / 5주차 백엔드 서버
192.168.0.11   web02 / webserver02
192.168.0.20   lb (Nginx 로드밸런서) / 5주차 캐시 서버
192.168.0.100  VIP (Keepalived, IPVS 공통)
```

실제 배정 대역이 다르면 위 표의 값을 본인 대역으로 바꾸어 읽는다.

## 주의: 자격증명은 커밋하지 않는다

- SSH 개인키(`*.pem`, `id_rsa`), `.env`, `*.tfvars`, Redis 비밀번호, 클라우드 API 키를 저장소에 올리지 않는다. `.gitignore` 에 기본 패턴이 들어 있지만, 최종 책임은 커밋하는 사람에게 있다.
- 커밋 전 확인:

  ```bash
  git status
  git diff --cached
  ```

- 실수로 올렸다면 되돌리는 것만으로는 부족하다. **해당 자격증명을 즉시 폐기하고 새로 발급** 한다.
- 과제 제출용 캡처에 공용 IP·포트·계정이 함께 찍히는 경우가 많다. 공개 저장소에 올릴 때는 가린다.

## 실습 환경

- 플랫폼: DKU Solid Cloud (Apache CloudStack 기반). 교내망 또는 VPN에서만 접근한다. VM·네트워크 만들기는 각 주차 실습 가이드를 따른다.
- 패키지 버전은 고정하지 않는다. `apt` 기본 저장소 버전을 그대로 쓴다. 특정 버전이 필요한 경우에만 각 주차 README에 표기했다.

## 문의

실습 코드 오류·개선 제안은 강의 공지 채널로 알린다.

Networked Systems and Security Lab @ DKU
