<script lang="ts">
  import type { Ship, Vote } from "../api";

  import { slide } from "svelte/transition";
  import { derived, writable, type Readable } from "svelte/store";
  import { warships } from "../store";

  type VoteWithStats = Vote & { votedShips: (Ship & { votes: number })[] };

  export let votes: Readable<Promise<Vote[]>>;

  const voteStats = writable<VoteWithStats[]>([]);

  $: {
    if ($warships && $votes) {
      $warships
        .then(async (warships) => {
          const votes: Vote[] = await $votes;
          return { votes, warships };
        })
        .then(({ votes, warships }) => {
          voteStats.set(
            votes
              .map((vote) => {
                return {
                  ...vote,
                  votedShips: Object.entries(vote.votes)
                    .map(([key, value]) => {
                      return {
                        ...warships[key],
                        votes: value,
                      };
                    })
                    .sort((a, b) =>
                      a.votes > b.votes ? -1 : a.votes === b.votes ? 0 : 1,
                    ) // Sort votes from high to low
                    .slice(0, 4), // Limit to top three ships
                };
              })
              .sort((a, b) => (a.id > b.id ? -1 : 1)),
          );
        });
    }
  }
</script>

<h2 class="text-xl -mt-2"><slot name="title">Previous Votes</slot></h2>

{#await $votes}
  loading...
{:then}
  {#if $voteStats.length === 0}
    <div class="px-4 pt-4">
      <div
        class="relative block w-full rounded-lg border-2 border-dashed hover:border-gray-300 p-12 text-center border-gray-400"
      >
        <span class="mt-2 block text-base text-gray-400"
          >No votes yet. Click on "New Vote" to create one</span
        >
      </div>
    </div>
  {/if}

  <div transition:slide|global>
    {#each $voteStats as vote}
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
          {#if vote.votedShips.length === 0}
            <div class="flex items">
              <span class="text-gray-500">No ships voted</span>
            </div>
          {/if}
          {#if vote.votedShips.length > 0}
            <div
              class="bg-gray-700 hover:bg-gray-600 transition
                      text-gray-200
                      drop-shadow-md rounded my-2 p-2 flex justify-around items-center gap-2"
            >
              <img alt="ship" class="h-6 w-10" src={vote.votedShips[0].image} />
              <span class="text-lg font-medium text-gray-400">1.</span>
              <span class="flex-grow text-lg">{vote.votedShips[0].name}</span>
              <span class="text-gray-400">{vote.votedShips[0].votes}</span>
            </div>
          {/if}
          {#if vote.votedShips.length > 2}
            <div class="flex flex-col items-start pl-4">
              <div>
                <span class="text-xs font-medium text-gray-400">2.</span>
                <span class="flex-grow text-xs">{vote.votedShips[1].name}</span>
                <span class="text-gray-400">{vote.votedShips[0].votes}</span>
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
  </div>
{:catch}
  error
{/await}
