<script lang="ts">
  import { onMount } from 'svelte';

  let patientName = '';
  let patientData: any = null;
  let message = '';

  // 查詢病患
  async function searchPatient() {
    message = '';
    patientData = null;

    const res = await fetch('http://127.0.0.1:7999/api/viewPatientsInfo');
    const data: Record<string, any> = await res.json();

    // 從 JSON 中找病患
    const found = Object.entries(data).find(
      ([, info]) => info.name === patientName
    );

    if (found) {
      const [id, info] = found;
      patientData = { id, ...info };
    } else {
      message = '找不到該病患';
    }
  }

  // 確認繳費
  async function confirmPayment() {
    if (!patientData) return;

    const url = `http://127.0.0.1:7999/api/patientsPay?patientID=${patientData.id}`;
    const res = await fetch(url);
    const result = await res.json();

    console.log(result);
    message = '已更新繳費狀態';
    
    // 更新畫面（模擬刷新）
    patientData.paied = '已繳費';
  }
</script>

<h2>查詢病患資訊</h2>

<input
  type="text"
  placeholder="輸入病患名字"
  bind:value={patientName}
/>
<button on:click={searchPatient}>查詢</button>

{#if message}
  <p>{message}</p>
{/if}

{#if patientData}
  <div class="patient-info">
    <h3>{patientData.name} ({patientData.id})</h3>
    <p>生日：{patientData.dob}</p>
    <p>聯絡電話：{patientData.contact}</p>
    <p>診斷：{patientData.diagnosis || '尚未診斷'}</p>
    <p>結果：{patientData.result || '無'}</p>
    <p>繳費狀態：{patientData.paied || '未繳費'}</p>

    {#if patientData.paied !== '已繳費'}
      <button on:click={confirmPayment}>確認繳費</button>
    {/if}
  </div>
{/if}

<style>
  .patient-info {
    margin-top: 1rem;
    padding: 1rem;
    border: 1px solid #ccc;
    border-radius: 8px;
  }
  input {
    margin-right: 0.5rem;
    padding: 0.3rem;
  }
</style>
