<script lang="ts">
  import { api } from '$lib/store';

  import { derived, Writable, writable } from 'svelte/store';

  import type { Vote } from '$lib/api';
  import VoteResults from './VoteResults.svelte';
  import Box from './Box.svelte';

  let currentVote: Writable<Promise<Vote>> = writable(null);
  let mostRecentVote: Writable<Promise<Vote>> = writable(null);

  function loadCurrentVote() {
    $currentVote = $api.getOpenVote();
  }

  $: if ($api) {
    loadCurrentVote();
    $mostRecentVote = $api
      .getClosedVotes()
      .then((votes: Vote[]) => (votes.length > 0 ? votes[0] : null));
  }

  const votes = derived([currentVote, mostRecentVote], async ([$currentVote, $mostRecentVote]) => {
    let current = await $currentVote;
    let mostRecent = await $mostRecentVote;

    if (current) {
      return current.votes;
    } else if (mostRecent) {
      return mostRecent.votes;
    }
    return { votes: [] };
  });

  async function closeVote() {
    await $api.closeVote((await $currentVote).id);

    loadCurrentVote();
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
      <div class="flex justify-around">
        <button
          on:click={() => closeVote()}
          class="px-8 py-4 rounded-md active:bg-cyan-600 active:ring-2 active:ring-cyan-400 transition font-medium"
          class:text-gray-800={vote !== undefined}
          class:text-gray-200={vote === undefined}
          class:bg-gray-700={vote === undefined}
          class:bg-cyan-500={vote !== undefined}
          class:hover:bg-cyan-400={vote !== undefined}
          disabled={vote === undefined}>End vote ({vote ? vote.id : 'n/a'})</button
        >
      </div>
    {/await}

    <div>
      <VoteResults votes={$votes}>
        <h2 slot="title">
          {#await $currentVote}
            Results
          {:then vote}
            {#if vote}
              Results
            {:else}
              Previous Results
            {/if}
          {:catch}
            error
          {/await}
        </h2>
      </VoteResults>
    </div>
  </Box>
</main>
