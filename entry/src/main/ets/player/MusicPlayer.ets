/**
 * 跨平台音频播放封装
 *
 * 优先调用系统 AVPlayer（鸿蒙原生 / ArkUI-X 安卓宿主运行时桥接）；
 * 当运行时不提供播放器能力、或歌曲没有可用 url 时，available=false，
 * 调用方回退到页面原有的计时模拟，保证 UI 不崩。
 *
 * AVPlayer 状态机：idle --set url--> initialized --prepare--> prepared --play--> playing。
 * 注意：setDataSource 在桥接层是异步的，必须在 stateChange 收到 initialized 后再 prepare，
 * loop 只能在 prepared/playing/paused/completed 状态设置，否则状态机会抛
 * "Operate Not Permit"。因此本封装按事件驱动推进状态，不做同步连续调用。
 *
 * 回调时间单位统一为「秒」。
 */
import media from '@ohos.multimedia.media';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'HeimaPlayer';
/** prepare 等待超时（毫秒），超时按不可用回退计时模拟 */
const LOAD_TIMEOUT: number = 8000;

export interface PlayerCallbacks {
  onPrepared?: (durationSec: number) => void;
  onPlaying?: () => void;
  onPaused?: () => void;
  onProgress?: (positionSec: number, durationSec: number) => void;
  onCompleted?: () => void;
  onError?: (message: string) => void;
}

export class MusicPlayer {
  private av: media.AVPlayer | null = null;
  private callbacks: PlayerCallbacks;
  private prepared: boolean = false;
  private playing: boolean = false;
  private durationMs: number = 0;
  /** 当前运行时是否具备真实播放能力 */
  available: boolean = true;

  private resolveLoad: ((ok: boolean) => void) | null = null;
  private loadTimer: number = -1;

  constructor(callbacks: PlayerCallbacks) {
    this.callbacks = callbacks;
  }

  /** 加载并准备音频；返回是否可真实播放（false 时调用方走计时模拟） */
  load(url: string): Promise<boolean> {
    this.releaseInternal();
    this.prepared = false;
    this.playing = false;
    this.durationMs = 0;

    if (url === undefined || url === null || url.length === 0) {
      this.available = false;
      return Promise.resolve(false);
    }

    return new Promise<boolean>((resolve: (ok: boolean) => void) => {
      this.resolveLoad = resolve;
      this.loadTimer = setTimeout(() => {
        hilog.error(DOMAIN, TAG, 'load timeout, fallback to timer');
        this.finishLoad(false, 'load timeout');
      }, LOAD_TIMEOUT);

      media.createAVPlayer().then((player: media.AVPlayer) => {
        this.av = player;
        this.bindEvents(player);
        player.url = url;
        // 等待 stateChange(initialized) 后再 prepare，见类头状态机说明。
      }).catch((e: Object) => {
        const msg: string = e !== undefined && (e as Error).message !== undefined
          ? (e as Error).message : 'createAVPlayer failed';
        hilog.error(DOMAIN, TAG, 'createAVPlayer failed: %{public}s', msg);
        this.finishLoad(false, msg);
      });
    });
  }

  private finishLoad(ok: boolean, message: string): void {
    if (this.loadTimer !== -1) {
      clearTimeout(this.loadTimer);
      this.loadTimer = -1;
    }
    if (!ok) {
      this.available = false;
      this.releaseInternal();
      if (this.callbacks.onError) {
        this.callbacks.onError(message);
      }
    }
    const resolver = this.resolveLoad;
    this.resolveLoad = null;
    if (resolver !== null) {
      resolver(ok);
    }
  }

  private bindEvents(player: media.AVPlayer): void {
    player.on('stateChange', (state: string) => {
      if (state === 'initialized') {
        // 数据源已就绪，进入 prepare。
        try {
          player.prepare();
        } catch (e) {
          hilog.error(DOMAIN, TAG, 'prepare call failed');
        }
      } else if (state === 'prepared') {
        this.prepared = true;
        this.durationMs = player.duration > 0 ? player.duration : 0;
        try {
          player.loop = false;
        } catch (e) {
          // 单曲播放不强制循环，忽略循环设置异常。
        }
        this.finishLoad(true, '');
        if (this.callbacks.onPrepared) {
          this.callbacks.onPrepared(this.durationMs / 1000);
        }
      } else if (state === 'playing') {
        this.playing = true;
        if (this.callbacks.onPlaying) {
          this.callbacks.onPlaying();
        }
      } else if (state === 'paused') {
        this.playing = false;
        if (this.callbacks.onPaused) {
          this.callbacks.onPaused();
        }
      } else if (state === 'completed') {
        this.playing = false;
        if (this.callbacks.onCompleted) {
          this.callbacks.onCompleted();
        }
      } else if (state === 'error') {
        this.finishLoad(false, 'player state error');
      }
    });

    player.on('durationUpdate', (dur: number) => {
      if (dur > 0) {
        this.durationMs = dur;
      }
    });

    player.on('timeUpdate', (pos: number) => {
      if (this.callbacks.onProgress) {
        this.callbacks.onProgress(pos / 1000, this.durationMs / 1000);
      }
    });

    player.on('endOfStream', () => {
      this.playing = false;
      if (this.callbacks.onCompleted) {
        this.callbacks.onCompleted();
      }
    });

    player.on('error', (err: Object) => {
      const msg: string = err !== undefined && (err as Error).message !== undefined
        ? (err as Error).message : 'player error';
      this.finishLoad(false, msg);
    });
  }

  play(): void {
    if (this.av === null || !this.prepared) {
      return;
    }
    try {
      this.av.play();
    } catch (e) {
      hilog.error(DOMAIN, TAG, 'play failed');
    }
  }

  pause(): void {
    if (this.av === null) {
      return;
    }
    try {
      this.av.pause();
    } catch (e) {
      // 忽略暂停异常
    }
  }

  seekTo(sec: number): void {
    if (this.av === null) {
      return;
    }
    try {
      this.av.seek(Math.floor(sec * 1000), media.SeekMode.SEEK_NEXT_SYNC);
    } catch (e) {
      // 忽略拖动异常
    }
  }

  getIsPlaying(): boolean {
    return this.playing;
  }

  release(): void {
    if (this.resolveLoad !== null) {
      this.finishLoad(false, 'released');
    }
    this.releaseInternal();
  }

  private releaseInternal(): void {
    if (this.loadTimer !== -1) {
      clearTimeout(this.loadTimer);
      this.loadTimer = -1;
    }
    if (this.av !== null) {
      try {
        this.av.release();
      } catch (e) {
        // 忽略释放异常
      }
      this.av = null;
    }
    this.prepared = false;
    this.playing = false;
  }
}
