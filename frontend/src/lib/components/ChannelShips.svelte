<script lang="ts">
  import type { Channel, Ship } from '$lib/api';
  import { api } from '$lib/store';
  import { createEventDispatcher, onMount } from 'svelte';
  import { derived, writable, type Readable, type Writable } from 'svelte/store';
  import Box from './Box.svelte';

  export let channel: Readable<Channel>;
  const dispatch = createEventDispatcher();

  let search = writable('');
  let filteredShips = derived([channel, search], ([$channel, $search]) => {
    if (!$channel) {
      return;
    }
    const sort = (a: Ship, b: Ship) => {
      if (a.enabled && !b.enabled) {
        return 1;
      }

      if (!a.enabled && b.enabled) {
        return -1;
      }

      return a.name.localeCompare(b.name);
    };

    if (!$search) {
      return $channel.ships.sort(sort);
    }

    return $channel.ships
      .filter((ship) => ship.name.toLowerCase().includes($search.toLowerCase()))
      .sort(sort);
  });

  async function enable(ship: Ship) {
    ship.enabled = true;
    await $api.setShipStatus(ship.id, true);

    dispatch('update', $channel.ships);
  }

  async function disable(ship: Ship) {
    ship.enabled = false;
    await $api.setShipStatus(ship.id, false);

    dispatch('update', $channel.ships);
  }
</script>

<Box title="Ships">
  {#if $channel}
    <div class="flex flex-col gap-4">
      <input
        type="text"
        bind:value={$search}
        placeholder="Search"
        class="w-full border placeholder-gray-400 text-gray-300 rounded px-2 py-1 bg-cyan-900 border-gray-800"
      />
      <div class="flex flex-col gap-4">
        {#each $filteredShips as ship}
          <div class="flex flex-row gap-4 bg-gray-900 drop-shadow rounded items-center p-2">
            <img src={ship.image} alt={ship.name} class="h-6" />
            <div class="flex-grow">{ship.name}</div>

            {#if ship.enabled}
              <button
                class="hover:bg-gray-700 rounded px-4 py-2 text-gray-400 transition"
                on:click={() => disable(ship)}
              >
                <span>Disable</span>
              </button>
            {:else}
              <button
                class="bg-gray-700 hover:bg-gray-600 rounded px-4 py-2 text-gray-200 transition"
                on:click={() => enable(ship)}
              >
                <span>Enable</span>
              </button>
            {/if}
          </div>
        {/each}
      </div>
    </div>
  {/if}
</Box>
