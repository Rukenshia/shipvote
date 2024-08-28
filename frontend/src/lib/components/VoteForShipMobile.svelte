<script lang="ts">
  import type { Ship, Vote } from "../api";
  import { api } from "../store";
  import ShipFilters from "./ShipFilters.svelte";
  import { slide } from "svelte/transition";

  export let vote: Vote;
  export let warships: { [key: string]: Ship };

  let filteredShips: Ship[] = vote.ships.map((id) => warships[`${id}`]);
  let showFilters = false;

  const votedShips = vote.ships.map((id) => ({
    ship: warships[`${id}`] as Ship,
    votes: vote.votes[id] || 0,
  }));

  async function voteForShip(ship: Ship) {
    await $api.voteForShip(vote.id, ship.id);
  }
</script>

<div class="flex flex-col gap-4 text-white">
  <div class="flex items-center justify-center gap-8">
    <h2 class="text-xl font-bold flex-grow">Cast your vote</h2>
    <button
      class="bg-cyan-800 rounded hover:bg-cyan-700 px-4 py-2 flex gap-2 items-center justify-center text-xl"
      class:bg-cyan-700={showFilters}
      on:click={() => (showFilters = !showFilters)}
    >
      <svg
        class="w-8 h-8"
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
  </div>

  {#if showFilters}
    <div in:slide|global out:slide|global>
      <ShipFilters ships={votedShips.map((vs) => vs.ship)} bind:filteredShips />
    </div>
  {/if}

  <div class="grid grid-cols-1 divide-y divide-cyan-800">
    {#each filteredShips as ship}
      <button
        class="py-6 flex gap-4 items-end truncate"
        on:click={() => voteForShip(ship)}
      >
        <img class="w-auto h-8" alt={ship.name} src={ship.image} />
        <span class="text-md sm:text-lg truncate flex-grow text-left">
          {ship.name}
        </span>
        <span class="text-md sm:text-lg text-cyan-400/50">
          {votedShips.find((vs) => vs.ship.id === ship.id).votes}
          votes
        </span>
      </button>
    {/each}
  </div>
</div>
