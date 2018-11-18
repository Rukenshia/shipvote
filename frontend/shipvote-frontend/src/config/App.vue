<template>
<mdc-layout-grid>
  <mdc-layout-cell :span=12>
    <mdc-headline>Shipvote Settings</mdc-headline>

    <mdc-layout-grid v-if="loading">
      <mdc-layout-cell :span=4>
        <mdc-body typo="body2">Loading your config</mdc-body>
        <mdc-linear-progress indeterminate></mdc-linear-progress>
      </mdc-layout-cell>
    </mdc-layout-grid>


    <mdc-layout-grid v-if="!loading">
      <mdc-layout-cell :span=12>
        <mdc-layout-grid>
          <mdc-layout-cell :phone=4 :desktop=4 :tablet=4>
            <mdc-textfield class="fullwidth" v-model="config.wows_username" label="WoWS Username" :valid="validations.username" required box/>
          </mdc-layout-cell>
          <mdc-layout-cell :phone=4 :desktop=2 :tablet=2>
            <mdc-select class="fullwidth" v-model="config.wows_realm" label="WoWS Server" :valid="validations.realm">
              <option>eu</option>
              <option>na</option>
              <option>asia</option>
              <option>ru</option>
            </mdc-select>
          </mdc-layout-cell>
          <mdc-layout-cell :span=12 v-if="configured">
            <mdc-button raised @click="updateInfo">Save</mdc-button>
            <mdc-button outlined @click="updateInfo">Refresh ships</mdc-button>
            <mdc-body v-if="error">An error occured: {{error}}</mdc-body>
          </mdc-layout-cell>
          <mdc-layout-cell :span=12 v-if="!configured">
            <mdc-button raised @click="createInfo" :disabled="config.wows_username === ''">Setup</mdc-button>
            <mdc-body v-if="error">An error occured: {{error}}</mdc-body>
          </mdc-layout-cell>
        </mdc-layout-grid>

        <template v-if="configured">
          <mdc-body typo="body1">You currently own {{config.ships.length}} ships.</mdc-body>


          <mdc-list two-line bordered>
            <mdc-list-item v-for="ship in config.ships" :key="ship.id">
              <img slot="start-detail" :src="ship.image"
            width="56" height="auto" :alt="`Image of ${ship.name}`">
              <span><strong>{{ship.name}}</strong></span>
              <span slot="secondary">Tier: {{ship.tier}}, Nation: {{ship.nation}}</span>
            </mdc-list-item>
          </mdc-list>
        </template>
      </mdc-layout-cell>
    </mdc-layout-grid>
  </mdc-layout-cell>
</mdc-layout-grid>
</template>

<script>
import { get, post, put } from 'axios';
import { BASE_URL } from '../shipvote';

export default {
  name: 'app',
  data() {
    return {
      loading: true,

      error: undefined,
      validations: {
        username: true,
        realm: true
      },

      configured: false,
      config: {}
    };
  },
  created() {
    window.Twitch.ext.onAuthorized(data => {
      this.config.id = data.channelId;

      get(`${BASE_URL}/api/channels/${data.channelId}`)
        .then(res => {
          this.loading = false;

          this.config = res.data['data'];
        })
        .catch(e => {
          if (e.response.status === 404) {
            this.loading = false;
            this.config = {
              id: data.channelId,
              wows_username: '',
              wows_realm: 'eu',
              ships: []
            };
          }
        });
    });
  },
  methods: {
    updateInfo() {
      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;

      put(`${BASE_URL}/api/channels/${this.config.id}`, {
        channel: this.config
      })
        .then(res => {
          this.loading = false;

          this.config = res.data['data'];
        })
        .catch(res => {
          this.error = 'could not save information';

          if (res.response.status === 404) {
            this.validations.username = false;
            this.validations.realm = false;
            this.error = 'Please check your username and realm';
          }
        });
    },
    createInfo() {
      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;

      post(`${BASE_URL}/api/channels`, this.config)
        .then(res => {
          this.loading = false;

          this.config = res.data['data'];
          this.configured = true;
        })
        .catch(res => {
          this.error = 'could not save information';

          if (res.response.status === 404) {
            this.validations.username = false;
            this.validations.realm = false;
            this.error = 'Please check your username and realm';
          }
        });
    }
  }
};
</script>

<style lang="scss">
@import '../typography';
@import '../card';
@import '../mdc.scss';

:root {
  --mdc-theme-secondary: #6441a4;
  --mdc-theme-primary: #6441a4;
}

.mdc-card.mdc-card--flat {
  padding: 4px;

  box-shadow: none;
  border-radius: 8px;
  background-color: #f8f9fa;

  color: #5f6368;
}

.mdc-list.mdc-list--bordered li:first-child {
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
}

.mdc-list.mdc-list--bordered li:last-child {
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
}

.mdc-list-item__graphic {
  margin-top: -32px;
}

.fullwidth,
.fullwidth .mdc-textfield {
  width: 100%;
}
</style>
