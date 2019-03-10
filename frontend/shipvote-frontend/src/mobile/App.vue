<template>
  <div :class="theme">
    <mdc-linear-progress indeterminate v-if="loading"></mdc-linear-progress>
    <template v-else>
      <mdc-list two-line :interactive="selecting">
        <mdc-list-item v-for="ship in ships"
          :key="ship.id" :selected="selectedShip && selectedShip.id === ship.id"
          @click="voteForShip(ship)"
          >

          <img
            slot="start-detail"
            :src="ship.image"
            width="56px"
            height="auto"
            :alt="`Image of ${ship.name}`"
          >
          <span>
            {{ship.name}}
          </span>
          <span slot="secondary" v-if="selectedShip && selectedShip.id === ship.id">You voted for this ship</span>
          <span slot="secondary" v-else>Tier: {{ship.tier}}, Nation: {{ship.nation}}</span>

          <div slot="end-detail" v-show="ship.votes > 0">
            <span class="mdc-typography">{{ship.votes}} vote{{ship.votes > 1 ? 's' : ''}}</span>

            <mdc-linear-progress :progress="ship.votes === 0 ? 0 : ship.votes / totalVotes"></mdc-linear-progress>
          </div>
        </mdc-list-item>
      </mdc-list>
    </template>
  </div>
</template>

<script>
import { BASE_WS_URL, BASE_URL, ShipvoteApi } from '../shipvote';

const get = window.axios.get;

window.App = {
  name: 'app',
  data() {
    return {
      loading: true,
      theme: 'light',
      api: undefined,

      // Active vote
      vote: undefined,

      // User is selecting a ship
      selecting: true,

      // The user selected ship
      selectedShip: null,

      // total votes
      totalVotes: 0,

      // Ships available to vote
      ships: []
    };
  },
  created() {
    window.Twitch.ext.onContext(data => {
      this.theme = data.theme;
    });
    window.Twitch.ext.onAuthorized(authData => {
      this.api = new ShipvoteApi(BASE_URL, authData.token, authData.channelId);

      this.api.getChannelInfo().then(info => {
        const updateVotes = voteId => {
          this.api.getVote(voteId).then(vote => {
            if (!vote || vote.status === 'closed') {
              checkOpenVote();
              return;
            }

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
                setTimeout(() => updateVotes(voteId), 2500);
              }
            });
        };

        const checkOpenVote = () => {
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
                this.ships = ships.map(s => ({ ...s, votes: 0 })).sort((a, b) => {
                  const byTier = a.tier < b.tier ? 1 : (a.tier == b.tier ? 0 : -1);

                  if (byTier === 0) {
                    return a.name < b.name ? -1 : 1;
                  }
                  return byTier;
                });

                this.loading = false;
                updateVotes(vote.id);
              });
            } else {
              this.loading = false;
              this.selecting = false;
              this.selectedShip = undefined;
              this.totalVotes = 0;
              this.ships = [];
            }
          }).catch(e => console.error(`checkOpenVote: ${e}`))
            .then(() => {
              if (!this.voting) {
                setTimeout(() => checkOpenVote(), 5000);
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

      this.selecting = false;
      this.selectedShip = ship;

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
@import '../list';

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}

.mdc-list-item__graphic {
  margin-bottom: 10px;
}
</style>
