import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { OrderStore } from '../model/OrderStore';

const TAG = 'EntryAbility';
const DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onCreate');

    // 初始化本地数据存储
    OrderStore.getInstance().init(this.context);

    // 检查是否从碰一碰/深度链接进入，携带拼单ID
    if (want.parameters && want.parameters['orderId']) {
      const orderId = want.parameters['orderId'] as string;
      hilog.info(DOMAIN, TAG, `Launched with orderId: ${orderId}`);
      AppStorage.setOrCreate('pendingOrderId', orderId);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageCreate');
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `loadContent failed: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'loadContent succeeded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'onForeground');
    // 每次回到前台清理过期拼单
    OrderStore.getInstance().cleanExpired();
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'onBackground');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'onNewWant');
    // App已在运行时，通过碰一碰/链接再次唤起
    if (want.parameters && want.parameters['orderId']) {
      const orderId = want.parameters['orderId'] as string;
      hilog.info(DOMAIN, TAG, `onNewWant with orderId: ${orderId}`);
      AppStorage.setOrCreate('pendingOrderId', orderId);
    }
  }
}
