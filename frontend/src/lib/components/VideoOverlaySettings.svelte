<script lang="ts">
  import { createEventDispatcher } from "svelte";
  import Box from "./Box.svelte";
  import type { Channel } from "../api";
  import { api } from "../store";

  export let channel: Channel;
  let overlayPosition = channel.overlay_position;

  const dispatch = createEventDispatcher();

  let channelUpdateFeedback = "";

  const options = [
    ["top_left", "Top Left", true],
    ["top_right", "Top Right", true],
    ["bottom_left", "Bottom Left", false],
    ["bottom_right", "Bottom Right", false],
  ];

  async function changeOverlayPosition(position: string) {
    console.log("changeOverlayPosition", position);

    channel.overlay_position = position;

    try {
      await $api.updateChannelConfig(channel);

      channelUpdateFeedback = "Overlay position updated";
    } catch (e) {
      console.error(e);

      channelUpdateFeedback = "Failed to update overlay position";
    }

    setTimeout(() => {
      channelUpdateFeedback = "";
    }, 5000);
  }
</script>

<div>
  <a
    class="inline-flex items-center gap-2 rounded p-4 font-medium text-gray-300 transition hover:bg-gray-800 hover:drop-shadow-xl"
    href="#live_config"
    on:click={() => dispatch("back")}
  >
    <svg
      class="mt-0.5 h-4 w-4"
      fill="none"
      stroke="currentColor"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
      ><path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M10 19l-7-7m0 0l7-7m-7 7h18"
      /></svg
    >
    Go back</a
  >
</div>

<Box title="Settings">
  <div class="flex flex-col gap-4">
    <h2 class="text-lg font-normal">Overlay Position</h2>

    <div class="grid content-center max-w-xl grid-cols-2 gap-4 px-8">
      {#each options as [position, label, available]}
        <button
          class="w-full aspect-square flex flex-col gap-2 items-center justify-center col-span-1 transition text-gray-200 px-4 py-2 rounded
          ring-cyan-400"
          disabled={!available}
          class:hover:cursor-not-allowed={!available}
          class:active:bg-cyan-600={available}
          class:active:ring-2={available}
          class:hover:bg-cyan-700={available}
          class:bg-cyan-950={!available}
          class:bg-cyan-800={overlayPosition === position}
          class:bg-cyan-900={overlayPosition !== position}
          class:ring-2={overlayPosition === position}
          on:click={() => (overlayPosition = position)}
        >
          {label}
          {#if !available}
            <span class="text-xs text-cyan-400">not available</span>
          {/if}
        </button>
      {/each}
    </div>

    <button
      class="bg-cyan-900 hover:bg-cyan-800 transition text-gray-200 px-4 py-2 rounded mt-4
      active:bg-cyan-600 active:ring-2 ring-cyan-400"
      on:click={() => changeOverlayPosition(overlayPosition)}
    >
      Save
    </button>

    {#if channelUpdateFeedback}
      <div class="text-cyan-400">{channelUpdateFeedback}</div>
    {/if}
  </div></Box
>
