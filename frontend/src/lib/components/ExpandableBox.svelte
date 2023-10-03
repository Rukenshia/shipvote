<script lang="ts">
  import Box from "./Box.svelte";
  import { slide } from "svelte/transition";

  export let title: string;

  let expanded = false;
</script>

<Box>
  <button
    class="flex items-center gap-2 cursor-pointer"
    on:click={() => (expanded = !expanded)}
  >
    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d={expanded ? "M5 15l7-7 7 7" : "M19 9l-7 7-7-7"}
      />
    </svg>
    {title}
  </button>
  {#if expanded}
    <div in:slide out:slide class="mt-4">
      <slot />
    </div>
  {/if}
</Box>
