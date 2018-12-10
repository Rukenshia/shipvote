<template>
<mdc-layout-grid :class="theme">
  <mdc-layout-cell :span=12>
    <mdc-card class="mdc-card--flat">
      <mdc-card-text style="padding-left: 16px">
        <mdc-body>Learn how to use this extension <a target="_blank" href="https://shipvote.in.fkn.space/getting-started">here</a>.</mdc-body>
      </mdc-card-text>
    </mdc-card>
  </mdc-layout-cell>

  <mdc-layout-cell :span=12 v-if="error">
    <span v-if="!voting" class="typography__color--error">Could not load configuration</span>
  </mdc-layout-cell>
  <mdc-layout-cell :span=12 v-if="!loaded_configuration">
    <mdc-linear-progress indeterminate></mdc-linear-progress>
  </mdc-layout-cell>
  <mdc-layout-cell :span=12 v-if="!configured && loaded_configuration">
    <mdc-card outlined>
      <mdc-card-header style="padding: 8px" class="typography__color--error">
        No personal configuration
      </mdc-card-header>
      <mdc-card-text style="padding: 8px">
          <mdc-body>You did not configure this extension yet. Head over to your twitch dashboard, then go to "Extensions", "My Extensions"
          and Click on the cog icon to configure this extension.</mdc-body>

          <mdc-button outlined @click="loadChannelConfig">Reload</mdc-button>
      </mdc-card-text>
    </mdc-card>
  </mdc-layout-cell>
  <mdc-layout-cell :span=12 v-if="configured && loaded_configuration">
    <mdc-card class="mdc-card--flat" style="text-align: center">
      <mdc-card-header>
        <mdc-headline>
          Vote is
          <span v-if="voting" class="typography__color--success">open</span>
          <span v-if="!voting" class="typography__color--error">closed</span>
        </mdc-headline>

        <mdc-body v-if="!voting">Based on the current filter, the vote will include {{filteredShips.length}} ships.</mdc-body>

        <mdc-button :unelevated=true v-if="!voting" @click="openVote" class="mdc-button--primary">Open</mdc-button>
        <mdc-button :unelevated=true v-if="voting" @click="closeVote" class="mdc-button--danger">Close</mdc-button>

        <br />
        <br />
      </mdc-card-header>
    </mdc-card>

    <div v-if="voting">
      <mdc-headline>Vote Statistics</mdc-headline>
      <mdc-list two-line bordered>
        <mdc-list-item>
          <span><strong>{{stats.votes}}</strong></span>
          <span slot="secondary">Participants</span>
        </mdc-list-item>
        <mdc-list-item>
          <span><strong>{{mostVoted}}</strong></span>
          <span slot="secondary">Most Votes</span>
        </mdc-list-item>
      </mdc-list>

      <mdc-headline tag="h3">Vote results</mdc-headline>
      <mdc-list two-line bordered>
        <mdc-list-item v-for="ship in sortedVotes" :key="ship.id">
          <img slot="start-detail" :src="ship.image"
         width="56" height="auto" :alt="`Image of ${ship.name}`">
          <span><strong>{{ship.name}}</strong></span>
          <span slot="secondary">{{ship.votes}} vote{{ship.votes === 1 ? '' : 's'}}</span>
        </mdc-list-item>
      </mdc-list>
    </div>
    <div v-show="!voting">
      <mdc-headline>General</mdc-headline>
      <!-- <mdc-textfield v-model="settings.duration" label=" Duration (seconds)" box/> -->
      <mdc-checkbox  label="Premium Ships" v-model="settings.premium"/>


      <mdc-headline>Filters</mdc-headline>

      <div class="mdc-tab-bar" role="tablist">
        <div class="mdc-tab-scroller">
          <div class="mdc-tab-scroller__scroll-area">
            <div class="mdc-tab-scroller__scroll-content">
              <button class="mdc-tab" :class="{'mdc-tab--active': viewSetting === 0}"
                role="tab"
                :aria-selected="viewSetting === 0"
                @click="() => this.viewSetting = 0"
                tabindex="0">
                <span class="mdc-tab__content">
                  <span class="mdc-tab__text-label">Tier</span>
                </span>
                <span v-if="viewSetting === 0" class="mdc-tab-indicator mdc-tab-indicator--active">
                  <span class="mdc-tab-indicator__content mdc-tab-indicator__content--underline"></span>
                </span>
                <span class="mdc-tab__ripple"></span>
              </button>
              <button class="mdc-tab" :class="{'mdc-tab--active': viewSetting === 1}"
                role="tab"
                :aria-selected="viewSetting === 1"
                @click="() => this.viewSetting = 1"
                tabindex="1">
                <span class="mdc-tab__content">
                  <span class="mdc-tab__text-label">Type</span>
                </span>
                <span v-if="viewSetting === 1" class="mdc-tab-indicator mdc-tab-indicator--active">
                  <span class="mdc-tab-indicator__content mdc-tab-indicator__content--underline"></span>
                </span>
                <span class="mdc-tab__ripple"></span>
              </button>
              <button class="mdc-tab" :class="{'mdc-tab--active': viewSetting === 2}"
                role="tab"
                :aria-selected="viewSetting === 2"
                @click="() => this.viewSetting = 2"
                tabindex="2">
                <span class="mdc-tab__content">
                  <span class="mdc-tab__text-label">Nation</span>
                </span>
                <span v-if="viewSetting === 2" class="mdc-tab-indicator mdc-tab-indicator--active">
                  <span class="mdc-tab-indicator__content mdc-tab-indicator__content--underline"></span>
                </span>
                <span class="mdc-tab__ripple"></span>
              </button>
            </div>
          </div>
        </div>
      </div>

      <mdc-layout-grid v-if="viewSetting === 0">
        <template v-for="(v,key) in settings.tiers">
          <mdc-layout-cell :key="key">
            <mdc-checkbox  :label="`Tier ${key + 1}`" v-model="settings.tiers[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>

      <mdc-layout-grid v-if="viewSetting === 1">
        <template v-for="key in Object.keys(settings.types)">
          <mdc-layout-cell :key="key">
            <mdc-checkbox  :label="key" v-model="settings.types[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>

      <mdc-layout-grid v-if="viewSetting === 2">
        <template v-for="key in Object.keys(settings.nations)">
          <mdc-layout-cell :key="key">
            <mdc-checkbox class="checkbox" :label="key" v-model="settings.nations[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>
    </div>

    <mdc-card class="mdc-card--flat">
      <mdc-card-text>
        <mdc-body typo="body2">
          Got feedback, need help or want to give me some love? Contact me on Twitch(rukenshia), Discord (Rukenshia#4396), or <a href="mailto:jan@ruken.pw">via mail</a>
        </mdc-body>
      </mdc-card-text>
    </mdc-card>
  </mdc-layout-cell>
</mdc-layout-grid>
</template>

<script>
import { Socket } from 'phoenix';
import { BASE_WS_URL, BASE_URL } from '../shipvote';

const get = window.axios.get;

window.App = {
  name: 'app',
  data() {
    return {
      socket: undefined,
      channel: undefined,
      channelId: undefined,
      token: '',
      theme: 'light',

      viewSetting: 0,

      connecting: true,
      connected: false,
      configured: false,
      loaded_configuration: false,
      error: false,
      voting: false,

      settings: {
        duration: '60',
        premium: true,
        tiers: [true, true, true, true, true, true, true, true, true, true],
        types: {
          Battleship: true,
          Cruiser: true,
          Destroyer: true,
          AirCarrier: true
        },
        nations: {
          commonwealth: true,
          france: true,
          germany: true,
          italy: true,
          japan: true,
          pan_america: true,
          pan_asia: true,
          poland: true,
          uk: true,
          usa: true,
          ussr: true
        }
      },

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

      this.loadChannelConfig();

      this.socket = new Socket(`${BASE_WS_URL}/socket`, {
        params: { token: this.token }
      });
      this.socket.connect();
      // Now that you are connected, you can join channels with a topic:
      let channel = (this.channel = this.socket.channel(
        `stream:${data.channelId}`,
        {}
      ));
      channel
        .join()
        .receive('ok', resp => {
          this.connected = true;
          this.connecting = false;

          channel.push('get_status');
        })
        .receive('error', resp => {
          this.connecting = false;
        });

      channel.on('status', data => {
        this.voting = data.voting;

        if (data.votes) {
          const values = Object.values(data.votes);
          if (values.length === 0) {
            this.stats.votes = 0;
          } else {
            this.stats.votes = values.reduce((p, c) => p + c);
          }
          this.stats.ship_votes = data.votes;
          this.$forceUpdate();
        }
      });

      channel.on('new_vote', data => {
        if (typeof this.stats.ship_votes[data['ship_id']] === 'undefined') {
          this.stats.ship_votes[data['ship_id']] = 0;
        }
        this.stats.ship_votes = {
          ...this.stats.ship_votes,
          [data['ship_id']]: this.stats.ship_votes[data['ship_id']] + 1
        };

        this.stats.votes++;
        this.$forceUpdate();
      });
    });
  },
  computed: {
    filteredShips() {
      return this.ships
        .filter(s => s.enabled)
        .filter(s => this.settings.tiers[s.tier - 1] === true)
        .filter(s => this.settings.types[s.type] === true)
        .filter(
          s =>
            this.settings.premium ||
            (!this.settings.premium && s.premium === false)
        )
        .filter(s => this.settings.nations[s.nation] === true)
        .map(s => s.id);
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
    loadChannelConfig() {
      this.loaded_configuration = false;
      get(`${BASE_URL}/api/settings/channels/${this.channelId}`, {
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
      if (this.channel) {
        this.channel.push('open_vote', {
          ships: this.filteredShips
        });
      }
    },
    closeVote() {
      if (this.channel) {
        this.channel.push('close_vote');
      }
    }
  }
};

export default window.App;
</script>

<style lang="scss">
@import '../darkmode';
@import '../typography';
@import '../card';

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

.mdc-list-item__graphic {
  margin-top: -32px;
}

.mdc-list .mdc-list-item {
  padding-top: 16px;
}

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}
</style>
