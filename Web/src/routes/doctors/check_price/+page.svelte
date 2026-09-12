<script lang="ts">
  // 後端位址：開發時請依你的實際狀況調整
  const API_BASE = 'http://127.0.0.1:7999';
  import { goto } from '$app/navigation';

  // 表單欄位
  let patientID = '';
  let hasNewAllergy: 'Y' | 'N' = 'N';
  let extraHistory = '';          // 若 hasNewAllergy = 'Y' 才填
  let diagnosis = '';             // 症狀
  let result: '洗牙' | '補牙' | '拔牙' | '整牙' | '開藥' = '補牙';
  let prescription = '';          // 多種藥物以 ", " (英文逗號+一個半形空白) 分隔；否則填「否」
  let cost: number | '' = '';

  // UI 狀態
  let submitting = false;
  let messages: string[] = [];
  let errorMsg = '';

  // 批價清單（GET）
  type PriceItem = {
    patientID: string;
    name: string;
    cost: number;
    type: string;
    date: string;
    paid: string;
  };
  let priceList: PriceItem[] = [];
  let loadingList = true;
  let listError = '';

  // 載入現有批價清單（GET /api/checkPrice）
  async function loadPriceList() {
    loadingList = true;
    listError = '';
    try {
      const res = await fetch(`${API_BASE}/api/checkPrice`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      priceList = await res.json();
    } catch (e: any) {
      listError = e?.message ?? '載入失敗';
    } finally {
      loadingList = false;
    }
  }

  // 初始載入
  loadPriceList();

  // 送出（POST /api/checkPrice）
  async function submitForm() {
    messages = [];
    errorMsg = '';

    // description 規則：若勾選「有新的過敏史」才把 extraHistory 串上；否則送空字串
    const description = hasNewAllergy === 'Y'
      ? (extraHistory?.trim() || '有新過敏史但未填寫')
      : '';

    // prescription 規則：若不是「開藥」，就忽略 prescription；若是開藥且沒有藥名，請填「否」
    const normalizedPrescription =
      result === '開藥'
        ? (prescription?.trim() || '否')
        : '';

    // cost 檢查
    const parsedCost = typeof cost === 'number' ? cost : parseInt(String(cost), 10);
    if (!patientID || !diagnosis || !result || Number.isNaN(parsedCost)) {
      errorMsg = '請完整填寫必填欄位（病歷號、症狀、診斷結果、費用）。';
      return;
    }

    submitting = true;
    try {
      const res = await fetch(`${API_BASE}/api/checkPrice`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          patientID,
          description,
          diagnosis,
          result,
          prescription: normalizedPrescription,
          cost: parsedCost
        })
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err?.error || `HTTP ${res.status}`);
      }

      const data = await res.json(); // { status: "success", messages: [...] }
      messages = Array.isArray(data?.messages) ? data.messages : ['已完成'];
      // 重新載入清單
      await loadPriceList();
      // 清掉表單（可依需求保留）
      // patientID = ''; hasNewAllergy = 'N'; extraHistory = ''; diagnosis = '';
      // result = '補牙'; prescription = ''; cost = '';
    } catch (e: any) {
      errorMsg = e?.message ?? '提交失敗';
    } finally {
      submitting = false;
    }
  }
</script>


<!-- 表單 -->
<div class="max-w-3xl mx-auto p-4 space-y-4">
  <h1 class="text-2xl font-bold">批價 / 診斷提交</h1>

  <div class="space-y-2">
    <label class="block font-medium">病人病歷號碼（patientID）*</label>
    <input class="border rounded p-2 w-full" bind:value={patientID} placeholder="例如：P8" />
  </div>

  <div class="space-y-2">
    <label class="block font-medium">病人是否有新的過敏史？*</label>
    <div class="flex items-center gap-4">
      <label class="inline-flex items-center gap-2">
        <input type="radio" name="allergy" value="N" bind:group={hasNewAllergy} />
        <span>否</span>
      </label>
      <label class="inline-flex items-center gap-2">
        <input type="radio" name="allergy" value="Y" bind:group={hasNewAllergy} />
        <span>有（請填其他病史）</span>
      </label>
    </div>
    {#if hasNewAllergy === 'Y'}
      <textarea class="border rounded p-2 w-full" rows="3" bind:value={extraHistory} placeholder="請輸入該病人的其他病史"></textarea>
    {/if}
  </div>

  <div class="space-y-2">
    <label class="block font-medium">病人症狀（diagnosis）*</label>
    <input class="border rounded p-2 w-full" bind:value={diagnosis} placeholder="例如：牙痛 / 牙齦流血 ..." />
  </div>

  <div class="space-y-2">
    <label class="block font-medium">診斷結果（result）*</label>
    <select class="border rounded p-2 w-full" bind:value={result}>
      <option>洗牙</option>
      <option>補牙</option>
      <option>拔牙</option>
      <option>整牙</option>
      <option>開藥</option>
    </select>
  </div>

  {#if result === '開藥'}
    <div class="space-y-2">
      <label class="block font-medium">藥名（多種以「, 」分隔；否則填「否」）</label>
      <input class="border rounded p-2 w-full" bind:value={prescription} placeholder="Aspirin, 新的藥物" />
      <p class="text-sm text-gray-600">**注意**：請使用「英文逗號 + 一個半形空白」分隔，如：<code>Aspirin, 新的藥物</code>。</p>
    </div>
  {/if}

  <div class="space-y-2">
    <label class="block font-medium">費用（cost，整數）*</label>
    <input class="border rounded p-2 w-full" type="number" min="0" bind:value={cost} placeholder="例如：500" />
  </div>

  <button class="px-4 py-2 rounded bg-blue-600 text-white disabled:opacity-50"
          on:click|preventDefault={submitForm}
          disabled={submitting}>
    {submitting ? '提交中…' : '送出'}
  </button>

  {#if errorMsg}
    <div class="mt-3 p-3 border rounded bg-red-50 text-red-700">{errorMsg}</div>
  {/if}
  {#if messages.length}
    <div class="mt-3 p-3 border rounded bg-green-50 text-green-700">
      <ul class="list-disc pl-5">
        {#each messages as m}<li>{m}</li>{/each}
      </ul>
    </div>
  {/if}
</div>

<!-- 既有批價清單（GET /api/checkPrice） -->
<div class="max-w-4xl mx-auto p-4 mt-8 space-y-3">
  <h2 class="text-xl font-semibold">現有批價清單</h2>
  {#if loadingList}
    <div>載入中…</div>
  {:else if listError}
    <div class="p-3 border rounded bg-red-50 text-red-700">{listError}</div>
  {:else if priceList.length === 0}
    <div class="text-gray-600">尚無資料</div>
  {:else}
    <table class="w-full border-collapse">
      <thead>
        <tr>
          <th class="border p-2">病歷號</th>
          <th class="border p-2">姓名</th>
          <th class="border p-2">費用</th>
          <th class="border p-2">類型</th>
          <th class="border p-2">日期</th>
          <th class="border p-2">繳費狀態</th>
        </tr>
      </thead>
      <tbody>
        {#each priceList as item}
          <tr>
            <td class="border p-2">{item.patientID}</td>
            <td class="border p-2">{item.name}</td>
            <td class="border p-2">{item.cost}</td>
            <td class="border p-2">{item.type}</td>
            <td class="border p-2">{item.date}</td>
            <td class="border p-2">{item.paid}</td>
          </tr>
        {/each}
      </tbody>
    </table>
  {/if}
</div>
