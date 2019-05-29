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

      if (changed.includes('game')) {
        this.gameIsWows = data.game === 'World of Warships';
      }

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

        const updateVotes = voteId => {
          if (!this.gameIsWows) {
            this.voting = false;
            this.noteDismissed = false;
            this.voted = false;
            this.selecting = false;
            this.totalVotes = 0;
            this.ships = [];

            setTimeout(() => { checkOpenVote() }, this.channel.vote_status_delay);
            return;
          }

          this.api.getVote(voteId).then(vote => {
            if (!vote || vote.status === 'closed') {
              this.vote = vote;
              this.voting = false;
              checkOpenVote();
              return;
            }

            // an open vote exists, reset the delays to the default values
            this.channel.vote_status_delay = 7500;
            this.channel.vote_progress_delay = 4000;

            let totalVotes = 0;
            Object.keys(vote.votes).forEach(shipId => {
              totalVotes += vote.votes[shipId];
              shipId = parseInt(shipId, 10);
              const shipIdx = this.ships.findIndex(s => s.id === shipId);

              if (shipIdx !== -1) {
                Vue.set(this.ships, shipIdx, {
                  ...this.ships[shipIdx],
                  votes: vote.votes[shipId]
                });
              }
            });

            this.vote = vote;
            this.totalVotes = totalVotes;
          }).catch(e => console.error(`updateVotes: ${e}`))
            .then(() => {
              if (this.voting) {
                setTimeout(() => updateVotes(voteId), this.channel.vote_progress_delay);
              }
            });
        };

        const checkOpenVote = () => {
          if (!this.gameIsWows) {
            setTimeout(() => { checkOpenVote() }, 60000);
            return;
          }

          this.api.getOpenVote().then(vote => {
            this.vote = vote;
            if (vote && !this.voting) {
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
                updateVotes(vote.id);
              });
            } else {
              this.voting = false;
              this.noteDismissed = false;
              this.voted = false;
              this.selecting = false;
              this.totalVotes = 0;
              this.ships = [];
            }
          }).catch(e => console.error(`checkOpenVote: ${e}`))
            .then(() => {
              if (!this.voting) {
                setTimeout(() => { checkOpenVote() }, this.channel.vote_status_delay);
              }
            });
        };

        checkOpenVote();
      });
    });
  },
  methods: {
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
