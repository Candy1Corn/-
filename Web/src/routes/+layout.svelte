<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<nav>
	<a href="/">home</a>
	<a href="/about">about</a>
	<a href="/view_patients_info"> 查看患者資料 </a>
</nav>

{@render children?.()}

<style>

  nav {
    display: flex;
    gap: 1rem;
    padding: 1rem;
    background-color: #4161a6;
    border-radius: 10px;
    box-shadow: 0 0 10px rgb(0, 0, 0);
  }
  nav:hover {
    filter: drop-shadow(0 0 2em  #4161a6);
    transition: all 0.2s ease-in-out;
  }
  nav a {
    text-decoration: none;
    color: #ffffff;
    font-weight: bold;
  }

  nav a:hover {
    text-decoration: underline;
  }
</style>