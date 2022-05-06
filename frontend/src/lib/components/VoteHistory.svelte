<script lang="ts">
  import type { Ship, Vote } from '$lib/api';

  import { derived, Readable } from 'svelte/store';
  import { warships } from '../store';

  type VoteWithStats = Vote & { votedShips: (Ship & { votes: number })[] };

  export let votes: Promise<Vote[]>;

  const votesWithStats: Readable<Promise<VoteWithStats[]>> = derived(
    warships,
    async ($warships) => {
      if (!$warships) {
        return new Array(4).fill({ name: '' });
      }

      const currentWarships = await $warships;
      const voteHistory = await votes;

      return voteHistory.reverse().map((vote) => ({
        ...vote,
        votedShips: Object.entries(vote.votes)
          .map(([key, value]) => {
            return {
              ...currentWarships[key],
              votes: value
            };
          })
          .sort((a, b) => (a.votes > b.votes ? -1 : a.votes === b.votes ? 0 : 1)) // Sort votes from high to low
          .slice(0, 4) // Limit to top three ships
      }));
    }
  );
</script>

<h2 class="text-xl mt-2"><slot name="title">Previous Votes</slot></h2>

{#await $votesWithStats}
  loading...
{:then votesWithStats}
  {#each votesWithStats as vote}
    <div class="p-2">
      <h5 class="text-md font-medium text-gray-100">
        <div class="flex items-center">
          <div class="flex-grow">
            <span class="text-gray-300">#</span>
            {vote.id}
          </div>
          <span class="text-gray-500 text-xs">{vote.updated_at}</span>
        </div>
      </h5>
      <div class="px-4 grid grid-cols-2 gap-2 items-center">
        {#if vote.votedShips.length > 0}
          <div
            class="bg-gray-700 hover:bg-gray-600 transition
                      text-gray-200
                      drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-2"
          >
            <img alt="ship" class="h-6 w-10" src={vote.votedShips[0].image} />
            <span class="text-lg font-medium text-gray-400">1.</span>
            <span class="flex-grow text-lg">{vote.votedShips[0].name}</span>
          </div>
        {/if}
        {#if vote.votedShips.length > 2}
          <div class="flex flex-col items-start pl-4">
            <div>
              <span class="text-xs font-medium text-gray-400">2.</span>
              <span class="text-xs">{vote.votedShips[1].name}</span>
            </div>
            <div>
              <span class="text-xs font-medium text-gray-400">3.</span>
              <span class="text-xs">{vote.votedShips[2].name}</span>
            </div>
          </div>
        {/if}
        {#if vote.votedShips.length === 2}
          <div
            class="
                      text-gray-200
                      drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-2"
          >
            <img alt="ship" class="h-4 w-8" src={vote.votedShips[1].image} />
            <span class="text-md font-medium text-gray-400">2.</span>
            <span class="flex-grow text-md">{vote.votedShips[1].name}</span>
          </div>
        {/if}
      </div>
    </div>
  {/each}
{:catch}
  error
{/await}
