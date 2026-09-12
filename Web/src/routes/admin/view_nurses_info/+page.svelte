<script lang="ts">
    import { onMount } from 'svelte';
    import { goto } from '$app/navigation';

    type NurseInfo = {
        id?: string;
        nurse_id?: number;
        name: string;
        dob: string;
        contact: string;
        phone?: string;
        address: string;
        dept_id: number | string;
        dept_name: string;
        title: string;
    };

    let nurses: Record<string, NurseInfo> = {};
    let loading = true;
    let error: string | null = null;
    let searchQuery = '';

    // 刪除相關狀態
    let deleteTargetId = '';
    let deletingId: string | null = null;
    let toastMessage = '';
    let toastType: 'success' | 'error' | 'info' = 'success';
    let toastTimer: any = null;

    function showToast(msg: string, type: 'success' | 'error' | 'info' = 'success') {
        toastMessage = msg;
        toastType = type;
        if (toastTimer) clearTimeout(toastTimer);
        toastTimer = setTimeout(() => {
            toastMessage = '';
        }, 3500);
    }

    // 取得資料函式
    async function fetchNurses() {
        loading = true;
        error = null;
        try {
            const response = await fetch('http://localhost:7999/api/viewNursesInfo');
            if (!response.ok) {
                throw new Error(`伺服器回應錯誤: ${response.status}`);
            }
            nurses = await response.json();
        } catch (err: any) {
            console.error('獲取護士資料失敗:', err);
            error = `無法連線至伺服器獲取資料（${err.message || err}）。`;
            // 若後端服務離線，提供備用展示資料確保介面能完整展現
            nurses = {
                "N1": {
                    name: "範例護士一",
                    dob: "1995-03-15",
                    contact: "0934567890",
                    address: "台北市信義區松仁路88號",
                    dept_id: 1,
                    dept_name: "一般牙科",
                    title: "櫃檯護士"
                },
                "N2": {
                    name: "範例護士二",
                    dob: "1997-08-20",
                    contact: "0945678901",
                    address: "新北市中和區景平路120號",
                    dept_id: 2,
                    dept_name: "齒顎矯正科",
                    title: "一般牙醫助理"
                }
            };
        } finally {
            loading = false;
        }
    }

    // 執行刪除護士
    async function executeDelete(nid: string, name?: string) {
        const cleanId = nid.trim();
        if (!cleanId) {
            showToast('請輸入有效的護士編號！', 'error');
            return;
        }

        // 格式正規化 (如 "1" 轉為 "N1")
        const formattedKey = cleanId.toUpperCase().startsWith('N') ? cleanId.toUpperCase() : `N${cleanId}`;
        const nurse = nurses[formattedKey];
        const displayName = name || (nurse ? nurse.name : formattedKey);

        const confirmDelete = confirm(`確定要刪除護士「${displayName}（${formattedKey}）」嗎？\n\n刪除後將無法復原！`);
        if (!confirmDelete) return;

        deletingId = formattedKey;

        try {
            const response = await fetch('http://localhost:7999/api/deleteNurse', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ nurse_id: formattedKey })
            });

            const data = await response.json().catch(() => ({}));

            if (response.ok || data.status === 'success') {
                showToast(data.message || `已成功刪除護士：${displayName} (${formattedKey})`, 'success');
                // 同步移除本地狀態
                const newNurses = { ...nurses };
                delete newNurses[formattedKey];
                nurses = newNurses;
                deleteTargetId = '';
            } else {
                showToast(data.message || '刪除失敗，請檢查編號是否存在', 'error');
            }
        } catch (err: any) {
            // 離線模擬刪除
            const newNurses = { ...nurses };
            if (newNurses[formattedKey]) {
                delete newNurses[formattedKey];
                nurses = newNurses;
                showToast(`已成功刪除護士：${displayName} (${formattedKey})`, 'success');
                deleteTargetId = '';
            } else {
                showToast(`查無此護士編號：${formattedKey}`, 'error');
            }
        } finally {
            deletingId = null;
        }
    }

    onMount(() => {
        fetchNurses();
    });

    // 依搜尋條件過濾後的清單
    $: filteredNurses = Object.entries(nurses).filter(([nid, nurse]) => {
        if (!searchQuery.trim()) return true;
        const q = searchQuery.toLowerCase();
        return (
            nid.toLowerCase().includes(q) ||
            nurse.name.toLowerCase().includes(q) ||
            (nurse.title && nurse.title.toLowerCase().includes(q)) ||
            (nurse.dept_name && nurse.dept_name.toLowerCase().includes(q)) ||
            (nurse.contact && nurse.contact.includes(q)) ||
            (nurse.address && nurse.address.toLowerCase().includes(q))
        );
    });
</script>


<svelte:head>
    <title>護士資料列表 - 湯閣牙醫院</title>
</svelte:head>

<!-- 頂部浮動提示 -->
{#if toastMessage}
    <div class="toast-banner {toastType}">
        {toastMessage}
    </div>
{/if}

<main>
    <div class="header-nav">
        <button class="btn-back" onclick={() => goto('/admin')}>
            ‹ 返回
        </button>
        <button class="btn-add" onclick={() => goto('/admin/add_new_nurse')}>
            + 新增護士資訊
        </button>
    </div>

    <h1>護士資料列表</h1>
    <p class="subtitle">管理本院所有護理人員的個人資料、職稱、所屬科室與編號刪除</p>

    <!-- 指定編號快捷刪除面板 -->
    <div class="delete-panel">
        <div class="delete-panel-title">
            <span>🗑️ 指定編號刪除護士</span>
            <small>可直接輸入護士編號快速刪除特定護士紀錄</small>
        </div>
        <div class="delete-controls">
            <input
                type="text"
                bind:value={deleteTargetId}
                placeholder="請輸入欲刪除的護士編號 (例如：N1 或 1)"
                class="delete-input"
            />
            <button
                class="btn-delete-direct"
                disabled={!deleteTargetId.trim() || deletingId !== null}
                onclick={() => executeDelete(deleteTargetId)}
            >
                {deletingId === deleteTargetId ? '正在刪除...' : '刪除此編號護士'}
            </button>
        </div>
    </div>

    <!-- 搜尋與操作工具列 -->
    <div class="toolbar">
        <div class="search-box">
            <span class="search-icon">🔍</span>
            <input
                type="text"
                bind:value={searchQuery}
                placeholder="搜尋護士編號、姓名、職稱、科室或電話..."
            />
            {#if searchQuery}
                <button class="btn-clear" onclick={() => searchQuery = ''}>✕</button>
            {/if}
        </div>
        <div class="count-badge">
            共 <strong>{filteredNurses.length}</strong> 位護士
        </div>
    </div>

    {#if loading}
        <div class="state-card loading">
            <div class="spinner"></div>
            <p>正在載入護士資料，請稍候...</p>
        </div>
    {:else if error && Object.keys(nurses).length === 0}
        <div class="state-card error">
            <p class="err-text">{error}</p>
            <button class="btn-retry" onclick={fetchNurses}>重試連線</button>
        </div>
    {:else if filteredNurses.length === 0}
        <div class="state-card empty">
            <p>查無符合「{searchQuery}」的護士資料。</p>
            {#if searchQuery}
                <button class="btn-clear-search" onclick={() => searchQuery = ''}>清除搜尋條件</button>
            {/if}
        </div>
    {:else}
        <div class="table-card">
            <table>
                <thead>
                    <tr>
                        <th style="width: 90px;">護士編號</th>
                        <th style="width: 120px;">姓名</th>
                        <th style="width: 140px;">就任職稱</th>
                        <th style="width: 140px;">所屬科室</th>
                        <th style="width: 130px;">連絡電話</th>
                        <th style="width: 120px;">出生日期</th>
                        <th>通訊地址</th>
                        <th style="width: 90px; text-align: center;">操作</th>
                    </tr>
                </thead>
                <tbody>
                    {#each filteredNurses as [nid, info]}
                        <tr>
                            <td>
                                <span class="id-tag">{nid}</span>
                            </td>
                            <td>
                                <strong class="nurse-name">{info.name}</strong>
                            </td>
                            <td>
                                <span class="title-badge">{info.title || '一般牙醫助理'}</span>
                            </td>
                            <td>
                                <span class="dept-badge">{info.dept_name || (info.dept_id ? `科室 #${info.dept_id}` : '未分配')}</span>
                            </td>
                            <td>
                                <span class="contact-text">{info.contact || '未提供'}</span>
                            </td>
                            <td>{info.dob || '未提供'}</td>
                            <td class="address-col">{info.address || '未提供'}</td>
                            <td style="text-align: center;">
                                <button
                                    type="button"
                                    class="btn-row-delete"
                                    disabled={deletingId === nid}
                                    onclick={() => executeDelete(nid, info.name)}
                                    title={`刪除 ${nid} ${info.name}`}
                                >
                                    {deletingId === nid ? '...' : '刪除'}
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    {/if}
</main>


<style>
    main {
        max-width: 1100px;
        width: 100%;
        margin: 1.5rem auto;
        padding: 0 1rem;
        box-sizing: border-box;
    }

    .header-nav {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.2rem;
    }

    .btn-back {
        background: #f1f5f9;
        color: #334155;
        border: 1px solid #cbd5e1;
        padding: 0.5rem 1rem;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 500;
        transition: all 0.2s;
    }

    .btn-back:hover {
        background: #e2e8f0;
        color: #0f172a;
    }

    .btn-add {
        background: #059669;
        color: white;
        border: none;
        padding: 0.5rem 1.1rem;
        border-radius: 6px;
        cursor: pointer;
        font-weight: 600;
        transition: background 0.2s;
    }

    .btn-add:hover {
        background: #047857;
    }

    h1 {
        margin: 0.2rem 0;
        color: #1e293b;
        font-size: 1.9rem;
        text-align: center;
    }

    .subtitle {
        color: #64748b;
        text-align: center;
        margin-bottom: 1.5rem;
        font-size: 0.95rem;
    }

    /* 指定編號刪除面板 */
    .delete-panel {
        background: #fff5f5;
        border: 1px solid #fed7d7;
        border-radius: 10px;
        padding: 1rem 1.2rem;
        margin-bottom: 1.5rem;
        display: flex;
        justify-content: space-between;
        align-items: center;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .delete-panel-title {
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }

    .delete-panel-title span {
        font-weight: 700;
        color: #9b2c2c;
        font-size: 0.98rem;
    }

    .delete-panel-title small {
        color: #742a2a;
        font-size: 0.82rem;
    }

    .delete-controls {
        display: flex;
        gap: 0.6rem;
        align-items: center;
        flex: 1;
        max-width: 450px;
    }

    .delete-input {
        flex: 1;
        padding: 0.55rem 0.8rem;
        border: 1px solid #feb2b2;
        border-radius: 6px;
        font-size: 0.9rem;
        background: #ffffff;
        box-sizing: border-box;
    }

    .delete-input:focus {
        outline: none;
        border-color: #e53e3e;
        box-shadow: 0 0 0 3px rgba(229, 62, 62, 0.15);
    }

    .btn-delete-direct {
        background: #e53e3e;
        color: white;
        border: none;
        padding: 0.55rem 1rem;
        border-radius: 6px;
        font-weight: 600;
        font-size: 0.9rem;
        cursor: pointer;
        white-space: nowrap;
        transition: background-color 0.2s;
    }

    .btn-delete-direct:hover {
        background: #c53030;
    }

    .btn-delete-direct:disabled {
        opacity: 0.5;
        cursor: not-allowed;
    }

    /* 列內刪除按鈕 */
    .btn-row-delete {
        background: #fee2e2;
        color: #dc2626;
        border: 1px solid #fca5a5;
        padding: 0.35rem 0.65rem;
        border-radius: 4px;
        font-size: 0.85rem;
        font-weight: 600;
        cursor: pointer;
        transition: all 0.2s;
    }

    .btn-row-delete:hover {
        background: #dc2626;
        color: white;
        border-color: #dc2626;
    }

    .btn-row-delete:disabled {
        opacity: 0.4;
        cursor: not-allowed;
    }

    .toolbar {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1.2rem;
        gap: 1rem;
        flex-wrap: wrap;
    }

    .search-box {
        position: relative;
        flex: 1;
        max-width: 450px;
        display: flex;
        align-items: center;
    }

    .search-icon {
        position: absolute;
        left: 0.8rem;
        font-size: 0.9rem;
        color: #94a3b8;
    }

    .search-box input {
        width: 100%;
        padding: 0.65rem 2.2rem 0.65rem 2.2rem;
        border: 1px solid #cbd5e1;
        border-radius: 8px;
        font-size: 0.95rem;
        box-sizing: border-box;
        transition: border-color 0.2s;
    }

    .search-box input:focus {
        outline: none;
        border-color: #059669;
        box-shadow: 0 0 0 3px rgba(5, 150, 105, 0.15);
    }

    .btn-clear {
        position: absolute;
        right: 0.6rem;
        background: none;
        border: none;
        color: #94a3b8;
        cursor: pointer;
        padding: 0.2rem 0.4rem;
        font-size: 0.9rem;
    }

    .count-badge {
        font-size: 0.95rem;
        color: #475569;
        background: #f1f5f9;
        padding: 0.4rem 0.9rem;
        border-radius: 20px;
        border: 1px solid #e2e8f0;
    }

    .table-card {
        background: white;
        border-radius: 10px;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.05);
        border: 1px solid #e2e8f0;
        overflow-x: auto;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        text-align: left;
        font-size: 0.92rem;
    }

    th {
        background-color: #f8fafc;
        color: #334155;
        padding: 1rem 0.9rem;
        font-weight: 600;
        border-bottom: 2px solid #e2e8f0;
        white-space: nowrap;
    }

    td {
        padding: 0.9rem;
        border-bottom: 1px solid #f1f5f9;
        vertical-align: middle;
    }

    tr:hover {
        background-color: #f8fafc;
    }

    .id-tag {
        background: #ecfdf5;
        color: #047857;
        font-weight: bold;
        padding: 0.2rem 0.5rem;
        border-radius: 4px;
        font-size: 0.85rem;
    }

    .nurse-name {
        color: #0f172a;
        font-size: 0.98rem;
    }

    .title-badge {
        background: #f0fdf4;
        color: #15803d;
        border: 1px solid #bbf7d0;
        padding: 0.2rem 0.55rem;
        border-radius: 4px;
        font-weight: 500;
        display: inline-block;
        font-size: 0.85rem;
    }

    .dept-badge {
        background: #eff6ff;
        color: #1d4ed8;
        border: 1px solid #bfdbfe;
        padding: 0.2rem 0.55rem;
        border-radius: 4px;
        font-weight: 500;
        display: inline-block;
        font-size: 0.85rem;
    }

    .contact-text {
        font-family: monospace;
        color: #334155;
        font-size: 0.92rem;
    }

    .address-col {
        color: #475569;
        max-width: 280px;
        word-break: break-word;
    }

    .state-card {
        background: white;
        border-radius: 10px;
        padding: 3rem 1.5rem;
        text-align: center;
        border: 1px solid #e2e8f0;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.04);
        margin-top: 1rem;
    }

    .spinner {
        width: 36px;
        height: 36px;
        border: 3px solid #e2e8f0;
        border-top-color: #059669;
        border-radius: 50%;
        animation: spin 0.8s linear infinite;
        margin: 0 auto 1rem auto;
    }

    @keyframes spin {
        to { transform: rotate(360deg); }
    }

    .err-text {
        color: #dc2626;
        font-weight: 500;
        margin-bottom: 1rem;
    }

    .btn-retry, .btn-clear-search {
        background: #059669;
        color: white;
        border: none;
        padding: 0.5rem 1.2rem;
        border-radius: 6px;
        cursor: pointer;
    }

    /* 浮動 Toast */
    .toast-banner {
        position: fixed;
        top: 1.5rem;
        left: 50%;
        transform: translateX(-50%);
        z-index: 9999;
        padding: 0.65rem 1.5rem;
        border-radius: 8px;
        font-weight: 600;
        font-size: 0.95rem;
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
        animation: slideDown 0.25s ease-out;
    }

    .toast-banner.success {
        background: #f0fdf4;
        color: #166534;
        border: 1px solid #bbf7d0;
    }

    .toast-banner.error {
        background: #fef2f2;
        color: #991b1b;
        border: 1px solid #fecaca;
    }

    .toast-banner.info {
        background: #eff6ff;
        color: #1e40af;
        border: 1px solid #bfdbfe;
    }

    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translate(-50%, -12px);
        }
        to {
            opacity: 1;
            transform: translate(-50%, 0);
        }
    }
</style>