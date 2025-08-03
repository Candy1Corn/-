<script lang="ts">
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

<nav>
	<a href="/">home</a><p></p>
	<a href="/about">about</a><p></p>
	<a href="/contact">log in</a><p></p>
	<a href="/contact">log out</a>
</nav>

{@render children?.()}

<style>

  nav:hover {
    box-shadow: 0 0 10px rgb(168, 168, 168);
    transition: all 0.2s ease-in-out;
  }

</style>