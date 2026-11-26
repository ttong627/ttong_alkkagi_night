"""수호알까기 업로드 열쇠 만들기 + 깃허브 비밀값 등록(한 번만).

  python D:\\ttong_alkkagi_night\\tool\\setup_upload_key.py           # 비밀번호를 직접 입력(화면에 안 보임)
  python D:\\ttong_alkkagi_night\\tool\\setup_upload_key.py --dry-run # 시험: 임시 폴더에 시험 열쇠만, 깃허브엔 안 올림

비밀번호는 실행하는 사람이 정한다 — 화면·파일·기록에 남기지 않는다.
열쇠 파일은 D:\\TTong_Keys\\alkkagi_night_upload.jks (이미 있으면 덮어쓰지 않고 멈춘다).
"""
from __future__ import annotations

import base64
import getpass
import glob
import os
import subprocess
import sys
import tempfile
import uuid

REPO = "ttong627/ttong_alkkagi_night"
KEY_DIR = r"D:\TTong_Keys"
ALIAS = "upload"
DNAME = "CN=Well Share Logis, O=Well Share Logis Co. Ltd., C=KR"


def keytool() -> str:
    found = sorted(glob.glob(r"C:\Program Files\Eclipse Adoptium\*\bin\keytool.exe"))
    if not found:
        sys.exit("keytool 을 찾지 못했습니다(자바 설치 확인).")
    return found[-1]


def ask_password() -> str:
    p1 = getpass.getpass("새 업로드 열쇠 비밀번호(8자 이상, 화면에 안 보임): ")
    p2 = getpass.getpass("한 번 더: ")
    if p1 != p2:
        sys.exit("두 비밀번호가 다릅니다. 다시 실행하세요.")
    if len(p1) < 8:
        sys.exit("비밀번호는 8자 이상이어야 합니다.")
    return p1


def make_key(kt: str, jks: str, password: str) -> str:
    subprocess.run(
        [kt, "-genkeypair", "-keystore", jks, "-storetype", "PKCS12", "-alias", ALIAS,
         "-keyalg", "RSA", "-keysize", "2048", "-validity", "10000",
         "-storepass", password, "-keypass", password, "-dname", DNAME],
        check=True, stdin=subprocess.DEVNULL, capture_output=True,
    )
    out = subprocess.run(
        [kt, "-J-Duser.language=en", "-list", "-v", "-keystore", jks, "-storepass", password, "-alias", ALIAS],
        check=True, stdin=subprocess.DEVNULL, capture_output=True, text=True, errors="replace",
    ).stdout
    return next((ln.strip() for ln in out.splitlines() if "SHA256:" in ln), "")


def set_secret(name: str, value: str, env: dict) -> None:
    subprocess.run(["gh", "secret", "set", name, "-R", REPO], input=value, text=True, check=True, env=env,
                   capture_output=True)


def main() -> int:
    dry = "--dry-run" in sys.argv
    kt = keytool()
    if dry:
        key_dir = tempfile.mkdtemp(prefix="alkkagi_key_dry_")
        password = "dryrun-" + uuid.uuid4().hex[:10]
    else:
        key_dir = KEY_DIR
        password = ask_password()
    os.makedirs(key_dir, exist_ok=True)
    jks = os.path.join(key_dir, "alkkagi_night_upload.jks")
    if os.path.exists(jks):
        sys.exit(f"이미 열쇠가 있습니다: {jks} (덮어쓰지 않습니다)")
    fp = make_key(kt, jks, password)
    print(f"열쇠 만들었습니다: {jks}")
    print(f"지문 {fp}")
    if dry:
        print("시험 실행이라 깃허브에는 올리지 않았습니다.")
        return 0
    token = subprocess.run(["gh", "auth", "token", "--user", "ttong627"], capture_output=True, text=True,
                           check=True).stdout.strip()
    env = {**os.environ, "GH_TOKEN": token}
    with open(jks, "rb") as f:
        set_secret("ALKKAGI_UPLOAD_KEYSTORE_B64", base64.b64encode(f.read()).decode(), env)
    set_secret("ALKKAGI_KEYSTORE_PASSWORD", password, env)
    set_secret("ALKKAGI_KEY_PASSWORD", password, env)
    set_secret("ALKKAGI_KEY_ALIAS", ALIAS, env)
    print()
    print("깃허브 비밀값 4개 등록 끝.")
    print(f"열쇠 파일과 비밀번호는 꼭 따로 보관하세요(잃으면 구글에 업로드 열쇠 재설정을 요청해야 합니다): {jks}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
