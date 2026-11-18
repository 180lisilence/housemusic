import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { display, window } from '@kit.ArkUI';
import { loadBaseUrl } from '../common/AppConfig';

const DOMAIN = 0x0000;
const TAG = 'HeimaMusic';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    loadBaseUrl(this.context);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 启动页作为入口页面，5 秒后由页面自身跳转首页
    windowStage.loadContent('pages/Splash', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
    });

    this.enableImmersive(windowStage);

    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /** 沉浸式：全屏布局 + 状态栏/导航栏透明，并把安全区高度写入 AppStorage 供页面避让 */
  private enableImmersive(windowStage: window.WindowStage): void {
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true);

      const density: number = display.getDefaultDisplaySync().densityPixels;
      const topArea: window.AvoidArea = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const bottomArea: window.AvoidArea =
        mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      AppStorage.setOrCreate('topSafe', topArea.topRect.height / density);
      AppStorage.setOrCreate('bottomSafe', bottomArea.bottomRect.height / density);

      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#131215',
        statusBarContentColor: '#FFFFFF',
        navigationBarContentColor: '#FFFFFF'
      });
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to enable immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }
}
