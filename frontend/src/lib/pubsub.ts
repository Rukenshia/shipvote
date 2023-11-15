import type { ShipvoteApi } from "./api";
import { api, vote } from "./store";
import { get } from "svelte/store";

interface VoteStatusMessage {
  id: number;
  status: "open" | "closed";
}

interface VoteProgressMessage {
  id: number;
  voted_ships: { [key: number]: number };
}

interface Message {
  type: "vote_status" | "vote_progress";
  data: VoteStatusMessage | VoteProgressMessage;
}

export class PubSubHandler extends EventTarget {
  private fn: (target: string, contentType: string, message: string) => void = (
    _target: string,
    contentType: string,
    message: string,
  ) => {
    if (contentType !== "application/json") {
      return;
    }

    const data = JSON.parse(atob(message));
    this.handlePubSubMessage(data);
  };

  init() {
    window.Twitch.ext.listen("broadcast", this.fn);
  }

  deinit() {
    window.Twitch.ext.unlisten("broadcast", this.fn);
  }

  handlePubSubMessage(message: Message) {
    const currentVote = get(vote);
    const currentApi: ShipvoteApi = get(api);

    if (!currentApi) {
      console.log("no api in handlePubSubMessage");
      return;
    }

    switch (message.type) {
      case "vote_status":
        // things that can happen when a vote_status message is received:
        //
        // - a vote is opened
        // - a vote is closed and we knew about this vote
        // - a vote is closed and we didn't know about this vote
        //
        if (currentVote && message.data.status === "closed") {
          vote.update(() => null);
          console.log(`vote ${currentVote.id} closed`);
          this.dispatchEvent(new Event("vote_closed"));
          return;
        }

        if (!currentVote && message.data.status === "open") {
          // TODO: replace with data in pubsub message
          //
          // we don't know about this vote yet, so we need to fetch it
          // use a timeout to cause less load on backend
          setTimeout(
            async () => {
              const newVote = await currentApi.getVote(message.data.id);
              vote.update(() => newVote);
              console.log(`vote ${newVote.id} opened`);
              this.dispatchEvent(new Event("vote_opened"));
            },
            Math.floor(Math.random() * 2001),
          );
        }
        break;
      case "vote_progress":
        // this event is only sent when a vote is open
        // but we might not know about the vote yet
        if (!currentVote) {
          // TODO: replace with data in pubsub message
          //
          // use a timeout to cause less load on backend
          setTimeout(
            async () => {
              const newVote = await currentApi.getVote(message.data.id);
              vote.update(() => newVote);

              console.log(
                `vote ${newVote.id} opened (detected via vote_progress)`,
              );
              this.dispatchEvent(new Event("vote_opened"));
            },
            Math.floor(Math.random() * 2001),
          );
          return;
        }

        vote.update(() => ({
          ...currentVote,
          votes: message.data.voted_ships,
        }));
        this.dispatchEvent(new Event("vote_progress"));
    }
  }
}

export function fakePubSubVoting() {
  const interval = setInterval(async () => {
    const currentApi = get(api);
    const currentVote = get(vote);

    if (!currentApi) {
      console.log("no api in fakePubSubVoting");
      return;
    }

    const openVote = await currentApi.getOpenVote();

    if (!openVote && currentVote) {
      window.Twitch.ext.send("broadcast", "application/json", {
        type: "vote_status",
        data: { id: currentVote.id, status: "closed" },
      });
      return;
    }

    if (openVote && !currentVote) {
      window.Twitch.ext.send("broadcast", "application/json", {
        type: "vote_status",
        data: { id: openVote.id, status: "open" },
      });
    }

    if (!currentVote) {
      return;
    }

    const fullVote = await currentApi.getVote(openVote.id);

    window.Twitch.ext.send("broadcast", "application/json", {
      type: "vote_progress",
      data: { id: fullVote.id, voted_ships: fullVote.votes },
    });
  }, 1000);

  return () => {
    clearInterval(interval);
  };
}
