<script lang="ts">
  const dev = import.meta.env.DEV;
  import type { Channel, Ship, Vote } from "../../lib/api";
  import CreatorBanner from "../../lib/components/CreatorBanner.svelte";
  import VoteForShip from "../../lib/components/VoteForShip.svelte";
  import VoteProgressOverlay from "../../lib/components/VoteProgressOverlay.svelte";
  import { PubSubHandler, fakePubSubVoting } from "../../lib/pubsub";
  import { api, vote, warships } from "../../lib/store";
  import { onMount, onDestroy } from "svelte";
  import { writable, type Writable } from "svelte/store";
  import { scale } from "svelte/transition";

  let channel: Writable<Channel> = writable();

  let hidden = false;
  let gameIsWows = false;
  const pubSubHandler = new PubSubHandler();

  onMount(() => {
    pubSubHandler.init();

    let loadingChannel = false;
    let hasContext = false;

    api.subscribe(async ($api) => {
      if (!$api) {
        return;
      }

      if (loadingChannel) {
        return;
      }

      if (hasContext && !gameIsWows) {
        console.log("game is not wows, not getting channel info");
        return;
      }

      loadingChannel = true;

      console.info("starting shipvote session after api became available");

      console.log($api);

      $channel = await $api.getChannelInfo();
    });

    window.Twitch.ext.onContext(async (data, changed) => {
      hasContext = true;
      gameIsWows = data.game === "World of Warships";

      if (data.game !== "World of Warships") {
        // console.log("game is not WoWS");
        return;
      }
      if (!$api) {
        console.error("Game is WoWS, but API is not available");
        return;
      }

      if (!$channel) {
        if (loadingChannel) {
          return;
        }

        loadingChannel = true;
        console.info("Starting Shipvote session");

        $channel = await $api.getChannelInfo();
      }
    });

    pubSubHandler.addEventListener("channel_update", (e: any) => {
      if (e.detail.overlay_position) {
        console.log(
          "channel update. changed overlay position to",
          e.detail.overlay_position,
        );
        $channel.overlay_position = e.detail.overlay_position;
      }
    });

    if (dev) {
      return fakePubSubVoting();
    }

    return () => {};
  });

  onDestroy(() => {
    pubSubHandler.deinit();
  });

  vote.subscribe(($vote) => {
    if (!$vote) {
      // reset hidden flag as we haven't voted if there is no vote
      // there is probably a better way of doing this
      hidden = false;
    }
  });
</script>

{#if $channel}
  {#await $warships then $warships}
    {#if $vote}
      {#if $vote.status === "open"}
        <div
          class="fixed"
          class:left-0={$channel.overlay_position.endsWith("left")}
          class:right-0={$channel.overlay_position.endsWith("right")}
          class:top-0={$channel.overlay_position.startsWith("top")}
          class:bottom-0={$channel.overlay_position.startsWith("bottom")}
        >
          <VoteProgressOverlay {vote} warships={$warships} />
        </div>
        {#if !hidden}
          <div
            class="fixed inset-0 flex items-center justify-center pointer-events-none"
          >
            <div
              class="w-full max-w-2xl h-[calc(100%-10rem)] my-[5rem] flex items-center justify-center pointer-events-auto"
              in:scale|global={{ duration: 300 }}
              out:scale|global={{ duration: 300 }}
            >
              <div class="relative w-full h-full text-white">
                <div
                  class="relative z-20 h-full rounded-xl bg-gradient-to-b from-cyan-800 to-cyan-950 opacity-80 transition-all duration-300 hover:opacity-100"
                  id="vote-for-ship"
                >
                  <div
                    class="h-full flex flex-col space-between overflow-y-auto p-4 pt-2"
                  >
                    <div class="flex-grow">
                      <VoteForShip
                        vote={$vote}
                        warships={$warships}
                        close={() => (hidden = true)}
                      />
                    </div>
                    <div
                      class="flex-shrink mt-4 rounded-lg bg-cyan-950 px-2 py-1 text-xs opacity-50"
                    >
                      <CreatorBanner />
                    </div>
                  </div>
                </div>
                <div
                  class="absolute -inset-1 z-10 rounded-md bg-gradient-to-br from-blue-500/50 via-sky-800/60 to-cyan-600/50 blur-md"
                />
              </div>
            </div>
          </div>
        {/if}
      {/if}
    {/if}
  {/await}
{/if}
