<script lang="ts">
  import { api, vote } from "../store";
  import { createEventDispatcher } from "svelte";

  import VoteResults from "./VoteResults.svelte";
  import Box from "./Box.svelte";
  import type { Vote } from "../api";
  import RemainingVoteTime from "./RemainingVoteTime.svelte";

  const dev = import.meta.env.DEV;
  const dispatch = createEventDispatcher();

  async function closeVote() {
    await $api.closeVote($vote.id);
    dispatch("close", { id: $vote.id });

    $api.getOpenVote().then((v: Vote) => ($vote = v));

    if (dev) {
      window.Twitch.ext.send("broadcast", "application/json", {
        type: "vote_status",
        data: { id: $vote.id, status: "closed" },
      });
    }
  }
</script>

{#if $vote && $vote.status === "open"}
  <Box>
    The vote is currently

    <span class="font-medium"> open </span>

    {#if $vote && $vote.status === "open"}
      <div class="mt-2 flex flex-col justify-around gap-2 px-4">
        <button
          on:click={() => closeVote()}
          class="rounded-md px-8 py-4 font-medium transition active:bg-cyan-600 active:ring-2 active:ring-cyan-400"
          class:text-gray-800={$vote !== undefined}
          class:text-gray-200={$vote === undefined}
          class:bg-gray-700={$vote === undefined}
          class:bg-cyan-500={$vote !== undefined}
          class:hover:bg-cyan-400={$vote !== undefined}
          disabled={$vote === undefined}>Close vote</button
        >

        {#if vote.ends_at}
          <RemainingVoteTime
            started_at={$vote.created_at}
            ends_at={$vote.ends_at}
          />
        {/if}
      </div>
    {/if}

    <div>
      {#if $vote && $vote.status === "open"}
        <VoteResults votes={$vote.votes} />
      {/if}
    </div>
  </Box>
{/if}
