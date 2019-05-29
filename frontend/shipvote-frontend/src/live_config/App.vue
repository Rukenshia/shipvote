<template>
  <mdc-layout-grid :class="theme">
    <mdc-dialog
      v-model="showDialog"
      title="Year of the Filter Rework"
      accept="Alright"
      @accept="dismissDialog"
    >
      The filters for selecting ships for votes have been reworked to allow more customization.
      Please submit feedback so I can keep improving it!
    </mdc-dialog>

    <mdc-layout-cell :span="12" v-if="error">
      <span v-if="!voting" class="typography__color--error">Could not load configuration</span>
    </mdc-layout-cell>
    <mdc-layout-cell :span="12" v-if="!loaded_configuration">
      <mdc-linear-progress indeterminate></mdc-linear-progress>
    </mdc-layout-cell>
    <mdc-layout-cell :span="12" v-if="!configured && loaded_configuration">
      <mdc-card class="mdc-card--flat">
        <mdc-card-text>
          <mdc-body>
            You did not configure this extension yet. Head over to your twitch dashboard, then go to "Extensions", "My Extensions"
            and Click on the cog icon to configure this extension.
          </mdc-body>

          <mdc-button outlined @click="loadChannelConfig">Reload</mdc-button>
        </mdc-card-text>
      </mdc-card>
    </mdc-layout-cell>
    <mdc-layout-cell :span="12" v-if="configured && loaded_configuration">
      <mdc-card class="mdc-card--flat" style="text-align: center">
        <mdc-card-header>
          <mdc-headline>
            The vote is
            <strong v-if="voting">open</strong>
            <strong v-if="!voting">closed</strong>
          </mdc-headline>

          <mdc-body
            v-if="!voting"
          >You have selected {{selectedShips.length}} ships for the next vote.</mdc-body>

          <mdc-button
            :unelevated="true"
            v-if="!voting"
            @click="openVote"
            class="mdc-button--primary"
            :disabled="selectedShips.length === 0"
          >Open</mdc-button>
          <mdc-button
            :unelevated="true"
            v-else
            @click="closeVote"
            class="mdc-button--danger"
          >Close</mdc-button>

          <br>
          <br>
        </mdc-card-header>
      </mdc-card>

      <mdc-headline>Previous results</mdc-headline>

      <template v-if="loadingClosedVotes">
        <mdc-layout-grid>
          <mdc-layout-cell :span="4">
            <mdc-linear-progress indeterminate></mdc-linear-progress>
          </mdc-layout-cell>
        </mdc-layout-grid>
      </template>
      <template v-else>
        <VoteResults :votes="closedVotes" :ships="ships"></VoteResults>
      </template>

      <div v-if="voting">
        <mdc-headline>Vote Statistics</mdc-headline>
        <mdc-list two-line bordered>
          <mdc-list-item>
            <span>
              <strong>{{stats.votes}}</strong>
            </span>
            <span slot="secondary">Participants</span>
          </mdc-list-item>
          <mdc-list-item>
            <span>
              <strong>{{mostVoted}}</strong>
            </span>
            <span slot="secondary">Most Votes</span>
          </mdc-list-item>
        </mdc-list>

        <mdc-headline tag="h3">Vote results</mdc-headline>
        <mdc-list two-line bordered v-if="sortedVotes.length > 0">
          <mdc-list-item v-for="ship in sortedVotes" :key="ship.id">
            <img
              slot="start-detail"
              :src="ship.image"
              width="56"
              height="auto"
              :alt="`Image of ${ship.name}`"
            >
            <span>
              <strong>{{ship.name}}</strong>
            </span>
            <span slot="secondary">{{ship.votes}} vote{{ship.votes === 1 ? '' : 's'}}</span>
          </mdc-list-item>
        </mdc-list>
        <mdc-text typo="body1" style="padding-left: 8px" v-else>
          Nothing to show yet
        </mdc-text>
      </div>
      <div v-show="!voting">
        <mdc-headline>Ship selection</mdc-headline>

        <mdc-layout-grid>
          <mdc-layout-cell :phone="2" :tablet="2" :desktop="2">
            <mdc-select class="fullwidth" v-model="bulkAdd.nations" label="Nation">
              <template v-for="nation in filters.nations">
                <option :key="nation">{{nation}}</option>
              </template>
            </mdc-select>
          </mdc-layout-cell>
          <mdc-layout-cell :phone="2" :tablet="2" :desktop="2">
            <mdc-select class="fullwidth" v-model="bulkAdd.tiers" label="Tier">
              <template v-for="tier in filters.tiers">
                <option :key="tier">{{tier}}</option>
              </template>
            </mdc-select>
          </mdc-layout-cell>
          <mdc-layout-cell :phone="2" :tablet="2" :desktop="2">
            <mdc-select class="fullwidth" v-model="bulkAdd.types" label="Class">
              <template v-for="type in filters.types">
                <option :key="type">{{type}}</option>
              </template>
            </mdc-select>
          </mdc-layout-cell>
          <mdc-layout-cell :phone="2" :tablet="2" :desktop="2">
            <mdc-checkbox label="Premiums" v-model="bulkAdd.premiums"/>
          </mdc-layout-cell>

          <mdc-layout-cell :span="6">
            <mdc-button
              raised
              class="fullwidth"
              @click="doBulkAdd"
              :disabled="bulkAddShips.length === 0"
            >Add {{bulkAddShips.length}} ships</mdc-button>
          </mdc-layout-cell>
          <mdc-layout-cell :span="6">
            <mdc-button
              class="fullwidth"
              @click="selectedShips = []"
              :disabled="selectedShips.length === 0"
            >
              <i class="material-icons">delete</i> reset
            </mdc-button>
          </mdc-layout-cell>
        </mdc-layout-grid>

        <mdc-layout-grid>
          <mdc-layout-cell :phone="4" :tablet="8" :desktop="12">
            <mdc-textfield
              box
              class="fullwidth"
              v-model="search"
              label="Ship name"
              trailing-icon="search"
            />
          </mdc-layout-cell>
        </mdc-layout-grid>

        <mdc-list bordered two-line>
          <mdc-list-item v-for="ship in searchedSelectedShips" :key="ship.id">
            <img
              slot="start-detail"
              :src="ship.image"
              width="56"
              height="auto"
              :alt="`Image of ${ship.name}`"
            >
            <span>
              <strong>{{ship.name}}</strong>
            </span>
            <span slot="secondary">Tier: {{ship.tier}}, Nation: {{ship.nation}}</span>

            <mdc-button slot="end-detail" raised @click="deselect(ship)">remove</mdc-button>
          </mdc-list-item>
          <mdc-list-item v-for="ship in availableShips" :key="ship.id">
            <img
              slot="start-detail"
              :src="ship.image"
              width="56"
              height="auto"
              :alt="`Image of ${ship.name}`"
            >
            <span>
              <strong>{{ship.name}}</strong>
            </span>
            <span slot="secondary">Tier: {{ship.tier}}, Nation: {{ship.nation}}</span>

            <mdc-button slot="end-detail" @click="select(ship)">add</mdc-button>
          </mdc-list-item>
        </mdc-list>
      </div>

      <mdc-card class="mdc-card--flat">
        <mdc-card-text style="padding-bottom: 8px">
          <mdc-body typo="body2">
            Got feedback, need help or want to give me some love? Contact me on Twitch(rukenshia), Discord (Rukenshia#4396), or
            <a
              href="mailto:jan@ruken.pw"
            >via mail</a>
          </mdc-body>
        </mdc-card-text>
      </mdc-card>
    </mdc-layout-cell>
  </mdc-layout-grid>
</template>

<script>
import { Socket } from 'phoenix';
import { BASE_WS_URL, BASE_URL, ShipvoteApi } from '../shipvote';
import VoteResults from './VoteResults';

const get = window.axios.get;

window.App = {
  name: 'app',
  components: {
    VoteResults,
  },
  data() {
    return {
      socket: undefined,
      channel: undefined,
      channelId: undefined,
      token: '',
      theme: 'light',
      api: undefined,
      vote: undefined,

      loadingClosedVotes: true,
      closedVotes: [],

      viewSetting: 0,

      connecting: true,
      connected: false,
      configured: false,
      loaded_configuration: false,
      error: false,

      search: '',
      showDialog: false,
      bulkAdd: {
        nations: 'all',
        tiers: 'all',
        types: 'all',
        premiums: true,
      },
      filters: {
        nations: ['all', 'commonwealth', 'france', 'germany', 'italy', 'japan', 'pan_america', 'pan_asia', 'poland', 'uk', 'usa', 'ussr'],
        tiers: ['all', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'],
        types: ['all', 'Battleship', 'Cruiser', 'Destroyer', 'AirCarrier'],
      },
      selectedShips: [],


      stats: {
        votes: 0,

        ship_votes: {}
      },

      ships: []
    };
  },
  created() {
    window.Twitch.ext.onContext(ctx => {
      this.theme = ctx.theme;
    });

    window.Twitch.ext.onAuthorized(data => {
      if (this.socket) {
        this.socket.disconnect();
      }

      this.channelId = data.channelId;
      this.token = data.token;

      this.loadChannelConfig().then(() => {
        // Restore ships from localStorage
        this.loadPreviouslySelectedShips();

        this.api = new ShipvoteApi(BASE_URL, this.token, this.channelId);
        this.updateClosedVotes();

        const updateOpenVote = () => {
          this.api
            .getOpenVote()
            .then(vote => {
              this.vote = vote;

              if (!vote) {
                return;
              }

              this.stats.ship_votes = vote.votes;

              const votes = Object.values(vote.votes);

              this.stats.votes =
                votes.length > 0 ? votes.reduce((p, v) => p + v) : 0;
            })
            .catch(e => console.error(`loadChannelConfig: ${e}`))
            .then(() => {
              setTimeout(() => updateOpenVote(), 5000);
            });
        };

        updateOpenVote();
      });
    });
  },
  computed: {
    voting() {
      return this.vote !== undefined && this.vote.status === 'open';
    },
    bulkAddShips() {
      return this.ships
        .filter(s => s.enabled)
        .filter(s => !this.selectedShips.includes(s))
        .filter(s => this.bulkAdd.premiums || !s.premium)
        .filter(s => this.bulkAdd.nations === 'all' || s.nation === this.bulkAdd.nations)
        .filter(s => this.bulkAdd.tiers === 'all' || s.tier === tierToInt(this.bulkAdd.tiers))
        .filter(s => this.bulkAdd.types === 'all' || s.type === this.bulkAdd.types);
    },
    searchedSelectedShips() {
      return this.selectedShips.filter(s => s.name.startsWith(this.search));
    },
    availableShips() {
      return this.ships
        .filter(s => s.enabled)
        .filter(s => s.name.startsWith(this.search))
        .filter(s => !this.selectedShips.includes(s))
        .sort((a, b) => {
          if (a.tier < b.tier) {
            return 1;
          } else if (a.tier === b.tier) {
            return 0;
          }
          return -1;
        });
    },
    sortedVotes() {
      if (this.ships.length === 0) {
        return [];
      }

      const sorted = Object.keys(this.stats.ship_votes).map(v => ({
        ...this.ships.find(s => s.id === parseInt(v, 10)),
        votes: this.stats.ship_votes[v]
      }));

      sorted.sort((a, b) => {
        const av = this.stats.ship_votes[a.id] || 0;
        const bv = this.stats.ship_votes[b.id] || 0;

        if (av < bv) {
          return 1;
        } else if (av === bv) {
          return 0;
        }
        return -1;
      });

      return sorted;
    },
    mostVoted() {
      if (this.ships.length === 0) {
        return 'none';
      }

      const sorted = Object.keys(this.stats.ship_votes).map(v => ({
        ...this.ships.find(s => s.id === parseInt(v, 10)),
        votes: this.stats.ship_votes[v]
      }));

      sorted.sort((a, b) => {
        const av = this.stats.ship_votes[a.id] || 0;
        const bv = this.stats.ship_votes[b.id] || 0;

        if (av < bv) {
          return 1;
        } else if (av === bv) {
          return 0;
        }
        return -1;
      });

      if (sorted.length === 0 || typeof sorted[0] === 'undefined') {
        return 'none';
      }

      const max = this.stats.ship_votes[sorted[0].id];

      return sorted
        .filter(s => s.votes === max)
        .map(s => s.name)
        .join(', ');
    }
  },
  methods: {
    loadPreviouslySelectedShips() {
      const ids = JSON.parse(window.localStorage.getItem('selectedShips')) || [];
      console.log(this.ships);

      this.selectedShips = this.ships.filter(({ id }) => ids.includes(id));
    },
    storeSelectedShips() {
      window.localStorage.setItem('selectedShips', JSON.stringify(this.selectedShips.map(s => s.id)));
    },
    loadChannelConfig() {
      this.loaded_configuration = false;
      return get(`${BASE_URL}/api/settings/channels/${this.channelId}`, {
        headers: {
          'Content-Type': 'application/json',
          authorization: `Bearer ${this.token}`
        }
      })
        .then(res => {
          this.ships = res.data['data']['ships'];
          this.configured = true;
        })
        .catch(e => {
          if (e.response.status === 404) {
            this.configured = false;
          } else {
            console.error(e);
            this.error = true;
          }
        })
        .then(() => {
          this.loaded_configuration = true;
        });
    },
    openVote() {
      this.stats.votes = 0;
      this.stats.ship_votes = {};
      this.api.openVote(this.selectedShips.map(s => s.id)).then(vote => {
        this.vote = vote;
        this.storeSelectedShips();
      });
    },
    closeVote() {
      this.api.closeVote(this.vote.id).then(vote => {
        this.vote = vote;
        this.updateClosedVotes();
      });
    },
    updateClosedVotes() {
      this.api.getClosedVotes().then(votes => {
        this.closedVotes = votes;
        this.loadingClosedVotes = false;
      });
    },
    doBulkAdd() {
      this.selectedShips.push(...this.bulkAddShips);
      this.sortSelectedShips();
    },
    select(ship) {
      this.selectedShips.push(ship);
      this.sortSelectedShips();
    },
    deselect(ship) {
      const idx = this.selectedShips.findIndex(s => s.id === ship.id);

      this.selectedShips.splice(idx, 1);
    },
    sortSelectedShips() {
      this.selectedShips = this.selectedShips.sort((a, b) => {
        if (a.tier < b.tier) {
          return 1;
        } else if (a.tier == b.tier) {
          return 0;
        }
        return -1;
      });
    },
    dismissDialog() {
      window.localStorage.setItem('showDialogDismissed', true);
      this.showDialog = false;
    },
  }
};

function tierToInt(tier) {
  return {
    'I': 1,
    'II': 2,
    'III': 3,
    'IV': 4,
    'V': 5,
    'VI': 6,
    'VII': 7,
    'VIII': 8,
    'IX': 9,
    'X': 10
  }[tier] || 0;
}

export default window.App;
</script>

<style lang="scss">
@import '../darkmode';
@import '../typography';
@import '../card';
@import '../list';

.button {
  border-radius: 4px;
  padding: 8px;
  background-color: #6441a4;

  cursor: pointer;

  font-weight: normal;
  color: white;
  text-transform: uppercase;

  &:hover {
    background-color: lighten(#6441a4, 5%);
  }
}

.mdc-list.mdc-list--bordered li:first-child {
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
}

.mdc-list.mdc-list--bordered li:last-child {
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

.mdc-card.mdc-card--flat {
  padding: 4px;

  box-shadow: none;
  border-radius: 8px;
  background-color: #f8f9fa;

  color: #5f6368;
}

.mdc-button.mdc-button--danger {
  --mdc-theme-primary: rgba(210, 77, 87, 1);
}

.mdc-button.mdc-button--primary {
  --mdc-theme-primary: rgba(63, 195, 128, 1);
}

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}

.fullwidth {
  width: 100%;
}
</style>
