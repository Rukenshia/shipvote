<script lang="ts">
  import { derived } from 'svelte/store';
  import { warships } from '../store';

  export let votes: { [key: string]: number };

  const ships = derived(warships, async ($warships) => {
    if (!$warships) {
      return new Array(4).fill({ name: '' });
    }

    const currentWarships = await $warships;
    return Object.entries(votes)
      .map(([key, value]) => {
        return {
          ...currentWarships[key],
          votes: value
        };
      })
      .sort((a, b) => (a.votes > b.votes ? -1 : a.votes === b.votes ? 0 : 1)) // Sort votes from high to low
      .slice(0, 4);
  });
</script>

<h2 class="text-xl mt-2"><slot name="title">Results</slot></h2>

<ul class="px-4">
  {#await $ships}
    <li
      class="bg-gray-700 hover:bg-gray-600 transition
			drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-4"
    >
      <div class="h-10" />
    </li>
  {:then ships}
    {#if ships.length === 0}
      <li
        class="bg-gray-700 hover:bg-gray-600 transition
			drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-4"
      >
        <div class="h-10 text-center flex items-center">No voted ships</div>
      </li>
    {/if}
    {#each ships as ship, rank}
      <li
        class="bg-gray-700 hover:bg-gray-600 transition
			drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-4"
      >
        <img alt="ship" class="h-10 w-16" src={ship.image} />
        <span class="text-lg font-medium text-gray-400">{rank + 1}.</span>
        <span class="flex-grow text-lg">{ship.name}</span>
        <span class="pr-4 font-medium">{ship.votes}</span>
      </li>
    {/each}
  {/await}
</ul>
