<script lang="ts">
  import { goto } from '$app/navigation';

  import type { Ship, Vote } from '$lib/api';
  import Box from '$lib/components/Box.svelte';
  import Duration from '$lib/components/Duration.svelte';
  import ShipFilters from '$lib/components/ShipFilters.svelte';

  import { api, channel, vote } from '$lib/store';
  import { writable, type Writable } from 'svelte/store';

  let selectedShips: Writable<Ship[]> = writable([]);
  let filteredShips: Ship[] = [];

  function addShips(ships: Ship[]) {
    $selectedShips = [...$selectedShips, ...ships.filter((s) => !$selectedShips.includes(s))];
  }

  function addShip(ship: Ship) {
    if ($selectedShips.includes(ship)) {
      return;
    }
    $selectedShips = [...$selectedShips, ship];
  }

  function removeShip(ship: Ship) {
    $selectedShips = $selectedShips.filter((s) => s !== ship);
  }

  function removeAllShips() {
    $selectedShips = [];
  }

  async function openVote() {
    $vote = $api.openVote($selectedShips.map((s) => s.id));
    await goto('/live_config/');
  }
</script>

<div class="flex flex-col gap-8">
  <div>
    <a
      class="text-gray-300 hover:bg-gray-800 rounded hover:drop-shadow-xl transition font-medium p-4 inline-flex items-center gap-2"
      href="/live_config"
    >
      <svg
        class="w-4 h-4 mt-0.5"
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
  {#await $channel}
    <div class="text-gray-500">loading...</div>
  {:then channel}
    {#await $vote then vote}
      {#if vote}
        <Box>There is already an open vote</Box>
      {:else}
        <Box>
          <h2 class="text-gray-200 text-xl font-medium">New Vote</h2>

          <div class="relative">
            <div class="p-4"><Duration /></div>
            <div
              class="absolute left-0 top-0 w-full h-full bg-gray-800/90 rounded flex items-center justify-center"
            >
              <div>Coming (back) soon</div>
            </div>
          </div>

          <div class="mt-8 flex justify-around items-center">
            <button
              on:click={() => openVote()}
              class="px-8 py-4 rounded-md {$selectedShips.length
                ? 'hover:bg-cyan-400 active:bg-cyan-600 active:ring-2 active:ring-cyan-400'
                : 'text-cyan-200/50'} transition font-medium"
              class:text-gray-800={$selectedShips.length}
              class:bg-cyan-900={!$selectedShips.length}
              class:bg-cyan-500={$selectedShips.length}
              disabled={!$selectedShips.length}
              >Start vote with {$selectedShips.length} ship{#if $selectedShips.length !== 1}s{/if}</button
            >
          </div>
        </Box>
        <Box>
          <ShipFilters ships={channel.ships} bind:filteredShips />
        </Box>

        <div class="sticky bottom-0 flex justify-between">
          {#if filteredShips.length}
            <button
              on:click={() => addShips(filteredShips)}
              class="text-gray-200 px-4 py-2 rounded-md bg-cyan-800/50 hover:text-gray-100 hover:bg-cyan-700 transition font-medium"
            >
              {#if filteredShips.length === 1}
                Add {filteredShips[0].name}
              {:else}
                Add {filteredShips.length} Ships
              {/if}
            </button>
          {/if}
          <button
            on:click={() => removeAllShips()}
            class="text-gray-300 px-4 py-2 rounded-md bg-zinc-700 {$selectedShips.length
              ? 'hover:text-gray-100 hover:bg-cyan-500'
              : ''} transition font-medium"
            class:text-gray-500={!$selectedShips.length}
            class:bg-transparent={!$selectedShips.length}
            disabled={!$selectedShips.length}>Remove all</button
          >
        </div>

        <div class="flex flex-col gap-4">
          {#each filteredShips as ship}
            <Box>
              <div class="flex items-center gap-4">
                <img class="w-16 h-10" alt={ship.name} src={ship.image} />
                <span class="text-lg flex-grow">
                  {ship.name}
                </span>
                {#if $selectedShips.find((s) => s.id === ship.id)}
                  <button
                    class="bg-cyan-900 drop-shadow-sm hover:bg-cyan-700 transition font-medium py-2 px-4 rounded"
                    on:click={() => removeShip(ship)}
                  >
                    -
                  </button>
                {:else}
                  <button
                    class="bg-cyan-900 drop-shadow-sm hover:bg-cyan-700 transition font-medium py-2 px-4 rounded"
                    on:click={() => addShip(ship)}
                  >
                    +
                  </button>
                {/if}
              </div>
            </Box>
          {/each}
        </div>
      {/if}
    {/await}
  {:catch}
    could not load channel information
  {/await}
</div>
