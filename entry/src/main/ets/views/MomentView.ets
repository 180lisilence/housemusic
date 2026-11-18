/**
 * 首页 —— 动态页（教材 9.2.5 首页-动态页）
 * 结构：互动广场 + 动态列表（作者 / 内容 / 歌曲卡片 / 点赞评论分享）
 * 说明：卡片与操作行均为视图内 @Builder，事件挂容器级，规避独立 @Component
 *       在 ArkUI-X 下子节点点击事件不转发的问题。
 */
import { MomentItemType } from '../models/MusicModels';
import { getMomentList } from '../api/MusicApi';
import { COLOR_ACCENT, COLOR_CARD, COLOR_SUB, COLOR_TEXT, COLOR_WEAK, SPACE_PAGE } from '../common/Theme';
import { LoadingTip } from '../common/Widgets';
import { gotoPlayer } from '../common/Nav';

@Component
export struct MomentView {
  @StorageProp('topSafe') topSafe: number = 0;
  @StorageLink('moments') moments: MomentItemType[] = [];

  aboutToAppear(): void {
    getMomentList().then((list: MomentItemType[]) => {
      this.moments = list;
    });
  }

  /** 点赞：拷贝数组重新赋值，触发视图刷新；liked 翻转并同步计数 */
  private toggleLike(index: number): void {
    if (index < 0 || index >= this.moments.length) {
      return;
    }
    const list: MomentItemType[] = this.moments.slice();
    const m: MomentItemType = list[index];
    m.liked = !m.liked;
    m.likes = m.liked ? m.likes + 1 : m.likes - 1;
    list[index] = m;
    this.moments = list;
  }

  private onComment(index: number): void {
    // 评论面板待接入
  }

  private onShare(index: number): void {
    // 分享待接入
  }

  @Builder
  MomentCardRow(item: MomentItemType, index: number) {
    Column() {
      Row() {
        Image(item.avatar)
          .width(40)
          .height(40)
          .borderRadius(20)
          .objectFit(ImageFit.Cover)

        Column() {
          Text(item.author)
            .fontSize(13)
            .fontColor(COLOR_SUB)
          Text(item.publishedAt)
            .fontSize(11)
            .fontColor(COLOR_WEAK)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })

        Image($r('app.media.ic_more'))
          .width(18)
          .height(18)
          .fillColor(COLOR_WEAK)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(item.content)
        .fontSize(14)
        .fontColor('#ececf2')
        .lineHeight(21)
        .width('100%')
        .margin({ top: 12 })

      Row() {
        Image(item.song.cover)
          .width(44)
          .height(44)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        Column() {
          Text(item.song.title)
            .fontSize(13)
            .fontColor(COLOR_TEXT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.song.artist)
            .fontSize(11)
            .fontColor(COLOR_WEAK)
            .margin({ top: 3 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })

        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.ic_play'))
            .width(12)
            .height(12)
            .fillColor('#ffffff')
        }
        .width(30)
        .height(30)
        .borderRadius(15)
        .backgroundColor(COLOR_ACCENT)
      }
      .width('100%')
      .padding(10)
      .borderRadius(12)
      .backgroundColor(COLOR_CARD)
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        gotoPlayer(item.song);
      })

      Row() {
        Row() {
          Image($r('app.media.ic_heart'))
            .width(16)
            .height(16)
            .fillColor(item.liked ? COLOR_ACCENT : COLOR_WEAK)
          Text(item.likes.toString())
            .fontSize(12)
            .fontColor(item.liked ? COLOR_ACCENT : COLOR_WEAK)
            .margin({ left: 5 })
        }
        .onClick(() => {
          this.toggleLike(index);
        })

        Row() {
          Image($r('app.media.ic_comment'))
            .width(16)
            .height(16)
            .fillColor(COLOR_WEAK)
          Text(item.comments.toString())
            .fontSize(12)
            .fontColor(COLOR_WEAK)
            .margin({ left: 5 })
        }
        .margin({ left: 26 })
        .onClick(() => {
          this.onComment(index);
        })

        Row() {
          Image($r('app.media.ic_share'))
            .width(15)
            .height(15)
            .fillColor(COLOR_WEAK)
          Text(item.shares.toString())
            .fontSize(12)
            .fontColor(COLOR_WEAK)
            .margin({ left: 5 })
        }
        .margin({ left: 26 })
        .onClick(() => {
          this.onShare(index);
        })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding({ top: 16, bottom: 16 })
    .alignItems(HorizontalAlign.Start)
    .border({ width: { bottom: 0.5 }, color: '#1c1c22' })
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('动态')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
          Blank()
          Row() {
            Image($r('app.media.ic_note'))
              .width(14)
              .height(14)
              .fillColor(COLOR_ACCENT)
            Text('互动广场')
              .fontSize(12)
              .fontColor(COLOR_ACCENT)
              .margin({ left: 4 })
          }
          .padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .borderRadius(14)
          .backgroundColor('#2a1a22')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 4 })

        if (this.moments.length === 0) {
          LoadingTip()
        } else {
          Column() {
            ForEach(this.moments, (item: MomentItemType, index: number) => {
              this.MomentCardRow(item, index)
            }, (item: MomentItemType) => item.id.toString())
          }
          .width('100%')
        }

        Text('已经看到全部动态')
          .fontSize(11)
          .fontColor(COLOR_WEAK)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 16, bottom: 10 })
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
}
