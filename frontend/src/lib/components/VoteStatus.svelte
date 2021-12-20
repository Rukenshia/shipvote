<script lang="ts">
  import { api } from '$lib/store';

  import { derived, Writable, writable } from 'svelte/store';

  import type { Vote } from '$lib/api';
  import VoteResults from './VoteResults.svelte';
  import Box from './Box.svelte';

  let currentVote: Writable<Promise<Vote>> = writable(null);
  let mostRecentVote: Writable<Promise<Vote>> = writable(null);

  $: if ($api) {
    $currentVote = $api.getOpenVote();
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
