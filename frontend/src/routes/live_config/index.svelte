<script lang="ts">
  import { onMount } from 'svelte';

  import VoteStatus from '$lib/components/VoteStatus.svelte';
  import VoteHistory from '$lib/components/VoteHistory.svelte';
  import Link from '$lib/components/Link.svelte';
  import { api, vote } from '$lib/store';
  import Box from '$lib/components/Box.svelte';
  import type { Vote } from '$lib/api';
  import { derived, Readable, Writable, writable } from 'svelte/store';

  onMount(() => {
    window.Twitch.ext.listen(
      'broadcast',
      (_target: string, contentType: string, message: string) => {
        if (contentType !== 'application/json') {
          return;
        }

        const data = JSON.parse(atob(message));
        handlePubSubMessage(data);
      }
    );
  });

  const closedVotes: Writable<Promise<Vote[]>> = writable(new Promise(() => {}));

  const isVoteOpen: Readable<boolean> = derived(vote, ($vote: Promise<Vote>, setter) => {
    $vote.then((v) => setter(v !== undefined));
  });

  $: if ($api) {
    $closedVotes = $api.getClosedVotes();
  }

  function handlePubSubMessage(data: object) {
    console.log(data);
  }
</script>

<div class="flex flex-col gap-4">
  <Link href="/live_config/new_vote" classes="bg-cyan-900 hover:bg-cyan-800" disabled={$isVoteOpen}
    >New Vote</Link
  >
  <VoteStatus />
  <Box>
    <VoteHistory votes={$closedVotes} />
  </Box>
</div>
