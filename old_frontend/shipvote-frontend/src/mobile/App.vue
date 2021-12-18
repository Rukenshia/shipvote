<template>
  <div class="app" :class="theme">
    <mdc-linear-progress indeterminate v-if="loading"></mdc-linear-progress>
    <template v-else>
      <template v-if="!vote">
        <mdc-headline>No vote available</mdc-headline>

        <span class="mdc-typography">Wait for the streamer to open a new vote.</span>
      </template>
      <template v-else>
        <div class="top-bar">
          <mdc-layout-grid style="padding: 0">
            <mdc-layout-cell span="12">
              <mdc-button @click="toggleFilters">
                <i class="material-icons">filter_list</i> Filter
              </mdc-button>
              <mdc-button v-if="filtered" @click="resetFilters" :unelevated="true">
                <i class="material-icons">clear</i> Reset
              </mdc-button>
            </mdc-layout-cell>
          </mdc-layout-grid>

          <div class="card__divider"></div>

          <div v-show="filtering" class="filters">
            <Filters
              ref="refFilter"
              :tiers="availableTiers"
              :nations="availableNations"
              @updateFilter="updateFilter"
            ></Filters>
          </div>
        </div>
        <mdc-list two-line :interactive="selecting">
          <mdc-list-item
            v-for="ship in filteredShips"
            :key="ship.id"
            :selected="selectedShip && selectedShip.id === ship.id"
            @click="voteForShip(ship)"
          >
            <img
              slot="start-detail"
              :src="ship.image"
              width="56px"
              height="auto"
              :alt="`Image of ${ship.name}`"
            />
            <span>{{ship.name}}</span>
            <span
              slot="secondary"
              v-if="selectedShip && selectedShip.id === ship.id"
            >You voted for this ship</span>
            <span slot="secondary" v-else>Tier: {{ship.tier}}, Nation: {{ship.nation}}</span>

            <div slot="end-detail" v-show="ship.votes > 0">
              <span class="mdc-typography">{{ship.votes}} vote{{ship.votes > 1 ? 's' : ''}}</span>

              <mdc-linear-progress :progress="ship.votes === 0 ? 0 : ship.votes / totalVotes"></mdc-linear-progress>
            </div>
          </mdc-list-item>
        </mdc-list>
      </template>
    </template>
  </div>
</template>

<script>
import { BASE_WS_URL, BASE_URL, ShipvoteApi } from "../shipvote";
import Filters from "../shared/Filters";
import Appsignal from "../shared/appsignal";

const get = window.axios.get;
const shipTypePriority = ["Destroyer", "Cruiser", "Battleship", "AirCarrier"];

window.App = {
  name: "app",
  components: { Filters },
  data() {
    return {
      loading: true,
      theme: "dark",
      api: undefined,
      channel: null,

      updateVotesTimeout: null,
      checkOpenVoteTimeout: null,

      gameIsWows: true,

      // Active vote
      vote: undefined,
      voting: false,

      // User is selecting a ship
      selecting: true,

      // The user selected ship
      selectedShip: null,

      // total votes
      totalVotes: 0,

      // Ships available to vote
      ships: [],

      // Filters
      filters: {},
      filtering: false
    };
  },
  created() {
    window.Twitch.ext.onContext((data, changed) => {
      if (changed.includes("theme")) {
        this.theme = data.theme;
      }

      this.gameIsWows = data.game === "World of Warships" || data.game === "";
    });
    window.Twitch.ext.onAuthorized(authData => {
      this.api = new ShipvoteApi(BASE_URL, authData.token, authData.channelId);

      this.api
        .getChannelInfo()
        .then(info => {
          this.channel = info;
          this.loading = false;

          window.Twitch.ext.listen(
            "broadcast",
            (target, contentType, message) => {
              if (contentType !== "application/json") {
                return;
              }

              const data = JSON.parse(atob(message));

              this.handlePubSubMessage(data);
            }
          );
        })
        .catch(err => {
          Appsignal.sendError(err);
          console.error(err);
        });
    });
  },
  computed: {
    filtered() {
      return (
        (typeof this.filters["tier"] !== "undefined" &&
          this.filters.tier !== "any") ||
        (typeof this.filters["nation"] !== "undefined" &&
          this.filters.nation !== "any")
      );
    },
    availableTiers() {
      const tiers = new Set();
      this.ships.forEach(s => tiers.add(s.tier));

      return [...tiers].sort((a, b) => a - b);
    },
    availableNations() {
      const nations = new Set();
      this.ships.forEach(s => nations.add(s.nation));

      return [...nations].sort((a, b) => a - b);
    },
    filteredShips() {
      return this.ships
        .filter(s => {
          if (
            typeof this.filters.tier === "undefined" ||
            this.filters.tier === "any"
          ) {
            return true;
          }

          return s.tier === this.filters.tier;
        })
        .filter(s => {
          if (
            typeof this.filters.nation === "undefined" ||
            this.filters.nation === "any"
          ) {
            return true;
          }

          return s.nation === this.filters.nation;
        })
        .sort((a, b) => {
          if (a.tier < b.tier) {
            return 1;
          } else if (a.tier > b.tier) {
            return -1;
          } else {
            // sort by type
            const aTypePrio = shipTypePriority.indexOf(a.type);
            const bTypePrio = shipTypePriority.indexOf(b.type);

            if (aTypePrio < bTypePrio) {
              return -1;
            } else if (aTypePrio > bTypePrio) {
              return 1;
            } else {
              // sort alphabetically
              if (a.name < b.name) {
                return -1;
              } else if (a.name == b.name) {
                return 0;
              } else {
                return 1;
              }
            }
          }
        });
    }
  },
  methods: {
    handlePubSubMessage(message) {
      switch (message.type) {
        case "vote_progress":
          this.handleVoteProgressMessage(message.data);
          break;
        case "vote_status":
          this.handleVoteStatusMessage(message.data);
          break;
      }
    },
    handleVoteStatusMessage(data) {
      if (data.status == "open") {
        if (this.vote && this.vote.id == data.id) {
          // The API might have restarted and sent a duplicate event
          return;
        }

        // Vote started before listening to messages, grab the vote
        this.api
          .getVote(data.id)
          .then(vote => {
            this.voting = true;
            this.voted = false;
            this.selecting = true;

            this.api.getWarships(vote.ships).then(ships => {
              this.ships = ships.map(s => ({ ...s, votes: 0 }));
              this.vote = vote;
            });
          })
          .catch(err => {
            Appsignal.sendError(err);
            console.error(err);
          });
        return;
      }

      this.vote = undefined;
      this.voting = false;
      this.voted = false;
      this.selecting = false;
      this.selectedShip = null;
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

      this.selecting = false;
      this.selectedShip = ship;

      this.api.voteForShip(this.vote.id, ship.id).catch(err => {
        console.log("Vote for ship", err);
      });
    },
    toggleFilters() {
      this.filtering = !this.filtering;
    },
    resetFilters() {
      this.$refs.refFilter.reset();
    },
    updateFilter({ name, value }) {
      this.filters = {
        ...this.filters,
        [name]: value
      };
    }
  }
};

export default window.App;
</script>

<style lang="scss">
@import "../darkmode";
@import "../typography";
@import "../card";
@import "../list";

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}

.mdc-list-item__graphic {
  margin-bottom: 10px;
}

body {
  height: 100vh;
  width: 100vw;
  margin: 0;
  padding: 0;
}

.app {
  padding: 1em;
  min-height: 100vh;
}
</style>
