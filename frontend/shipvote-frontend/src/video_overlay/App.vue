<template>
  <div :class="theme">
    <VoteProgress v-if="voting" :ships="ships" :voting="voting" :totalVotes="totalVotes"/>
    <div class="selection" v-bind:data-active="selecting">
      <ShipSelection
        @vote="voteForShip"
        :ships="ships"
        :enableVoting="true"
        :voted="voted"
        :maxHeight="maxHeight"
        :totalVotes="totalVotes"
      />
    </div>

    <div
      class="vote-notice"
      v-bind:data-active="voting && !selecting && !voted"
      v-bind:data-initial="voteStarted"
      v-bind:data-dismissed="selecting || voted"
    >
      <div class="cta raised" @click="selecting = true">
        <i class="material-icons">error_outline</i>
        <span>Vote for a Ship now!</span>
      </div>
    </div>
  </div>
</template>

<script>
import { Socket } from 'phoenix';
import { BASE_WS_URL, BASE_URL, ShipvoteApi } from '../shipvote';
import ShipSelection from './ShipSelection';
import VoteProgress from './VoteProgress';

const get = window.axios.get;

window.App = {
  name: 'app',
  components: { ShipSelection, VoteProgress },
  data() {
    return {
      channel: undefined,
      theme: 'light',
      api: undefined,

      // Flag to only do API calls when the game is set
      gameIsWows: true,

      // Active vote
      vote: undefined,

      // Max window height
      maxHeight: 200,

      // Socket is connected
      connected: false,
      // Vote is enabled
      voting: false,

      // Used to show the text initially, then dismiss it
      voteStarted: false,

      // User is selecting a ship
      selecting: false,
      // User has voted
      voted: false,

      // total votes
      totalVotes: 0,

      // Ships available to vote
      ships: []
    };
  },
  created() {
    window.Twitch.ext.onContext((data, changed) => {
      if (changed.includes('theme')) {
        this.theme = data.theme;
      }

      this.gameIsWows = data.game === 'World of Warships' || data.game === '';

      if (changed.includes('displayResolution')) {
        this.maxHeight =
          parseInt(
            data['displayResolution'].slice(
              data['displayResolution'].indexOf('x') + 1
            ),
            10
          ) - 160;
      }
    });
    window.Twitch.ext.onAuthorized(authData => {
      this.api = new ShipvoteApi(BASE_URL, authData.token, authData.channelId);

      this.api.getChannelInfo().then(info => {
        this.channel = info;

        window.Twitch.ext.listen('broadcast', (target, contentType, message) => {
          if (contentType !== 'application/json') {
            return;
          }

          const data = JSON.parse(atob(message));

          this.handlePubSubMessage(data);
        });
      });
    });
  },
  methods: {
    handlePubSubMessage(message) {
      switch(message.type) {
      case 'vote_progress':
        this.handleVoteProgressMessage(message.data);
        break;
      case 'vote_status':
        this.handleVoteStatusMessage(message.data);
        break;
      }
    },
    handleVoteStatusMessage(data) {
      if (data.status == "open") {
        // Vote started before listening to messages, grab the vote
        this.api.getVote(data.id).then(vote => {
          this.voteStarted = true;
          setTimeout(() => {
            this.voteStarted = false;
          }, 5000);
          this.voting = true;

          // Get ships
          // Update votes in an interval
          // Terminate interval
          this.api.getWarships(vote.ships).then(ships => {
            this.ships = ships.map(s => ({ ...s, votes: 0 }));
            this.vote = vote;
          });
        });
        return;
      }

      this.voting = false;
      this.voteStarted = false;
    },
    handleVoteProgressMessage(data) {
      if (!this.vote) {
        this.handleVoteStatusMessage({ status: "open", id: data.id });
        return;
      }

      let totalVotes = 0;
      Object.keys(data.voted_ships).forEach(shipId => {
        totalVotes += data.voted_ships[shipId];
        shipId = parseInt(shipId, 10);
        const shipIdx = this.ships.findIndex(s => s.id === shipId);

        if (shipIdx !== -1) {
          Vue.set(this.ships, shipIdx, {
            ...this.ships[shipIdx],
            votes: data.voted_ships[shipId]
          });
        }
      });

      this.totalVotes = totalVotes;
    },
    voteForShip(ship) {
      if (this.voted) {
        return;
      }

      this.voted = true;
      this.selecting = false;

      this.api.voteForShip(this.vote.id, ship.id);
    }
  }
};

export default window.App;
</script>

<style lang="scss">
@import '../darkmode';
@import '../typography';
@import '../card';

.vote-notice {
  position: fixed;
  left: 50%;
  bottom: 88px;
  transform: translateX(-50%);

  &[data-active='true'] .cta {
    opacity: 1;
  }

  &[data-initial='true'] .cta,
  &[data-active='true']:hover .cta {
    width: 186px;
  }

  &[data-active='true']:hover .cta {
    transition: width 0.5s;
    cursor: pointer;
  }

  &[data-dismissed='true'] .cta {
    transition: width 0.5s, opacity 0.2s;
  }

  .cta {
    display: flex;
    align-items: center;
    background-color: #ffffff;
    border-radius: 20px;
    padding: 8px 12px;

    width: 24px;
    height: 24px;
    overflow: hidden;
    opacity: 0;
    transition: width 0.5s 0.8s, opacity 1s ease-in;

    span {
      margin-left: 4px;
      font-size: 16px;
      font-family: Roboto;

      white-space: nowrap;
      overflow: hidden;
    }
  }
}

.selection {
  position: fixed;
  left: 8px;
  top: 80px;
  width: 386px;

  .card {
    height: 0;
    opacity: 0;
    visibility: hidden;
    overflow-y: scroll;

    transition: visibility 0s linear 0.5s, height 0.5s, opacity 0.45s;
  }

  &[data-active='true'] {
    .card {
      visibility: visible;
      transition-delay: 0s;
      opacity: 1;
    }
  }
}

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}
</style>
