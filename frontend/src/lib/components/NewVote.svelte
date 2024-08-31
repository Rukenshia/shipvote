<script lang="ts">
  const dev = import.meta.env.DEV;

  import type { Channel, Ship, ShipvoteApi, Vote } from "../api";
  import Box from "../components/Box.svelte";
  import Duration from "../components/Duration.svelte";
  import ShipFilters from "../components/ShipFilters.svelte";

  import { api, shipsInPreviousVote, vote } from "../store";
  import { writable, type Writable } from "svelte/store";
  import { createEventDispatcher, onMount } from "svelte";

  const dispatch = createEventDispatcher();

  // TODO: remove promise
  const channel: Writable<Promise<Channel>> = writable();
  api.subscribe(($api: ShipvoteApi) => {
    if (!$api) {
      return;
    }
    channel.set($api.broadcasterGetChannel());
  });

  let selectedShips: Writable<Ship[]> = writable([]);
  let filteredShips: Ship[] = [];
  let filteredUnaddedShips: Ship[] = [];

  $: {
    filteredUnaddedShips = filteredShips.filter(
      (ship) => !$selectedShips.find((s) => s.id === ship.id),
    );
  }

  let duration: number;

  function addShips(ships: Ship[]) {
    $selectedShips = [
      ...$selectedShips,
      ...ships.filter((s) => !$selectedShips.includes(s)),
    ];
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
    shipsInPreviousVote.set($selectedShips.map((s) => s.id));

    $vote = await $api.openVote(
      $selectedShips.map((s) => s.id),
      duration,
    );
    dispatch("vote_opened");

    if (dev) {
      window.Twitch.ext.send("broadcast", "application/json", {
        type: "vote_status",
        data: { id: $vote.id, status: "open" },
      });
    }
  }

  async function selectShipsFromPreviousVote() {
    $selectedShips = (await $channel).ships.filter((s: Ship) =>
      $shipsInPreviousVote.find((previousShipId) => previousShipId === s.id),
    );
  }
</script>

<div class="flex flex-col gap-8">
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
  {#await $channel}
    <div class="text-gray-500">loading...</div>
  {:then channel}
    {#if $vote}
      <Box>There is already an open vote</Box>
    {:else}
      <Box>
        <h2 class="text-xl font-medium text-gray-200">New Vote</h2>

        <div class="p-4"><Duration bind:selected={duration} /></div>

        <div class="mt-8 flex items-center justify-around">
          <button
            on:click={() => openVote()}
            class="rounded-md px-8 py-4 {$selectedShips.length
              ? 'hover:bg-cyan-400 active:bg-cyan-600 active:ring-2 active:ring-cyan-400'
              : 'text-cyan-200/50'} font-medium transition"
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
        {#if filteredUnaddedShips.length}
          <div class="flex items-center gap-4">
            <button
              on:click={() => addShips(filteredUnaddedShips)}
              class="rounded-md bg-cyan-800/50 px-4 py-2 font-medium text-gray-200 transition hover:bg-cyan-700 hover:text-gray-100"
            >
              {#if filteredUnaddedShips.length === 1}
                Add {filteredShips[0].name}
              {:else}
                Add {filteredUnaddedShips.length} Ships
              {/if}
            </button>
            <button
              on:click={() => selectShipsFromPreviousVote()}
              class="rounded-md bg-gray-600/50 px-4 py-2 font-medium text-gray-200 transition hover:bg-gray-700 hover:text-gray-100"
              >Add {$shipsInPreviousVote.length} from previous vote</button
            >
            >
          </div>
        {/if}
        <button
          on:click={() => removeAllShips()}
          class="rounded-md bg-zinc-700 px-4 py-2 text-gray-300 {$selectedShips.length
            ? 'hover:bg-cyan-500 hover:text-gray-100'
            : ''} font-medium transition"
          class:text-gray-500={!$selectedShips.length}
          class:bg-transparent={!$selectedShips.length}
          disabled={!$selectedShips.length}>Remove all</button
        >
      </div>

      <div class="flex flex-col gap-4">
        {#each filteredShips as ship}
          <button
            class="text-left"
            on:click={() =>
              $selectedShips.find((s) => s.id === ship.id)
                ? removeShip(ship)
                : addShip(ship)}
          >
            <Box
              colorClasses={$selectedShips.find((s) => s.id === ship.id)
                ? "bg-cyan-900 text-gray-100 transition-all duration-250"
                : "bg-gray-800 text-gray-100 transition-all duration-250"}
            >
              <div class="flex items-center gap-4">
                <img class="h-10 w-16" alt={ship.name} src={ship.image} />
                <span class="flex-grow text-lg">
                  {ship.name}
                </span>
                {#if $selectedShips.find((s) => s.id === ship.id)}
                  <button
                    class="rounded bg-cyan-950 px-4 py-2 font-medium drop-shadow-sm transition hover:bg-cyan-700"
                  >
                    -
                  </button>
                {:else}
                  <button
                    class="rounded bg-cyan-900 px-4 py-2 font-medium drop-shadow-sm transition hover:bg-cyan-700"
                  >
                    +
                  </button>
                {/if}
              </div>
            </Box>
          </button>
        {/each}
      </div>
    {/if}
  {:catch}
    could not load channel information
  {/await}
</div>
