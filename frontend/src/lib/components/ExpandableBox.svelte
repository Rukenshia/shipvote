<script lang="ts">
  import Box from "./Box.svelte";
  import { slide } from "svelte/transition";

  export let title: string = "";
  export let colorClasses: string | undefined = undefined;

  let expanded = false;
</script>

<Box {colorClasses}>
  <button
    class="flex cursor-pointer items-center gap-2"
    on:click={() => (expanded = !expanded)}
  >
    <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d={expanded ? "M5 15l7-7 7 7" : "M19 9l-7 7-7-7"}
      />
    </svg>
    <slot name="title">{title}</slot>
  </button>
  {#if expanded}
    <div in:slide|global out:slide|global class="mt-4">
      <slot />
    </div>
  {/if}
</Box>
