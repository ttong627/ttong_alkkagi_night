package TTong.alkkagi

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 비정상 종료 원인을 기기 내부에 기록하고 다음 실행 시 설정 화면에서 열람할 수 있게 한다.
        Diag.install(this)
        Diag.register(this, flutterEngine)
        // 직접 설치판(sideload)은 자체 업데이트 채널을 열고, 플레이 스토어판(play)은 빈 스텁만 연결한다.
        Updater.register(this, flutterEngine)
        Haptics.register(this, flutterEngine)
    }
}
