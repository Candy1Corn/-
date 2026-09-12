<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { auth, login, logout, ROLE_LABELS, DEMO_CREDENTIALS, type Role } from '$lib/auth';

  let selectedRole: Role = 'doctor';
  let username = '';
  let password = '';
  let submitting = false;
  let errorMessage = '';
  let successMessage = '';
  let redirectTarget = '';

  $: authState = $auth;
  $: redirectTarget = $page.url.searchParams.get('redirect') || '';

  // 根據角色切換時，自動帶入預設範例帳號密碼便於測試
  function handleRoleChange(role: Role) {
    selectedRole = role;
    errorMessage = '';
    successMessage = '';
    const demo = DEMO_CREDENTIALS[role];
    if (demo) {
      username = demo.username;
      password = demo.password || '';
    }
  }

  // 初始化設定
  onMount(() => {
    const demo = DEMO_CREDENTIALS[selectedRole];
    if (demo) {
      username = demo.username;
      password = demo.password || '';
    }
  });

  async function handleLogin() {
    if (!username.trim()) {
      errorMessage = '請輸入帳號或編號！';
      return;
    }

    submitting = true;
    errorMessage = '';
    successMessage = '';

    try {
      const result = await login(selectedRole, username, password);
      if (result.success) {
        successMessage = result.message;
        setTimeout(() => {
          if (redirectTarget) {
            goto(redirectTarget);
          } else {
            // 根據身分跳轉對應首頁
            switch (selectedRole) {
              case 'admin':
                goto('/admin');
                break;
              case 'doctor':
                goto('/doctors');
                break;
              case 'nurse':
                goto('/nurses');
                break;
              case 'patient':
                goto('/patients');
                break;
              default:
                goto('/');
            }
          }
        }, 500);
      } else {
        errorMessage = result.message || '登入失敗，請確認資料無誤';
      }
    } catch (err: any) {
      errorMessage = `登入異常：${err?.message || err}`;
    } finally {
      submitting = false;
    }
  }

  // 快速體驗單鍵登入
  async function quickLogin(role: Role) {
    selectedRole = role;
    const demo = DEMO_CREDENTIALS[role];
    username = demo.username;
    password = demo.password || '';
    await handleLogin();
  }

  async function handleLogout() {
    await logout();
    successMessage = '已成功登出';
    errorMessage = '';
  }
</script>

<svelte:head>
  <title>湯閣牙醫院 - 人員登入系統</title>
</svelte:head>

<main class="login-wrapper">
  {#if authState.isLoggedIn && authState.user}
    <!-- 已登入狀態提示卡片 -->
    <div class="card logged-in-card">
      <div class="avatar-badge">✓</div>
      <h2>您目前已登入</h2>
      <p class="user-desc">
        目前使用者：<strong>{authState.user.name}</strong>（{authState.user.roleName}）
        {#if authState.user.title}
          <span class="sub-title">[{authState.user.title}]</span>
        {/if}
      </p>

      <div class="actions">
        {#if authState.user.role === 'admin'}
          <button class="primary-btn" onclick={() => goto('/admin')}>進入管理員系統</button>
        {:else if authState.user.role === 'doctor'}
          <button class="primary-btn" onclick={() => goto('/doctors')}>進入醫生專區</button>
        {:else if authState.user.role === 'nurse'}
          <button class="primary-btn" onclick={() => goto('/nurses')}>進入護士專區</button>
        {:else}
          <button class="primary-btn" onclick={() => goto('/patients')}>進入病患專區</button>
        {/if}

        <button class="secondary-btn" onclick={handleLogout}>登出帳號</button>
      </div>
    </div>
  {:else}
    <!-- 未登入表單 -->
    <div class="card login-card">
      <h1>湯閣牙醫院</h1>
      <p class="subtitle">醫療業務守衛登入系統</p>

      {#if redirectTarget}
        <div class="alert-banner">
          🔒 您正嘗試造訪受保護的頁面：<code>{redirectTarget}</code>，請先登入具有相應權限的帳號。
        </div>
      {/if}

      <!-- 身分選擇標籤頁 -->
      <div class="role-tabs">
        {#each (['doctor', 'nurse', 'patient', 'admin'] as Role[]) as r}
          <button
            type="button"
            class="tab-btn"
            class:active={selectedRole === r}
            onclick={() => handleRoleChange(r)}
          >
            {#if r === 'doctor'}👨‍⚕️ 醫生
            {:else if r === 'nurse'}👩‍⚕️ 護士
            {:else if r === 'patient'}🧑 病患
            {:else}🛠️ 管理員{/if}
          </button>
        {/each}
      </div>

      <form onsubmit={(e) => { e.preventDefault(); handleLogin(); }}>
        <div class="field">
          <label for="username">
            {#if selectedRole === 'admin'}管理員帳號
            {:else if selectedRole === 'doctor'}醫師姓名 / 編號
            {:else if selectedRole === 'nurse'}護士姓名 / 編號
            {:else}病患姓名 / 病歷號{/if}
          </label>
          <input
            id="username"
            type="text"
            bind:value={username}
            placeholder={selectedRole === 'admin' ? '請輸入 admin' : '請輸入帳號或編號'}
            required
          />
        </div>

        <div class="field">
          <label for="password">密碼</label>
          <input
            id="password"
            type="password"
            bind:value={password}
            placeholder="請輸入密碼"
          />
        </div>

        {#if errorMessage}
          <div class="error-msg">{errorMessage}</div>
        {/if}

        {#if successMessage}
          <div class="success-msg">{successMessage}</div>
        {/if}

        <button type="submit" class="submit-btn" disabled={submitting}>
          {submitting ? '驗證中...' : `以 ${ROLE_LABELS[selectedRole]} 身分登入`}
        </button>
      </form>

      <!-- 快速切換體驗按鈕 -->
      <div class="quick-login-section">
        <div class="divider"><span>快速測試登入</span></div>
        <div class="quick-btns">
          <button type="button" class="quick-btn" onclick={() => quickLogin('doctor')}>
            👨‍⚕️ 醫生 (Doctor)
          </button>
          <button type="button" class="quick-btn" onclick={() => quickLogin('nurse')}>
            👩‍⚕️ 護士 (Nurse)
          </button>
          <button type="button" class="quick-btn" onclick={() => quickLogin('patient')}>
            🧑 病患 (Patient)
          </button>
          <button type="button" class="quick-btn" onclick={() => quickLogin('admin')}>
            🛠️ 管理員 (Admin)
          </button>
        </div>
      </div>
    </div>
  {/if}
</main>

<style>
  .login-wrapper {
    max-width: 500px;
    width: 100%;
    margin: 2rem auto;
    padding: 0 1rem;
    box-sizing: border-box;
  }

  .card {
    background: #ffffff;
    border-radius: 12px;
    padding: 2.2rem 2rem;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08);
    border: 1px solid #eef0f3;
  }

  h1 {
    margin: 0 0 0.2rem 0;
    color: #1a202c;
    font-size: 1.8rem;
    font-weight: bold;
    text-align: center;
  }

  .subtitle {
    margin: 0 0 1.5rem 0;
    color: #718096;
    font-size: 0.95rem;
    text-align: center;
  }

  .alert-banner {
    background: #fff8e6;
    border: 1px solid #ffe199;
    color: #8a5b00;
    padding: 0.75rem 1rem;
    border-radius: 8px;
    font-size: 0.88rem;
    margin-bottom: 1.2rem;
    text-align: left;
    line-height: 1.4;
  }

  .alert-banner code {
    background: #fff0c7;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 0.85rem;
  }

  .role-tabs {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 6px;
    margin-bottom: 1.5rem;
    background: #f1f5f9;
    padding: 4px;
    border-radius: 8px;
  }

  .tab-btn {
    background: transparent;
    border: none;
    padding: 0.5rem 0.2rem;
    border-radius: 6px;
    font-size: 0.85rem;
    color: #475569;
    cursor: pointer;
    transition: all 0.2s;
    font-weight: 500;
  }

  .tab-btn.active {
    background: #ffffff;
    color: #1e40af;
    font-weight: bold;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
  }

  form {
    display: flex;
    flex-direction: column;
    gap: 1.1rem;
    width: 100%;
  }

  .field {
    display: flex;
    flex-direction: column;
    text-align: left;
    gap: 0.35rem;
    width: 100%;
  }

  label {
    font-size: 0.9rem;
    font-weight: 600;
    color: #334155;
    justify-content: flex-start;
  }

  input {
    width: 100%;
    padding: 0.75rem 0.9rem;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    font-size: 0.95rem;
    box-sizing: border-box;
    transition: border-color 0.2s, box-shadow 0.2s;
  }

  input:focus {
    outline: none;
    border-color: #3b82f6;
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
  }

  .submit-btn {
    background: #2563eb;
    color: white;
    border: none;
    padding: 0.8rem;
    border-radius: 6px;
    font-size: 1rem;
    font-weight: 600;
    cursor: pointer;
    transition: background-color 0.2s;
    margin-top: 0.5rem;
    width: 100%;
  }

  .submit-btn:hover {
    background: #1d4ed8;
  }

  .submit-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .error-msg {
    background: #fef2f2;
    color: #dc2626;
    border: 1px solid #fecaca;
    padding: 0.65rem 0.9rem;
    border-radius: 6px;
    font-size: 0.9rem;
    text-align: left;
  }

  .success-msg {
    background: #f0fdf4;
    color: #16a34a;
    border: 1px solid #bbf7d0;
    padding: 0.65rem 0.9rem;
    border-radius: 6px;
    font-size: 0.9rem;
    text-align: left;
  }

  .divider {
    display: flex;
    align-items: center;
    text-align: center;
    margin: 1.8rem 0 1rem 0;
    color: #94a3b8;
    font-size: 0.8rem;
  }

  .divider::before,
  .divider::after {
    content: '';
    flex: 1;
    border-bottom: 1px solid #e2e8f0;
  }

  .divider span {
    padding: 0 0.6rem;
  }

  .quick-btns {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.6rem;
  }

  .quick-btn {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    color: #334155;
    padding: 0.55rem 0.5rem;
    border-radius: 6px;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .quick-btn:hover {
    background: #e2e8f0;
    border-color: #cbd5e1;
    color: #0f172a;
  }

  /* 已登入卡片 */
  .logged-in-card {
    text-align: center;
  }

  .avatar-badge {
    width: 48px;
    height: 48px;
    background: #dcfce7;
    color: #15803d;
    font-size: 1.5rem;
    font-weight: bold;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 1rem auto;
  }

  .user-desc {
    color: #475569;
    font-size: 1.05rem;
    margin-bottom: 1.5rem;
  }

  .sub-title {
    color: #64748b;
    font-size: 0.9rem;
    margin-left: 4px;
  }

  .actions {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    max-width: 280px;
    margin: 0 auto;
  }

  .primary-btn {
    background: #2563eb;
    color: white;
    padding: 0.75rem;
    border-radius: 6px;
    border: none;
    font-weight: 600;
    cursor: pointer;
  }

  .primary-btn:hover {
    background: #1d4ed8;
  }

  .secondary-btn {
    background: #f1f5f9;
    color: #475569;
    padding: 0.75rem;
    border-radius: 6px;
    border: 1px solid #cbd5e1;
    cursor: pointer;
  }

  .secondary-btn:hover {
    background: #e2e8f0;
  }
</style>
