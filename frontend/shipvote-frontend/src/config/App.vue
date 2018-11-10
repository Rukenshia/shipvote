<template>
  <div class="status">
    <p>Status:
      <strong>
        <span v-if="connected" class="typography__color--success">connected</span>
        <span v-if="connecting" class="typography__color--warning">connecting</span>
        <span v-if="!connecting && !connected" class="typography__color--error">failed to connect</span>
      </strong>
    </p>
    <p>Vote status:
      <strong>
        <span v-if="voting" class="typography__color--success">open</span>
        <span v-if="!voting" class="typography__color--error">closed</span>
      </strong>
    </p>

    <mdc-button :raised=true v-if="!voting" @click="openVote">Open vote</mdc-button>
    <mdc-button :raised=true v-if="voting" @click="closeVote">Close vote</mdc-button>

    <div v-if="voting">
      <mdc-headline>Voting stats</mdc-headline>
      <mdc-layout-grid>
        <mdc-layout-cell>
          <mdc-card>
            <mdc-card-header
              :title="`${stats.votes}`"
              subtitle="votes">
            </mdc-card-header>
          </mdc-card>
        </mdc-layout-cell>
        <mdc-layout-cell>
          <mdc-card>
            <mdc-card-header
              :title="`${mostVoted}`"
              subtitle="Top pick">
            </mdc-card-header>
          </mdc-card>
        </mdc-layout-cell>
      </mdc-layout-grid>
    </div>
    <div v-show="!voting">
      <mdc-headline>General</mdc-headline>
      <mdc-layout-grid>
        <mdc-layout-cell>
          <mdc-checkbox  label="Premium Ships" v-model="settings.premium"/>
        </mdc-layout-cell>
      </mdc-layout-grid>

      <mdc-headline>Tiers</mdc-headline>
      <mdc-layout-grid>
        <template v-for="(v,key) in settings.tiers">
          <mdc-layout-cell :key="key">
            <mdc-checkbox  :label="`Tier ${key + 1}`" v-model="settings.tiers[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>

      <mdc-headline>Classes</mdc-headline>
      <mdc-layout-grid>
        <template v-for="key in Object.keys(settings.types)">
          <mdc-layout-cell :key="key">
            <mdc-checkbox  :label="key" v-model="settings.types[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>

      <mdc-headline>Nations</mdc-headline>
      <mdc-layout-grid>
        <template v-for="key in Object.keys(settings.nations)">
          <mdc-layout-cell :key="key">
            <mdc-checkbox  :label="key" v-model="settings.nations[key]"/>
          </mdc-layout-cell>
        </template>
      </mdc-layout-grid>
    </div>
  </div>
</template>

<script>
import { Socket } from 'phoenix';
import { get } from 'axios';

export default {
  name: 'app',
  data() {
    return {
      socket: undefined,
      channel: undefined,

      connecting: true,
      connected: false,
      voting: false,

      settings: {
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
    get('https://shipvote.in.fkn.space/api/warships', {
      headers: { 'Content-Type': 'application/json' }
    }).then(res => {
      this.ships = res.data['data'];
    });

    window.Twitch.ext.onAuthorized(data => {
      if (this.socket) {
        this.socket.disconnect();
      }

      console.log(data);

      this.socket = new Socket('wss://shipvote.in.fkn.space/socket', {
        params: { token: data.token }
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

        console.log(a.name, av, b.name, bv);

        if (av < bv) {
          return 1;
        } else if (av === bv) {
          return 0;
        }
        return -1;
      });

      console.log(sorted);

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
    openVote() {
      if (this.channel) {
        this.channel.push('open_vote', {
          ships: this.ships
            .filter(s => this.settings.tiers[s.tier - 1] === true)
            .filter(s => this.settings.types[s.type] === true)
            .filter(
              s =>
                this.settings.premium ||
                (!this.settings.premium && s.premium === false)
            )
            .filter(s => this.settings.nations[s.nation] === true)
            .map(s => s.id)
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
</script>

<style lang="scss">
@import '../typography';
@import '../card';
@import '../mdc.scss';

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
</style>
