<script lang="ts">
  import type { Ship, Vote } from "../api";
  import { api } from "../store";
  import ShipFilters from "./ShipFilters.svelte";
  import { slide } from "svelte/transition";

  export let vote: Vote;
  export let warships: { [key: string]: Ship };

  export let close: () => void;

  let filteredShips: Ship[] = vote.ships.map((id) => warships[`${id}`]);
  let showFilters = false;

  let shipsByTier: Map<number, Ship[]> = new Map();
  $: {
    shipsByTier = new Map();
    filteredShips.forEach((ship) => {
      if (!shipsByTier.has(ship.tier)) {
        shipsByTier.set(ship.tier, []);
      }
      shipsByTier.get(ship.tier).push(ship);
    });

    shipsByTier = new Map(
      [...shipsByTier.entries()].sort((a, b) => a[0] - b[0])
    );
  }

  const votedShips = vote.ships.map((id) => ({
    ship: warships[`${id}`] as Ship,
    votes: vote.votes[id] || 0,
  }));

  async function voteForShip(ship: Ship) {
    close();
    await $api.voteForShip(vote.id, ship.id);
  }

  function romanize(tier: number): string {
    return "I II III IV V VI VII VIII IX X".split(" ")[tier - 1];
  }
</script>

<div class="flex flex-col gap-4 pr-4">
  <div class="flex gap-4">
    <h2 class="text-lg font-bold">Cast your vote</h2>
    <button
      class="bg-cyan-700 rounded hover:bg-cyan-600 px-2 py-0.5 flex gap-2 items-center"
      class:bg-cyan-600={showFilters}
      on:click={() => (showFilters = !showFilters)}
    >
      <svg
        class="w-4 h-4"
        fill="none"
        stroke="currentColor"
        stroke-width="1.5"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M12 3c2.755 0 5.455.232 8.083.678.533.09.917.556.917 1.096v1.044a2.25 2.25 0 01-.659 1.591l-5.432 5.432a2.25 2.25 0 00-.659 1.591v2.927a2.25 2.25 0 01-1.244 2.013L9.75 21v-6.568a2.25 2.25 0 00-.659-1.591L3.659 7.409A2.25 2.25 0 013 5.818V4.774c0-.54.384-1.006.917-1.096A48.32 48.32 0 0112 3z"
        />
      </svg>
      <span class="text-md">Filters</span>
    </button>
    <div class="flex-grow" />
    <button
      class="bg-cyan-700 rounded hover:bg-cyan-600 px-2 py-0.5 flex items-center"
      on:click={() => close()}
    >
      <svg
        class="w-4 h-4"
        fill="none"
        stroke="currentColor"
        stroke-width="1.5"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
        aria-hidden="true"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          d="M6 18L18 6M6 6l12 12"
        />
      </svg>
    </button>
  </div>

  {#if showFilters}
    <div in:slide out:slide>
      <ShipFilters ships={votedShips.map((vs) => vs.ship)} bind:filteredShips />
    </div>
  {/if}

  {#each shipsByTier.entries() as [tier, ships]}
    <div class="grid grid-cols-4 sm:grid-cols-4 lg:grid-cols-4 gap-2">
      <span
        class="col-span-full text-xs font-bold flex items-center gap-2 text-cyan-100"
      >
        Tier {romanize(tier)}
        <span class="border-t flex-grow" />
      </span>
      {#each ships as ship}
        <button
          class="flex bg-cyan-700 hover:bg-cyan-600 rounded pr-2 pb-1 items-end truncate min-w-min transition-colors"
          on:click={() => voteForShip(ship)}
        >
          <img class="w-auto h-6" alt={ship.name} src={ship.image} />
          <span class="text-xs sm:text-sm flex-grow truncate">
            {ship.name}
          </span>
        </button>
      {/each}
    </div>
  {/each}
</div>
