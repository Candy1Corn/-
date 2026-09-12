import { writable, get } from 'svelte/store';
import { browser } from '$app/environment';

export type Role = 'admin' | 'doctor' | 'nurse' | 'patient';

export interface User {
  id: string | number;
  username: string;
  name: string;
  role: Role;
  roleName: string;
  phone?: string;
  title?: string;
}

export interface AuthState {
  isLoggedIn: boolean;
  user: User | null;
  token: string | null;
}

export const ROLE_LABELS: Record<Role, string> = {
  admin: '管理員',
  doctor: '醫生',
  nurse: '護士',
  patient: '病患'
};

const STORAGE_KEY = 'clinic_auth_session';

// 預設登入者（未登入狀態）
const defaultState: AuthState = {
  isLoggedIn: false,
  user: null,
  token: null
};

// 嘗試從 localStorage 恢復登入狀態
function getInitialState(): AuthState {
  if (!browser) return defaultState;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && parsed.isLoggedIn && parsed.user) {
        return parsed;
      }
    }
  } catch (err) {
    console.error('無法讀取登入 session:', err);
  }
  return defaultState;
}

export const auth = writable<AuthState>(getInitialState());

// 同步持久化至 localStorage
if (browser) {
  auth.subscribe((state) => {
    try {
      if (state.isLoggedIn && state.user) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      } else {
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch (err) {
      console.error('儲存登入 session 失敗:', err);
    }
  });
}

/**
 * 取得當前認證狀態
 */
export function getAuthState(): AuthState {
  return get(auth);
}

/**
 * 預設測試帳號對照表（用於離線或展示體驗）
 */
export const DEMO_CREDENTIALS: Record<Role, { username: string; password?: string; name: string; id: string; title?: string }> = {
  admin: { username: 'admin', password: 'password', name: '王管理員', id: 'A001', title: '系統管理員' },
  doctor: { username: 'doctor', password: 'password', name: '陳醫師', id: 'D1', title: '主任醫師' },
  nurse: { username: 'nurse', password: 'password', name: '林護士', id: 'N1', title: '牙醫助理' },
  patient: { username: 'patient', password: 'password', name: '張病患', id: 'P1' }
};

/**
 * 執行登入程序
 */
export async function login(
  role: Role,
  username: string,
  password?: string
): Promise<{ success: boolean; message: string; user?: User }> {
  const trimmedUser = username.trim();
  if (!trimmedUser) {
    return { success: false, message: '請輸入帳號或編號' };
  }

  // 1. 優先嘗試呼叫後端 API
  try {
    const res = await fetch('http://localhost:7999/api/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role, username: trimmedUser, password: password || '' })
    });

    if (res.ok) {
      const data = await res.json();
      if (data.status === 'success' && data.user) {
        const loggedUser: User = {
          id: data.user.id || '1',
          username: data.user.username || trimmedUser,
          name: data.user.name || trimmedUser,
          role: data.user.role as Role,
          roleName: data.user.roleName || ROLE_LABELS[role],
          phone: data.user.phone,
          title: data.user.title
        };

        auth.set({
          isLoggedIn: true,
          user: loggedUser,
          token: data.token || `token_${Date.now()}`
        });

        return { success: true, message: data.message || '登入成功！', user: loggedUser };
      } else if (data.message) {
        return { success: false, message: data.message };
      }
    }
  } catch (apiErr) {
    console.warn('後端 API 無法連線，使用本地守衛驗證模式:', apiErr);
  }

  // 2. 本地驗證模式 (Fallback 確保前端無後端或離線時亦能完整體驗守衛流程)
  const demo = DEMO_CREDENTIALS[role];
  const user: User = {
    id: trimmedUser === demo.username ? demo.id : `ID-${trimmedUser}`,
    username: trimmedUser,
    name: trimmedUser === demo.username ? demo.name : trimmedUser,
    role,
    roleName: ROLE_LABELS[role],
    title: demo.title
  };

  auth.set({
    isLoggedIn: true,
    user,
    token: `local_token_${role}_${Date.now()}`
  });

  return { success: true, message: `登入成功！歡迎 ${user.name} (${user.roleName})`, user };
}

/**
 * 執行登出程序
 */
export async function logout(): Promise<{ success: boolean; message: string }> {
  try {
    await fetch('http://localhost:7999/api/logout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    });
  } catch {
    // 忽略後端連線中斷
  }

  auth.set({
    isLoggedIn: false,
    user: null,
    token: null
  });

  if (browser) {
    localStorage.removeItem(STORAGE_KEY);
  }

  return { success: true, message: '已成功登出系統' };
}

/**
 * 路由權限檢查結果
 */
export interface RouteAccessResult {
  allowed: boolean;
  redirect?: string;
  reason?: string;
}

/**
 * 守衛判定函式：檢查特定路徑與當前認證狀態是否具備存取權限
 */
export function checkRouteAccess(pathname: string, state: AuthState): RouteAccessResult {
  // 規範化路徑，移除結尾斜線（除非是根路徑）
  const cleanPath = pathname.length > 1 && pathname.endsWith('/') ? pathname.slice(0, -1) : pathname;

  // 公開路徑白名單
  const publicPaths = ['/', '/about', '/login'];
  if (publicPaths.includes(cleanPath)) {
    return { allowed: true };
  }

  // 若未登入，任何後台或功能頁面均拒絕並引導至登入頁
  if (!state.isLoggedIn || !state.user) {
    return {
      allowed: false,
      redirect: `/login?redirect=${encodeURIComponent(cleanPath)}`,
      reason: '請先登入系統後再訪問此頁面！'
    };
  }

  const role = state.user.role;

  // 管理員頁面守衛
  if (cleanPath.startsWith('/admin')) {
    if (role === 'admin') {
      return { allowed: true };
    }
    return {
      allowed: false,
      redirect: '/',
      reason: `權限不足：您目前的身分是「${state.user.roleName}」，無法進入管理員專區！`
    };
  }

  // 醫生專區守衛
  if (cleanPath.startsWith('/doctors')) {
    if (role === 'doctor' || role === 'admin') {
      return { allowed: true };
    }
    return {
      allowed: false,
      redirect: '/',
      reason: `權限不足：您目前的身分是「${state.user.roleName}」，無法進入醫生專區！`
    };
  }

  // 護士專區守衛
  if (cleanPath.startsWith('/nurses')) {
    if (role === 'nurse' || role === 'admin') {
      return { allowed: true };
    }
    return {
      allowed: false,
      redirect: '/',
      reason: `權限不足：您目前的身分是「${state.user.roleName}」，無法進入護士專區！`
    };
  }

  // 病患專區守衛（病患、護士、醫生、管理員皆可檢視或協助）
  if (cleanPath.startsWith('/patients')) {
    if (['patient', 'nurse', 'doctor', 'admin'].includes(role)) {
      return { allowed: true };
    }
    return {
      allowed: false,
      redirect: '/',
      reason: `權限不足：無法訪問病患專區！`
    };
  }

  // 其餘未特別定義之頁面，已登入者允許存取
  return { allowed: true };
}
