<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';
	import { auth, logout, checkRouteAccess } from '$lib/auth';
	import { page } from '$app/stores';
	import { goto, beforeNavigate } from '$app/navigation';
	import { browser } from '$app/environment';

	let { children } = $props();

	// 守衛狀態
	let isRouteAllowed = $state(true);
	let guardReason = $state('');

	// 提示訊息 (Toast notification)
	let toastMsg = $state('');
	let toastType = $state<'info' | 'error' | 'success'>('info');
	let toastTimeout: any = null;

	// 深色模式
	let isDarkMode = $state(false);

	if (browser) {
		const saved = localStorage.getItem('theme');
		isDarkMode = saved
			? saved === 'dark'
			: window.matchMedia('(prefers-color-scheme: dark)').matches;
	}

	$effect(() => {
		if (!browser) return;
		document.documentElement.classList.toggle('dark', isDarkMode);
		localStorage.setItem('theme', isDarkMode ? 'dark' : 'light');
	});

	function toggleDarkMode() {
		isDarkMode = !isDarkMode;
	}

	function showNotification(msg: string, type: 'info' | 'error' | 'success' = 'info') {
		toastMsg = msg;
		toastType = type;
		if (toastTimeout) clearTimeout(toastTimeout);
		toastTimeout = setTimeout(() => {
			toastMsg = '';
		}, 3000);
	}

	// 路由守衛 1：攔截客戶端點擊跳轉 (beforeNavigate)
	beforeNavigate(({ to, cancel }) => {
		if (!to) return;
		const targetPath = to.url.pathname;
		const access = checkRouteAccess(targetPath, $auth);

		if (!access.allowed) {
			cancel();
			if (access.reason) {
				showNotification(access.reason, 'error');
			}
			if (access.redirect) {
				goto(access.redirect);
			}
		}
	});

	// 路由守衛 2：頁面載入/直連網址/狀態變更檢查 ($effect)
	$effect(() => {
		const currentPath = $page.url.pathname;
		const access = checkRouteAccess(currentPath, $auth);
		isRouteAllowed = access.allowed;
		guardReason = access.reason || '';

		if (browser && !access.allowed && access.redirect) {
			if (access.reason) {
				showNotification(access.reason, 'error');
			}
			goto(access.redirect);
		}
	});

	// 登出處理函式
	async function handleLogout(e?: Event) {
		if (e) e.preventDefault();

		if (!$auth.isLoggedIn) {
			showNotification('目前尚未登入！', 'info');
			return;
		}

		const userName = $auth.user?.name || $auth.user?.username || '使用者';
		const confirmOut = confirm(`確定要登出帳號「${userName}」嗎？`);
		if (confirmOut) {
			const res = await logout();
			showNotification(res.message || '已成功登出系統', 'success');
			goto('/login');
		}
	}
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<!-- 頂部浮動通知訊息 -->
{#if toastMsg}
	<div class="toast-banner {toastType}">
		{toastMsg}
	</div>
{/if}

<nav>
	<a href="/">home</a><p></p>
	<a href="/about">about</a><p></p>
	<button
		type="button"
		class="theme-toggle-btn"
		onclick={toggleDarkMode}
		title={isDarkMode ? '切換為淺色模式' : '切換為深色模式'}
		aria-label="切換深色模式"
	>
		{isDarkMode ? '☀️' : '🌙'}
	</button>
	<p></p>
	{#if !$auth.isLoggedIn}
		<a href="/login">log in</a><p></p>
		<button type="button" class="nav-logout-btn" onclick={handleLogout} title="登出系統">log out</button>
	{:else}
		<span class="nav-user-status">
			👤 {$auth.user?.name}
			<span class="badge-role">{$auth.user?.roleName}</span>
		</span>
		<p></p>
		<button type="button" class="nav-logout-btn is-logged-in" onclick={handleLogout} title="點擊登出">log out</button>
	{/if}
</nav>

<!-- 守衛受限防護區塊：若無存取權限則阻擋內容呈現 -->
{#if isRouteAllowed}
	{@render children?.()}
{:else}
	<div class="guard-barrier">
		<div class="guard-card">
			<div class="guard-icon">🔒</div>
			<h2>存取受限</h2>
			<p>{guardReason || '您尚未登入或無權限檢視此頁面，系統正為您跳轉至登入頁面...'}</p>
			<div class="guard-actions">
				<a href="/login" class="guard-btn-login">立即前往登入</a>
				<a href="/" class="guard-btn-home">返回首頁</a>
			</div>
		</div>
	</div>
{/if}

<style>
  nav {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 1em;
    padding: 0.8rem 1.5rem;
    position: relative;
    z-index: 10;
  }

  nav:hover {
    box-shadow: 0 0 10px rgb(168, 168, 168);
    transition: all 0.2s ease-in-out;
  }

  nav a {
    text-decoration: none;
    color: var(--link, #1c7ed4);
    font-weight: 500;
  }

  nav a:hover {
    color: var(--link-hover, #3492e5);
  }

  .theme-toggle-btn {
    background: transparent;
    border: none;
    font-size: 1.2rem;
    line-height: 1;
    cursor: pointer;
    padding: 0.2rem 0.4rem;
    border-radius: 4px;
    transition: background 0.2s;
  }

  .theme-toggle-btn:hover {
    background: var(--bg-2, #e0e6eb);
  }

  .nav-logout-btn {
    background: transparent;
    border: none;
    color: var(--link, #1c7ed4);
    font-size: inherit;
    font-family: inherit;
    cursor: pointer;
    padding: 0;
    margin: 0;
    font-weight: 500;
    transition: color 0.2s;
  }

  .nav-logout-btn:hover {
    color: #e11d48;
    text-decoration: underline;
  }

  .nav-logout-btn.is-logged-in {
    color: #e11d48;
    background: #ffe4e6;
    padding: 0.25rem 0.6rem;
    border-radius: 4px;
    font-size: 0.9rem;
    font-weight: 600;
  }

  .nav-logout-btn.is-logged-in:hover {
    background: #fecdd3;
    text-decoration: none;
  }

  .nav-user-status {
    font-size: 0.9rem;
    color: #334155;
    background: #f1f5f9;
    padding: 0.25rem 0.6rem;
    border-radius: 4px;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
  }

  .badge-role {
    background: #2563eb;
    color: #ffffff;
    font-size: 0.75rem;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: 600;
  }

  /* 浮動提示 Toast */
  .toast-banner {
    position: fixed;
    top: 1.2rem;
    left: 50%;
    transform: translateX(-50%);
    z-index: 9999;
    padding: 0.6rem 1.4rem;
    border-radius: 8px;
    font-size: 0.95rem;
    font-weight: 600;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
    animation: fadeInDown 0.25s ease-out;
  }

  .toast-banner.info {
    background: #eff6ff;
    color: #1e40af;
    border: 1px solid #bfdbfe;
  }

  .toast-banner.error {
    background: #fef2f2;
    color: #b91c1c;
    border: 1px solid #fecaca;
  }

  .toast-banner.success {
    background: #f0fdf4;
    color: #15803d;
    border: 1px solid #bbf7d0;
  }

  @keyframes fadeInDown {
    from {
      opacity: 0;
      transform: translate(-50%, -10px);
    }
    to {
      opacity: 1;
      transform: translate(-50%, 0);
    }
  }

  /* 守衛阻擋提示卡片 */
  .guard-barrier {
    display: flex;
    justify-content: center;
    align-items: center;
    min-height: 50vh;
    padding: 2rem;
  }

  .guard-card {
    background: white;
    border: 1px solid #e2e8f0;
    border-radius: 12px;
    padding: 2.5rem 2rem;
    max-width: 440px;
    text-align: center;
    box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  }

  .guard-icon {
    font-size: 2.8rem;
    margin-bottom: 0.8rem;
  }

  .guard-card h2 {
    color: #1e293b;
    margin-bottom: 0.5rem;
  }

  .guard-card p {
    color: #64748b;
    font-size: 0.95rem;
    line-height: 1.5;
    margin-bottom: 1.5rem;
  }

  .guard-actions {
    display: flex;
    justify-content: center;
    gap: 0.8rem;
  }

  .guard-btn-login {
    background: #2563eb;
    color: white;
    padding: 0.6rem 1.2rem;
    border-radius: 6px;
    text-decoration: none;
    font-weight: 600;
  }

  .guard-btn-home {
    background: #f1f5f9;
    color: #475569;
    padding: 0.6rem 1.2rem;
    border-radius: 6px;
    text-decoration: none;
    font-weight: 500;
  }
</style>