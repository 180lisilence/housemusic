/**
 * 首页 —— 我的页（教材 9.2.6 首页-我的页）
 * 结构：封面图背景 + 个人信息 + 数据统计 + 功能入口 + 我喜欢的音乐（封面宫格）
 */
import { MineMenuType, MineStatType, SongItemType } from '../models/MusicModels';
import { getSongList } from '../api/MusicApi';
import { COLOR_ACCENT, COLOR_SUB, COLOR_TEXT, COLOR_WEAK, SPACE_PAGE } from '../common/Theme';
import { SectionHeader } from '../common/Widgets';
import { gotoPlayer } from '../common/Nav';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Component
export struct MineView {
  @StorageProp('topSafe') topSafe: number = 0;
  @StorageLink('songs') songs: SongItemType[] = [];
  @State stats: MineStatType[] = [
    { label: '关注', value: '16万' },
    { label: '粉丝', value: '10万' },
    { label: '获赞', value: '555' }
  ];
  @State menus: MineMenuType[] = [
    { name: '我的音乐', desc: '128 首本地歌曲', icon: $r('app.media.ic_note') },
    { name: '我收藏的歌单', desc: '12 个歌单', icon: $r('app.media.ic_star') },
    { name: '最近播放', desc: '今天听过 8 首', icon: $r('app.media.ic_clock') },
    { name: '服务器设置', desc: '填写接口地址并自检', icon: $r('app.media.ic_setting') }
  ];

  aboutToAppear(): void {
    getSongList().then((list: SongItemType[]) => {
      this.songs = list;
    });
  }

  private openSettings(): void {
    try {
      router.pushUrl({ url: 'pages/Settings' });
    } catch (err) {
      hilog.error(0x0000, 'HeimaMusic', 'openSettings failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 菜单点击：服务器设置进入设置页；其余为演示入口（待接对应列表页） */
  private openMenu(menu: MineMenuType): void {
    if (menu.name === '服务器设置') {
      try {
        router.pushUrl({ url: 'pages/Settings' });
      } catch (err) {
        hilog.error(0x0000, 'HeimaMusic', 'openMenu pushUrl failed: %{public}s', JSON.stringify(err));
      }
      return;
    }
    // 其余菜单入口待接入对应列表页
  }

  @Builder
  StatItem(stat: MineStatType) {
    Column() {
      Text(stat.value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)
      Text(stat.label)
        .fontSize(11)
        .fontColor(COLOR_SUB)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuRow(menu: MineMenuType) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image(menu.icon)
          .width(16)
          .height(16)
          .fillColor(COLOR_ACCENT)
      }
      .width(30)
      .height(30)
      .borderRadius(15)
      .backgroundColor('#2a1a22')

      Column() {
        Text(menu.name)
          .fontSize(14)
          .fontColor(COLOR_TEXT)
        Text(menu.desc)
          .fontSize(11)
          .fontColor(COLOR_WEAK)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Image($r('app.media.ic_back'))
        .width(11)
        .height(11)
        .fillColor(COLOR_WEAK)
        .rotate({ angle: 180 })
    }
    .width('100%')
    .height(54)
    .alignItems(VerticalAlign.Center)
    .onClick(() => {
      this.openMenu(menu);
    })
  }

  @Builder
  CoverCell(song: SongItemType) {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(song.cover)
          .width('100%')
          .aspectRatio(1)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
        Row() {
          Image($r('app.media.ic_play'))
            .width(7)
            .height(7)
            .fillColor('#ffffff')
          Text((song.id * 37 % 90 + 10).toString() + '万')
            .fontSize(9)
            .fontColor('#ffffff')
            .margin({ left: 2 })
        }
        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        .backgroundColor('#66000000')
        .borderRadius(8)
        .margin({ right: 5, bottom: 5 })
      }

      Text(song.title)
        .fontSize(11)
        .fontColor(COLOR_SUB)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 5 })
        .width('100%')
    }
    .width('23.2%')
    .margin({ bottom: 10 })
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      gotoPlayer(song);
    })
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Image($r('app.media.mine_bg'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Scroll() {
        Column() {
          Row() {
            Text('我的')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLOR_TEXT)
            Blank()
            Row() {
              Image($r('app.media.ic_setting'))
                .width(20)
                .height(20)
                .fillColor(COLOR_TEXT)
            }
            .width(36)
            .height(36)
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.openSettings();
            })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Image($r('app.media.avatar_1'))
              .width(66)
              .height(66)
              .borderRadius(33)
              .border({ width: 2, color: '#4dffffff' })
              .objectFit(ImageFit.Cover)

            Column() {
              Row() {
                Text('黑马听友')
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLOR_TEXT)
                Row() {
                  Image($r('app.media.ic_crown'))
                    .width(9)
                    .height(9)
                    .fillColor('#2a1a22')
                  Text('VIP')
                    .fontSize(9)
                    .fontColor('#2a1a22')
                    .margin({ left: 2 })
                }
                .padding({ left: 5, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
                .backgroundColor(COLOR_ACCENT)
                .margin({ left: 8 })
              }
              .alignItems(VerticalAlign.Center)

              Text('ID: 20261118 · 已听 2,048 分钟')
                .fontSize(11)
                .fontColor(COLOR_SUB)
                .margin({ top: 5 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 14 })
          }
          .width('100%')
          .margin({ top: 18 })
          .alignItems(VerticalAlign.Center)

          Row() {
            ForEach(this.stats, (stat: MineStatType) => {
              this.StatItem(stat)
            }, (stat: MineStatType) => stat.label)
          }
          .width('100%')
          .padding({ top: 16, bottom: 16 })
          .margin({ top: 18 })
          .borderRadius(14)
          .backgroundColor('#33FFFFFF')
          .alignItems(VerticalAlign.Center)

          Column() {
            ForEach(this.menus, (menu: MineMenuType, index: number) => {
              this.MenuRow(menu)
              if (index < this.menus.length - 1) {
                Divider()
                  .strokeWidth(0.5)
                  .color('#1c1c22')
                  .margin({ left: 42 })
              }
            }, (menu: MineMenuType) => menu.name)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 6, bottom: 6 })
          .margin({ top: 16 })
          .borderRadius(14)
          .backgroundColor('#26FFFFFF')
          .alignItems(HorizontalAlign.Start)

          Column() {
            SectionHeader('我喜欢的音乐')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(this.songs, (song: SongItemType) => {
                this.CoverCell(song)
              }, (song: SongItemType) => song.id.toString())
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .margin({ top: 22 })
          .alignItems(HorizontalAlign.Start)

          Column() {
            Image($r('app.media.ic_note'))
              .width(22)
              .height(22)
              .fillColor('#33FFFFFF')
            Text('黑马云音乐 6.0.0')
              .fontSize(11)
              .fontColor('#66FFFFFF')
              .margin({ top: 6 })
          }
          .width('100%')
          .margin({ top: 12, bottom: 14 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .padding({ left: SPACE_PAGE, right: SPACE_PAGE, top: this.topSafe + 10, bottom: 10 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
  }
}
