/**
 * 首页 —— 推荐页（教材 9.2.3 首页-推荐页）
 * 结构：搜索区域 / 轮播图区域 / 每日推荐 / 推荐歌单
 */
import { DailyRecommendType, RecommendListType, SongItemType, SwiperItemType } from '../models/MusicModels';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getDailyRecommend, getRecommendList, getSongList, getSwiperList } from '../api/MusicApi';
import { COLOR_ACCENT, COLOR_TEXT, COLOR_WEAK, SPACE_PAGE } from '../common/Theme';
import { LoadingTip, SearchBar, SectionHeader } from '../common/Widgets';
import { gotoPlayer } from '../common/Nav';
import { router } from '@kit.ArkUI';

@Component
export struct RecommendView {
  @StorageProp('topSafe') topSafe: number = 0;
  @StorageProp('dataSource') dataSource: string = 'unknown';
  @StorageLink('swipers') swipers: SwiperItemType[] = [];
  @StorageLink('dailies') dailies: DailyRecommendType[] = [];
  @StorageLink('playlists') playlists: RecommendListType[] = [];
  @StorageLink('songs') songs: SongItemType[] = [];
  @State loaded: boolean = false;

  private started: boolean = false;

  private ensureLoad(): void {
    if (this.started) {
      return;
    }
    this.started = true;
    getSwiperList().then((list: SwiperItemType[]) => {
      this.swipers = list;
      this.loaded = true;
    });
    getDailyRecommend().then((list: DailyRecommendType[]) => {
      this.dailies = list;
    });
    getRecommendList().then((list: RecommendListType[]) => {
      this.playlists = list;
    });
    getSongList().then((list: SongItemType[]) => {
      this.songs = list;
    });
  }

  /**
   * 按下标取歌播放。
   * 轮播 / 推荐歌单：卡片 id 与歌曲 id 对齐，下标 = id - 1；
   * 每日推荐：卡片封面与文案对应下一首（id+1），下标 = id，调用方按各自约定传入。
   */
  private playByIndex(index: number): void {
    if (this.songs.length === 0) {
      return;
    }
    const song: SongItemType = this.songs[index % this.songs.length];
    gotoPlayer(song);
  }

  private openSettings(): void {
    try {
      router.pushUrl({ url: 'pages/Settings' });
    } catch (err) {
      hilog.error(0x0000, 'HeimaMusic', 'openSettings failed: %{public}s', JSON.stringify(err));
    }
  }

  @Builder
  HeaderArea() {
    Column() {
      Row() {
        Column() {
          Text('黑马云音乐')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
          Text(this.dataSource === 'remote' ? '远程数据 · 已连接服务器' : '本地演示数据（未连接服务器）')
            .fontSize(12)
            .fontColor(COLOR_WEAK)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Image($r('app.media.ic_crown'))
          .width(20)
          .height(20)
          .fillColor(COLOR_ACCENT)
        Row() {
          Image($r('app.media.ic_setting'))
            .width(20)
            .height(20)
            .fillColor(COLOR_TEXT)
        }
        .width(36)
        .height(36)
        .margin({ left: 14 })
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.openSettings();
        })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ top: 6, bottom: 12 })

      SearchBar('搜索歌曲')
    }
    .padding({ left: SPACE_PAGE, right: SPACE_PAGE })
  }

  @Builder
  SwiperArea() {
    Swiper() {
      ForEach(this.swipers, (item: SwiperItemType) => {
        Image(item.image)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(14)
          .onClick(() => {
            this.playByIndex(item.id - 1);
          })
      }, (item: SwiperItemType) => item.id.toString())
    }
    .width('100%')
    .height(176)
    .autoPlay(true)
    .interval(3800)
    .loop(true)
    .indicator(new DotIndicator().color('#66FFFFFF').selectedColor(COLOR_ACCENT).bottom(10))
    .padding({ left: SPACE_PAGE, right: SPACE_PAGE })
    .margin({ top: 14 })
  }

  @Builder
  DailyArea() {
    Column() {
      SectionHeader('每日推荐')
      Row({ space: 10 }) {
        ForEach(this.dailies, (item: DailyRecommendType) => {
          Column() {
            Image(item.cover)
              .width('100%')
              .aspectRatio(1)
              .borderRadius(12)
              .objectFit(ImageFit.Cover)
            Text(item.title)
              .fontSize(13)
              .fontColor(COLOR_TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 7 })
            Text(item.desc)
              .fontSize(11)
              .fontColor(COLOR_WEAK)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .onClick(() => {
            this.playByIndex(item.id);
          })
        }, (item: DailyRecommendType) => item.id.toString())
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .margin({ top: 12 })
    }
    .padding({ left: SPACE_PAGE, right: SPACE_PAGE })
    .margin({ top: 22 })
    .alignItems(HorizontalAlign.Start)
    .visibility(this.dailies.length > 0 ? Visibility.Visible : Visibility.None)
  }

  @Builder
  RecommendListArea() {
    Column() {
      SectionHeader('推荐歌单')
      List({ space: 12 }) {
        ForEach(this.playlists, (item: RecommendListType) => {
          ListItem() {
            Column() {
              Stack({ alignContent: Alignment.TopEnd }) {
                Image(item.cover)
                  .width(132)
                  .height(132)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover)
                Row() {
                  Image($r('app.media.ic_play'))
                    .width(8)
                    .height(8)
                    .fillColor('#ffffff')
                  Text(item.count)
                    .fontSize(10)
                    .fontColor('#ffffff')
                    .margin({ left: 3 })
                }
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor('#66000000')
                .borderRadius(9)
                .margin({ top: 6, right: 6 })
              }

              Text(item.title)
                .fontSize(13)
                .fontColor(COLOR_TEXT)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 7 })
                .width(132)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .onClick(() => {
            this.playByIndex(item.id - 1);
          })
        }, (item: RecommendListType) => item.id.toString())
      }
      .width('100%')
      .height(178)
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ top: 12 })
    }
    .padding({ left: SPACE_PAGE, right: SPACE_PAGE })
    .margin({ top: 22 })
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Scroll() {
      Column() {
        this.HeaderArea()

        if (this.swipers.length > 0) {
          this.SwiperArea()
        } else {
          LoadingTip()
        }

        this.DailyArea()
        this.RecommendListArea()

        Text('已经到底啦，去「发现」找更多好歌')
          .fontSize(11)
          .fontColor(COLOR_WEAK)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 22, bottom: 12 })
      }
      .width('100%')
      .padding({ top: this.topSafe + 6, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .onAppear(() => {
      this.ensureLoad();
    })
  }
}
