/**
 * 黑马云音乐 —— 数据接口层（正式版：真服务器优先，失败回退本地样本）
 *
 * 默认接口（与教材一致，可在设置页改服务器地址）：
 *   GET /swiper         轮播
 *   GET /dailyRecommend 每日推荐
 *   GET /recommendList  推荐歌单
 *   GET /songList       歌曲列表
 *   GET /momentList     动态
 *
 * 兼容多种返回形态：裸数组、{data:[]}、{data:{list:[]}}、{code,data}；
 * 字段也兼容常见别名（title/name/songName、artist/singer、cover/coverUrl/icon、url/audioUrl）。
 */
import {
  DailyRecommendType,
  MomentItemType,
  RecommendListType,
  SongItemType,
  SwiperItemType
} from '../models/MusicModels';
import { getBaseUrl, setDataSource } from '../common/AppConfig';
import { httpGet } from './HttpClient';

const EP_SWIPER: string = '/swiper';
const EP_DAILY: string = '/dailyRecommend';
const EP_PLAYLIST: string = '/recommendList';
const EP_SONG: string = '/songList';
const EP_MOMENT: string = '/momentList';

const MOCK_DELAY: number = 160;

function delay<T>(data: T): Promise<T> {
  return new Promise<T>((resolve: (value: T) => void) => {
    setTimeout(() => {
      resolve(data);
    }, MOCK_DELAY);
  });
}

// ------------------------------------------------------------------ 通用解析

function extractArray(text: string): Object[] {
  try {
    const parsed: Object = JSON.parse(text);
    if (Array.isArray(parsed)) {
      return parsed as Object[];
    }
    const rec = parsed as Record<string, Object>;
    const keys: string[] = ['data', 'list', 'items', 'records', 'result', 'rows'];
    for (let i = 0; i < keys.length; i++) {
      const c: Object | undefined = rec[keys[i]];
      if (c === undefined || c === null) {
        continue;
      }
      if (Array.isArray(c)) {
        return c as Object[];
      }
      const inner = c as Record<string, Object>;
      for (let j = 0; j < keys.length; j++) {
        const cc: Object | undefined = inner[keys[j]];
        if (cc !== undefined && cc !== null && Array.isArray(cc)) {
          return cc as Object[];
        }
      }
    }
  } catch (e) {
    // 非 JSON
  }
  return [];
}

function str(o: Record<string, Object>, keys: string[]): string {
  for (let i = 0; i < keys.length; i++) {
    const v: Object | undefined = o[keys[i]];
    if (v !== undefined && v !== null) {
      const s: string = v.toString();
      if (s.length > 0 && s !== 'undefined') {
        return s;
      }
    }
  }
  return '';
}

function num(o: Record<string, Object>, keys: string[], def: number): number {
  for (let i = 0; i < keys.length; i++) {
    const v: Object | undefined = o[keys[i]];
    if (v !== undefined && v !== null) {
      const n: number = Number(v.toString());
      if (!isNaN(n) && n > 0) {
        return n;
      }
    }
  }
  return def;
}

/** 秒/毫秒/“mm:ss” 统一成秒 */
function seconds(o: Record<string, Object>, keys: string[], def: number): number {
  for (let i = 0; i < keys.length; i++) {
    const v: Object | undefined = o[keys[i]];
    if (v === undefined || v === null) {
      continue;
    }
    const s: string = v.toString();
    if (s.indexOf(':') > 0) {
      const parts: string[] = s.split(':');
      let total: number = 0;
      for (let k = 0; k < parts.length; k++) {
        total = total * 60 + Number(parts[k]);
      }
      if (total > 0) {
        return total;
      }
    }
    let n: number = Number(s);
    if (!isNaN(n) && n > 0) {
      if (n > 10000) {
        n = Math.floor(n / 1000);
      }
      return n;
    }
  }
  return def;
}

function asRec(o: Object): Record<string, Object> {
  return o as Record<string, Object>;
}

// ------------------------------------------------------------------ 各接口

function parseSwipers(text: string): SwiperItemType[] {
  const arr: Object[] = extractArray(text);
  const out: SwiperItemType[] = [];
  for (let i = 0; i < arr.length; i++) {
    const o = asRec(arr[i]);
    const image: string = str(o, ['image', 'imageUrl', 'cover', 'coverUrl', 'pic', 'img', 'url']);
    out.push({
      id: num(o, ['id', 'swiperId'], i + 1),
      title: str(o, ['title', 'name', 'swiperName']),
      subtitle: str(o, ['subtitle', 'desc', 'description', 'summary']),
      image: image.length > 0 ? image : $r('app.media.banner_1')
    } as SwiperItemType);
  }
  return out;
}

function parseDailies(text: string): DailyRecommendType[] {
  const arr: Object[] = extractArray(text);
  const out: DailyRecommendType[] = [];
  for (let i = 0; i < arr.length; i++) {
    const o = asRec(arr[i]);
    const cover: string = str(o, ['cover', 'coverUrl', 'image', 'imageUrl', 'pic', 'img']);
    out.push({
      id: num(o, ['id'], i + 1),
      title: str(o, ['title', 'name']),
      desc: str(o, ['desc', 'subtitle', 'description', 'summary']),
      cover: cover.length > 0 ? cover : $r('app.media.daily_1')
    } as DailyRecommendType);
  }
  return out;
}

function parsePlaylists(text: string): RecommendListType[] {
  const arr: Object[] = extractArray(text);
  const out: RecommendListType[] = [];
  for (let i = 0; i < arr.length; i++) {
    const o = asRec(arr[i]);
    const cover: string = str(o, ['cover', 'coverUrl', 'image', 'imageUrl', 'pic', 'img']);
    let count: string = str(o, ['count', 'playCount', 'play', 'playNum']);
    if (count.length === 0) {
      count = num(o, ['playCount'], 0).toString();
    }
    out.push({
      id: num(o, ['id', 'listId'], i + 1),
      title: str(o, ['title', 'name', 'listName']),
      count: count,
      cover: cover.length > 0 ? cover : $r('app.media.playlist_1')
    } as RecommendListType);
  }
  return out;
}

function parseSongs(text: string): SongItemType[] {
  const arr: Object[] = extractArray(text);
  const out: SongItemType[] = [];
  for (let i = 0; i < arr.length; i++) {
    const o = asRec(arr[i]);
    const cover: string = str(o, ['cover', 'coverUrl', 'image', 'imageUrl', 'pic', 'img']);
    const audio: string = str(o, ['url', 'audioUrl', 'src', 'path', 'audio']);
    out.push(new SongItemType(
      num(o, ['id', 'songId'], i + 1),
      str(o, ['title', 'name', 'songName']),
      str(o, ['artist', 'singer', 'artistName', 'author']),
      cover.length > 0 ? cover : $r('app.media.cover_1'),
      seconds(o, ['duration', 'time', 'length'], 240),
      audio
    ));
  }
  return out;
}

function parseMoments(text: string): MomentItemType[] {
  const arr: Object[] = extractArray(text);
  const out: MomentItemType[] = [];
  for (let i = 0; i < arr.length; i++) {
    const o = asRec(arr[i]);
    const avatar: string = str(o, ['avatar', 'avatarUrl', 'icon', 'head']);
    const songObj: Object | undefined = o['song'];
    let song: SongItemType = new SongItemType(0, '', '', $r('app.media.cover_1'), 240);
    if (songObj !== undefined && songObj !== null) {
      const s = asRec(songObj);
      const sc: string = str(s, ['cover', 'coverUrl', 'image', 'img']);
      const su: string = str(s, ['url', 'audioUrl', 'src', 'path', 'audio']);
      song = new SongItemType(
        num(s, ['id', 'songId'], i + 1),
        str(s, ['title', 'name', 'songName']),
        str(s, ['artist', 'singer']),
        sc.length > 0 ? sc : $r('app.media.cover_1'),
        seconds(s, ['duration', 'time'], 240),
        su
      );
    }
    out.push(new MomentItemType(
      num(o, ['id'], i + 1),
      avatar.length > 0 ? avatar : $r('app.media.avatar_1'),
      str(o, ['author', 'nickname', 'userName', 'name']),
      str(o, ['content', 'text', 'desc']),
      str(o, ['publishedAt', 'time', 'createTime', 'date']),
      song,
      num(o, ['likes', 'likeCount', 'like'], 0),
      num(o, ['comments', 'commentCount', 'comment'], 0),
      num(o, ['shares', 'shareCount', 'share'], 0),
      false
    ));
  }
  return out;
}

// ------------------------------------------------------------------ 本地样本

const SWIPER_LIST: SwiperItemType[] = [
  { id: 1, title: '每日推荐', subtitle: '今天从《逐梦星辰》听起', image: $r('app.media.banner_1') },
  { id: 2, title: '私人漫游', subtitle: '从《彩虹之旅》开启无限漫游', image: $r('app.media.banner_2') },
  { id: 3, title: '华语流行', subtitle: '每日推荐《快乐无界》', image: $r('app.media.banner_3') }
];

const DAILY_LIST: DailyRecommendType[] = [
  { id: 1, title: '每日推荐', desc: '今天从《逐梦星辰》听起！', cover: $r('app.media.daily_1') },
  { id: 2, title: '私人漫游', desc: '从《彩虹之旅》开启无限漫游', cover: $r('app.media.daily_2') },
  { id: 3, title: '华语流行', desc: '每日推荐《快乐无界》', cover: $r('app.media.daily_3') }
];

const RECOMMEND_LIST: RecommendListType[] = [
  { id: 1, title: '深夜慢摇', count: '270.9万', cover: $r('app.media.playlist_1') },
  { id: 2, title: '星际旅途', count: '476.1万', cover: $r('app.media.playlist_2') },
  { id: 3, title: 'City Pop 夜行', count: '188.4万', cover: $r('app.media.playlist_3') },
  { id: 4, title: '启程', count: '92.6万', cover: $r('app.media.playlist_4') },
  { id: 5, title: '雨后电台', count: '133.7万', cover: $r('app.media.playlist_5') },
  { id: 6, title: '慢速呼吸', count: '61.2万', cover: $r('app.media.playlist_6') }
];

const SONG_LIST: SongItemType[] = [
  new SongItemType(1, '逐梦星辰', '云雀合唱团', $r('app.media.cover_1'), 252),
  new SongItemType(2, '彩虹之旅', '林夕', $r('app.media.cover_2'), 228),
  new SongItemType(3, '快乐无界', '黑马乐队', $r('app.media.cover_3'), 245),
  new SongItemType(4, '晚风与海', '陈一', $r('app.media.cover_4'), 212),
  new SongItemType(5, '银河列车', '苏眠', $r('app.media.cover_5'), 266),
  new SongItemType(6, '山与雾', '白昼', $r('app.media.cover_6'), 237),
  new SongItemType(7, '青柠汽水', '小满', $r('app.media.cover_7'), 198),
  new SongItemType(8, '十七号公路', '远方', $r('app.media.cover_8'), 280)
];

const MOMENT_LIST: MomentItemType[] = [
  new MomentItemType(1, $r('app.media.avatar_1'), '阿树', '今天循环了一整天，副歌一响整个人都亮了。', '2 小时前',
    SONG_LIST[0], 1286, 233, 45, false),
  new MomentItemType(2, $r('app.media.avatar_2'), '小满', '通勤路上单曲循环，地铁都坐过站了。', '5 小时前',
    SONG_LIST[6], 864, 102, 18, false),
  new MomentItemType(3, $r('app.media.avatar_3'), '云雀', '把这首放进深夜歌单，闭眼就是星空。', '昨天 22:40',
    SONG_LIST[4], 2031, 356, 88, false),
  new MomentItemType(4, $r('app.media.avatar_4'), '老马', '编曲太克制了，越听越上头。', '昨天 19:12',
    SONG_LIST[7], 512, 61, 9, false)
];

// ------------------------------------------------------------------ 对外接口

/** 轮播图数据 */
export async function getSwiperList(): Promise<SwiperItemType[]> {
  const r = await httpGet(EP_SWIPER);
  if (r.ok) {
    const list: SwiperItemType[] = parseSwipers(r.body);
    if (list.length > 0) {
      setDataSource('remote');
      return list;
    }
  }
  setDataSource('mock');
  return delay<SwiperItemType[]>(SWIPER_LIST);
}

/** 每日推荐数据 */
export async function getDailyRecommend(): Promise<DailyRecommendType[]> {
  const r = await httpGet(EP_DAILY);
  if (r.ok) {
    const list: DailyRecommendType[] = parseDailies(r.body);
    if (list.length > 0) {
      setDataSource('remote');
      return list;
    }
  }
  setDataSource('mock');
  return delay<DailyRecommendType[]>(DAILY_LIST);
}

/** 推荐歌单数据 */
export async function getRecommendList(): Promise<RecommendListType[]> {
  const r = await httpGet(EP_PLAYLIST);
  if (r.ok) {
    const list: RecommendListType[] = parsePlaylists(r.body);
    if (list.length > 0) {
      setDataSource('remote');
      return list;
    }
  }
  setDataSource('mock');
  return delay<RecommendListType[]>(RECOMMEND_LIST);
}

/** 歌曲列表数据 */
export async function getSongList(): Promise<SongItemType[]> {
  const r = await httpGet(EP_SONG);
  if (r.ok) {
    const list: SongItemType[] = parseSongs(r.body);
    if (list.length > 0) {
      setDataSource('remote');
      return list;
    }
  }
  setDataSource('mock');
  return delay<SongItemType[]>(SONG_LIST);
}

/** 动态列表数据 */
export async function getMomentList(): Promise<MomentItemType[]> {
  const r = await httpGet(EP_MOMENT);
  if (r.ok) {
    const list: MomentItemType[] = parseMoments(r.body);
    if (list.length > 0) {
      setDataSource('remote');
      return list;
    }
  }
  setDataSource('mock');
  return delay<MomentItemType[]>(MOMENT_LIST);
}

/** 设置页自检用：返回服务端连通情况 */
export async function probeServer(path: string = EP_SWIPER): Promise<string> {
  const r = await httpGet(path, 5000);
  if (r.ok) {
    return '连通 · HTTP ' + r.code + ' · ' + r.costMs + 'ms · ' + r.body.length + ' 字节';
  }
  return '失败 · ' + (r.error.length > 0 ? r.error : ('HTTP ' + r.code));
}

export function currentBaseUrl(): string {
  return getBaseUrl();
}
