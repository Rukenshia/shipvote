<script lang="ts">
  import type { Ship } from "../api";
  import Filter from "./Filter.svelte";

  export let ships: Ship[] = [];
  export let filteredShips: Ship[] = [];

  let nations = [...new Set(ships.map((ship) => ship.nation)).values()].sort();
  let selectedNation = "all";
  let tiers = [...new Set(ships.map((ship) => ship.tier)).values()]
    .sort()
    .reverse();
  let selectedTier = "all";
  let types = [...new Set(ships.map((ship) => ship.type)).values()]
    .sort()
    .reverse();
  let selectedType = "all";

  let shipName = "";

  let changed = false;

  $: {
    filteredShips = ships
      .filter((ship) =>
        shipName
          ? ship.name.toLowerCase().includes(shipName.toLowerCase())
          : true,
      )
      .filter(
        (ship) => selectedNation === "all" || ship.nation === selectedNation,
      )
      .filter((ship) => selectedTier === "all" || ship.tier === selectedTier)
      .filter((ship) => selectedType === "all" || ship.type === selectedType);

    changed =
      selectedNation !== "all" ||
      selectedTier !== "all" ||
      selectedType !== "all" ||
      shipName !== "";
  }

  function resetAllFilters() {
    selectedNation = "all";
    selectedTier = "all";
    selectedType = "all";
    shipName = "";
  }

  resetAllFilters();
</script>

<div class="flex flex-col gap-2">
  <div class="flex items-center gap-2">
    <h2 class="text-cyan-100 text-xl font-medium">Filters</h2>
    <button
      class="text-xs drop-shadow-sm transition font-medium py-0.5 px-1 rounded"
      disabled={!changed}
      class:text-cyan-600={!changed}
      class:text-cyan-300={changed}
      class:bg-cyan-600={changed}
      class:bg-cyan-950={!changed}
      class:hover:bg-cyan-700={changed}
      on:click={resetAllFilters}
      ><svg
        class="h-6 w-6"
        fill="inherit"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          xmlns="http://www.w3.org/2000/svg"
          d="M12.2071 2.29289C12.5976 2.68342 12.5976 3.31658 12.2071 3.70711L10.9142 5H12.5C17.1523 5 21 8.84772 21 13.5C21 18.1523 17.1523 22 12.5 22C7.84772 22 4 18.1523 4 13.5C4 12.9477 4.44772 12.5 5 12.5C5.55228 12.5 6 12.9477 6 13.5C6 17.0477 8.95228 20 12.5 20C16.0477 20 19 17.0477 19 13.5C19 9.95228 16.0477 7 12.5 7H10.9142L12.2071 8.29289C12.5976 8.68342 12.5976 9.31658 12.2071 9.70711C11.8166 10.0976 11.1834 10.0976 10.7929 9.70711L7.79289 6.70711C7.40237 6.31658 7.40237 5.68342 7.79289 5.29289L10.7929 2.29289C11.1834 1.90237 11.8166 1.90237 12.2071 2.29289Z"
          fill="currentColor"
        />
      </svg>
    </button>
  </div>
  <div class="flex flex-col gap-2">
    <div class="flex gap-2">
      <Filter name="nations" options={nations} bind:value={selectedNation}
        >Nations</Filter
      >
      <Filter name="tiers" options={tiers} bind:value={selectedTier}
        >Tier</Filter
      >
      <Filter name="types" options={types} bind:value={selectedType}
        >Class</Filter
      >
    </div>
    <div class="relative">
      <input
        type="text"
        name="ship_name"
        class="bg-cyan-700 shadow-sm focus:ring-cyan-500 focus:border-cyan-500 block w-full sm:text-sm border-cyan-500 rounded-md placeholder-cyan-300/50 px-4 py-2"
        placeholder="Name"
        bind:value={shipName}
      />
      <div class="absolute flex items-center inset-y-0 right-0 pr-3">
        <svg
          class="w-6 h-6 text-cyan-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg"
          ><path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          /></svg
        >
      </div>
    </div>
  </div>
</div>
