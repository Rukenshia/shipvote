<script lang="ts">
  const dev = import.meta.env.DEV;
  import type { Channel, Ship, Vote } from "../../lib/api";
  import CreatorBanner from "../../lib/components/CreatorBanner.svelte";
  import VoteForShip from "../../lib/components/VoteForShip.svelte";
  import VoteProgressOverlay from "../../lib/components/VoteProgressOverlay.svelte";
  import { registerPubSubHandler, fakePubSubVoting } from "../../lib/pubsub";
  import { api, vote, warships } from "../../lib/store";
  import { onMount } from "svelte";
  import { writable, type Writable } from "svelte/store";
  import { scale } from "svelte/transition";

  let channel: Writable<Channel> = writable();

  let hidden = false;

  onMount(() => {
    registerPubSubHandler();

    window.Twitch.ext.onContext(async (data, changed) => {
      if (data.game !== "World of Warships") {
        console.log("game is not WoWS");
        return;
      }

      if (!$channel) {
        console.info("Starting Shipvote session");

        if (!$api) {
          console.error("Game is WoWS, but API is not available");
          return;
        }

        $channel = await $api.getChannelInfo();
      }
    });

    if (dev) {
      return fakePubSubVoting();
    }

    return () => {};
  });

  vote.subscribe(($vote) => {
    if (!$vote) {
      // reset hidden flag as we haven't voted if there is no vote
      // there is probably a better way of doing this
      hidden = false;
    }
  });
</script>

{#await $warships then $warships}
  {#if $vote}
    {#if $vote.status === "open"}
      <div class="fixed left-0 top-0">
        <VoteProgressOverlay {vote} warships={$warships} />
      </div>
      {#if !hidden}
        <div
          class="h-full flex items-center justify-center py-16 overflow-hidden"
          in:scale={{ duration: 300 }}
          out:scale={{ duration: 300 }}
        >
          <div class="relative max-w-2xl w-full text-white">
            <div
              class="h-full z-20 p-4 pt-2 relative bg-gradient-to-b from-cyan-800 to-cyan-950 rounded-xl opacity-80 hover:opacity-100 transition-all duration-300"
            >
              <div class="max-h-64 overflow-y-auto">
                <VoteForShip
                  vote={$vote}
                  warships={$warships}
                  close={() => (hidden = true)}
                />

                <div
                  class="opacity-50 mt-4 bg-cyan-950 px-2 py-1 text-xs rounded-lg"
                >
                  <CreatorBanner />
                </div>
              </div>
            </div>
            <div
              class="absolute -inset-1 rounded-md blur-md bg-gradient-to-br from-blue-500/50 via-sky-800/60 to-cyan-600/50 z-10"
            />
          </div>
        </div>
      {/if}
    {/if}
  {/if}
{/await}
