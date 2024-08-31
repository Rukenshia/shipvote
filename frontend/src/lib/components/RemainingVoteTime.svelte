<script lang="ts">
  import { onMount, onDestroy } from "svelte";
  export let started_at: string;
  export let ends_at: string;
  export let vertical_padding = 2;

  let remaining_minutes = 0;
  let remaining_seconds = 0;
  let closing = false;

  const started_at_date = new Date(started_at);
  const ends_at_date = new Date(ends_at);
  const total_seconds = Math.floor(
    (ends_at_date.getTime() - started_at_date.getTime()) / 1000,
  );

  let width = 0;

  let intv: any;
  onMount(() => {
    if (!ends_at) return;

    const calculateRemainingTime = () => {
      const elapsed_seconds = Math.floor(
        (Date.now() - started_at_date.getTime()) / 1000,
      );

      width = (elapsed_seconds / total_seconds) * 100;

      remaining_minutes = Math.floor(
        (ends_at_date.getTime() - Date.now()) / 1000 / 60,
      );
      remaining_seconds = Math.floor(
        (ends_at_date.getTime() - Date.now()) / 1000,
      );

      if (remaining_seconds <= 0 && remaining_minutes <= 0) {
        closing = true;
        if (intv) {
          clearInterval(intv);
        }
      }
    };

    intv = setInterval(calculateRemainingTime, 1000);
    calculateRemainingTime();
  });

  onDestroy(() => {
    if (intv) {
      clearInterval(intv);
    }
  });
</script>

<div
  class="relative flex h-full justify-start rounded-md bg-gray-200/5 text-sm text-gray-100/80 shadow-inner"
>
  <div class="absolute z-0 h-full w-full">
    <div
      style={`width: ${width}%;`}
      class="h-full rounded bg-cyan-500/10 transition-all duration-[1500ms]"
    ></div>
  </div>
  <div class={`z-10 p-4 py-${vertical_padding}`}>
    {#if closing}
      <span class="font-medium text-cyan-500"> Closing vote... </span>
    {:else}
      <span class="font-medium">Vote ends in</span>
      <span class="trim">
        {#if remaining_minutes > 0}
          {remaining_minutes} minute{remaining_minutes > 1 ? "s" : ""}{" "}
        {:else}{remaining_seconds % 60} second{remaining_seconds % 60 > 1
            ? "s"
            : ""}
        {/if}
      </span>
    {/if}
  </div>
</div>
