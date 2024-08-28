<script lang="ts">
  import type { Ship, Vote } from "../api";
  import { api } from "../store";
  import ShipFilters from "./ShipFilters.svelte";
  import RemainingVoteTime from "./RemainingVoteTime.svelte";
  import { slide } from "svelte/transition";

  export let vote: Vote;
  export let warships: { [key: string]: Ship };

  export let close: () => void;

  let filteredShips: Ship[] = vote.ships
    .map((id) => warships[`${id}`])
    .filter((ship) => ship !== undefined);
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
      [...shipsByTier.entries()].sort((a, b) => a[0] - b[0]),
    );
  }

  const votedShips = vote.ships
    .map((id) => ({
      ship: warships[`${id}`] as Ship,
      votes: vote.votes[id] || 0,
    }))
    .filter((vs) => vs.ship !== undefined);

  async function voteForShip(ship: Ship) {
    close();
    await $api.voteForShip(vote.id, ship.id);
  }

  function romanize(tier: number): string {
    return "I II III IV V VI VII VIII IX X".split(" ")[tier - 1];
  }
</script>

<div class="flex flex-col gap-4 pr-4">
  <div class="flex items-center gap-4">
    <h2 class="text-lg font-bold">Cast your vote</h2>
    <button
      class="flex items-center gap-2 rounded bg-cyan-700 px-2 py-0.5 hover:bg-cyan-600"
      class:bg-cyan-600={showFilters}
      on:click={() => (showFilters = !showFilters)}
    >
      <svg
        class="h-4 w-4"
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

    {#if vote.ends_at}
      <div class="flex-grow">
        <RemainingVoteTime
          vertical_padding={1}
          started_at={vote.created_at}
          ends_at={vote.ends_at}
        />
      </div>
    {:else}
      <div class="flex-grow" />
    {/if}

    <button
      class="flex items-center rounded bg-cyan-700 px-2 py-0.5 hover:bg-cyan-600"
      on:click={() => close()}
    >
      <svg
        class="h-4 w-4"
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
    <div in:slide|global out:slide|global>
      <ShipFilters ships={votedShips.map((vs) => vs.ship)} bind:filteredShips />
    </div>
  {/if}

  {#each shipsByTier.entries() as [tier, ships]}
    <div class="grid grid-cols-4 gap-2 sm:grid-cols-4 lg:grid-cols-4">
      <span
        class="col-span-full flex items-center gap-2 text-xs font-bold text-cyan-100"
      >
        Tier {romanize(tier)}
        <span class="flex-grow border-t" />
      </span>
      {#each ships as ship}
        <button
          class="flex min-w-min items-end truncate rounded bg-cyan-700 pb-1 pr-2 transition-colors hover:bg-cyan-600"
          on:click={() => voteForShip(ship)}
        >
          <img class="h-6 w-auto" alt={ship.name} src={ship.image} />
          <span class="flex-grow truncate text-xs sm:text-sm">
            {ship.name}
          </span>
        </button>
      {/each}
    </div>
  {/each}
</div>
