<script lang="ts">
  import { api, vote } from '$lib/store';

  import { derived } from 'svelte/store';

  import type { Vote } from '$lib/api';
  import VoteResults from './VoteResults.svelte';
  import Box from './Box.svelte';

  let currentVote = derived(vote, ($vote: Promise<Vote>) => $vote);

  async function closeVote() {
    await $api.closeVote((await $currentVote).id);

    $vote = $api.getOpenVote();
  }
</script>

<main>
  <Box>
    The vote is currently

    <span class="font-medium">
      {#await $currentVote}
        loading...
      {:then vote}
        {#if vote}
          open
        {:else}
          closed
        {/if}
      {:catch}
        &lt;request failed&gt;
      {/await}
    </span>

    {#await $currentVote then vote}
      {#if vote && vote.status === 'open'}
        <div class="flex justify-around mt-2">
          <button
            on:click={() => closeVote()}
            class="px-8 py-4 rounded-md active:bg-cyan-600 active:ring-2 active:ring-cyan-400 transition font-medium"
            class:text-gray-800={vote !== undefined}
            class:text-gray-200={vote === undefined}
            class:bg-gray-700={vote === undefined}
            class:bg-cyan-500={vote !== undefined}
            class:hover:bg-cyan-400={vote !== undefined}
            disabled={vote === undefined}>Close vote</button
          >
        </div>
      {/if}
    {/await}

    <div>
      {#await $currentVote then vote}
        {#if vote && vote.status === 'open'}
          <VoteResults votes={$currentVote.then((vote) => vote.votes)} />
        {/if}
      {/await}
    </div>
  </Box>
</main>
