<script lang="ts">
  import { derived, writable } from "svelte/store";
  import { warships } from "../store";

  export let votes: { [key: string]: number };

  const ships = writable([]);

  $: {
    warships.subscribe(async ($warships) => {
      if (!$warships) {
        return;
      }

      const currentWarships = await $warships;
      ships.set(
        Object.entries(votes)
          .map(([key, value]) => {
            return {
              ...currentWarships[key],
              votes: value,
            };
          })
          .sort((a, b) =>
            a.votes > b.votes ? -1 : a.votes === b.votes ? 0 : 1,
          ) // Sort votes from high to low
          .slice(0, 4),
      );
    });
  }
</script>

<h2 class="mt-2 text-xl"><slot name="title">Results</slot></h2>

<ul class="px-4">
  {#await $ships}
    <li
      class="my-2 flex items-center
			justify-around gap-4 rounded bg-gray-700 p-2 drop-shadow-md transition hover:bg-gray-600"
    >
      <div class="h-10" />
    </li>
  {:then ships}
    {#if ships.length === 0}
      <li
        class="my-2 flex items-center
			justify-around gap-4 rounded bg-gray-700 p-2 drop-shadow-md transition hover:bg-gray-600"
      >
        <div class="flex h-10 items-center text-center">No voted ships</div>
      </li>
    {/if}
    {#each ships as ship, rank}
      <li
        class="my-2 flex items-center
			justify-around gap-4 rounded bg-gray-700 p-2 drop-shadow-md transition hover:bg-gray-600"
      >
        <img alt="ship" class="h-10 w-16" src={ship.image} />
        <span class="text-lg font-medium text-gray-400">{rank + 1}.</span>
        <span class="flex-grow text-lg">{ship.name}</span>
        <span class="pr-4 font-medium">{ship.votes}</span>
      </li>
    {/each}
  {/await}
</ul>
