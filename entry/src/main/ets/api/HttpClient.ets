/**
 * 极简 HTTP 客户端（@kit.NetworkKit）
 * 只做三件事：拼接 baseUrl、超时、把响应体读成字符串；错误统一返回 ok=false，由上层回退到本地样本数据。
 */
import http from '@ohos.net.http';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getBaseUrl } from '../common/AppConfig';

export class HttpResult {
  ok: boolean = false;
  body: string = '';
  error: string = '';
  costMs: number = 0;
  code: number = 0;
}

function joinUrl(base: string, path: string): string {
  let b: string = base;
  if (b.endsWith('/')) {
    b = b.substring(0, b.length - 1);
  }
  return b + (path.startsWith('/') ? path : '/' + path);
}

export async function httpGet(path: string, timeoutMs: number = 6000): Promise<HttpResult> {
  const result = new HttpResult();
  const start: number = Date.now();
  let req: http.HttpRequest | undefined = undefined;
  try {
    req = http.createHttp();
    const url: string = joinUrl(getBaseUrl(), path);
    const resp = await req.request(url, {
      method: http.RequestMethod.GET,
      connectTimeout: timeoutMs,
      readTimeout: timeoutMs,
      expectDataType: http.HttpDataType.STRING
    });
    result.code = resp.responseCode;
    result.ok = resp.responseCode >= 200 && resp.responseCode < 300;
    const raw: Object | string | ArrayBuffer = resp.result;
    if (typeof raw === 'string') {
      result.body = raw as string;
    } else {
      result.body = JSON.stringify(raw);
    }
  } catch (e) {
    const err = e as Error;
    result.ok = false;
    result.error = err !== undefined && err.message !== undefined ? err.message : 'request failed';
    hilog.error(0x0000, 'HeimaNet', 'GET %{public}s failed: %{public}s', path, result.error);
    console.error('[HeimaNet] FAIL ' + path + ' : ' + result.error);
  } finally {
    if (req !== undefined) {
      req.destroy();
    }
    result.costMs = Date.now() - start;
  }
  return result;
}
