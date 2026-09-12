<script lang="ts">
	import { onMount } from 'svelte';

	let patientsPay: string | any[] = [];
	let patientIDInput = ''; // 綁定到 input 的值

	// 獲取資料的函式
	async function fetchData() {
		let url = '/api/patientsPay';
		// 如果 input 有值，就加到 URL 的 query string
		if (patientIDInput) {
			url += `?patientID=${patientIDInput}`;
		}

		try {
			const res = await fetch(url);
			if (res.ok) {
				patientsPay = await res.json();
			} else {
				console.error('Failed to fetch data', await res.text());
				patientsPay = []; // 清空舊資料
			}
		} catch (error) {
			console.error('Error fetching data:', error);
			patientsPay = []; // 清空舊資料
		}
	}

	// 頁面載入時，先獲取一次所有資料
	onMount(() => {
		fetchData();
	});

</script>

<h1>病患付款資料查詢</h1>

<div class="search-container">
    <input type="text" class="inputID" bind:value={patientIDInput} placeholder="請輸入病患ID (例如 P001)" />
    <button on:click={fetchData}>查詢</button>
</div>

{#if patientsPay.length > 0}
	<table>
		<thead>
			<tr>
				<th>病患ID</th>
				<th>姓名</th>
				<th>應付金額</th>
				<th>已付金額</th>
				<th>付款狀態</th>
			</tr>
		</thead>
		<tbody>
			{#each patientsPay as patient}
				<tr>
					<td>{patient.PatientID}</td>
					<td>{patient.Name}</td>
					<td>{patient.TotalAmount}</td>
					<td>{patient.PaidAmount}</td>
					<td>{patient.PaymentStatus}</td>
				</tr>
			{/each}
		</tbody>
	</table>
{:else}
    <p>查無資料或無待繳費項目。</p>
{/if}

<style>
    .search-container {
        margin-bottom: 1rem;
    }
    .inputID {
        padding: 0.5rem;
        margin-right: 0.5rem;
    }
	table {
		width: 100%;
		border-collapse: collapse;
	}
	th, td {
		border: 1px solid #ddd;
		padding: 8px;
		text-align: left;
	}
	th {
		background-color: #f2f2f2;
	}
</style>
