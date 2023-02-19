<script lang="ts">
  import { channel } from '$lib/store';
  import { onMount } from 'svelte';
  import Box from '$lib/components/Box.svelte';
</script>

<div class="flex flex-col gap-4">
  {#await $channel then channel}
    {#if channel}
      <Box title="Settings" />
    {/if}
  {:catch}
    <Box>There was an error retrieving your config</Box>
  {/await}
</div>
