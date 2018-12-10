<template>
  <mdc-layout-grid :class="theme">
    <mdc-layout-cell :span="12">
      <mdc-card class="mdc-card--flat">
        <mdc-card-text style="padding-left: 16px">
          <mdc-body>
            Learn how to use this extension
            <a
              target="_blank"
              href="https://shipvote.in.fkn.space/getting-started"
            >here</a>.
          </mdc-body>
        </mdc-card-text>
      </mdc-card>
      <mdc-headline>Shipvote Settings</mdc-headline>

      <mdc-layout-grid v-if="loading">
        <mdc-layout-cell :span="4">
          <mdc-body typo="body2">Loading your config</mdc-body>
          <mdc-linear-progress indeterminate></mdc-linear-progress>
        </mdc-layout-cell>
      </mdc-layout-grid>

      <mdc-layout-grid v-if="loadingError">
        <mdc-layout-cell :span="4">
          <mdc-body
            typo="body1"
          >Configuration could not be loaded. Please contact rukenshia for support.</mdc-body>
        </mdc-layout-cell>
      </mdc-layout-grid>

      <mdc-layout-grid v-if="!loading && !loadingError">
        <mdc-layout-cell :span="12">
          <mdc-layout-grid>
            <mdc-layout-cell :phone="4" :desktop="4" :tablet="4">
              <mdc-textfield
                class="fullwidth"
                v-model="config.wows_username"
                label="WoWS Username"
                :valid="validations.username"
                required
                box
              />
            </mdc-layout-cell>
            <mdc-layout-cell :phone="4" :desktop="2" :tablet="2">
              <mdc-select
                class="fullwidth"
                v-model="config.wows_realm"
                label="WoWS Server"
                :valid="validations.realm"
              >
                <option>eu</option>
                <option>na</option>
                <option>asia</option>
                <option>ru</option>
              </mdc-select>
            </mdc-layout-cell>
            <mdc-layout-cell :span="12" v-if="configured">
              <mdc-button raised @click="updateInfo" :disabled="saving">Save</mdc-button>
              <mdc-button outlined @click="updateInfo" :disabled="saving">Refresh ships</mdc-button>
              <mdc-body v-if="error">An error occured: {{error}}</mdc-body>
            </mdc-layout-cell>
            <mdc-layout-cell :span="12" v-if="!configured">
              <mdc-button
                raised
                @click="createInfo"
                :disabled="config.wows_username === '' || saving"
              >Setup</mdc-button>
              <mdc-body v-if="error">An error occured: {{error}}</mdc-body>
            </mdc-layout-cell>
          </mdc-layout-grid>

          <template v-if="configured">
            <mdc-body typo="body1">
              You currently own {{config.ships.length}} ships. {{enabledShips.length}} ships are currently enabled.
              Please reload your live dashboard after enabling/disabling ships to apply them to your next vote.
            </mdc-body>

            <mdc-list two-line bordered>
              <mdc-list-item v-for="ship in config.ships" :key="ship.id">
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

                <mdc-button
                  slot="end-detail"
                  @click="toggleShip(ship)"
                  :raised="!ship.enabled"
                >{{ship.enabled ? 'disable' : 'enable'}}</mdc-button>
              </mdc-list-item>
            </mdc-list>
          </template>
        </mdc-layout-cell>
      </mdc-layout-grid>
    </mdc-layout-cell>
  </mdc-layout-grid>
</template>

<script>
import { BASE_URL } from '../shipvote';

const { get, post, put } = window.axios;

window.App = {
  name: 'app',
  data() {
    return {
      loading: true,
      saving: false,
      loadingError: false,

      error: undefined,
      validations: {
        username: true,
        realm: true
      },

      configured: false,
      token: '',
      theme: 'light',
      config: {}
    };
  },
  created() {
    window.Twitch.ext.onContext(ctx => {
      this.theme = ctx.theme;
    });

    window.Twitch.ext.onAuthorized(data => {
      this.config.id = data.channelId;
      this.token = data.token;

      get(`${BASE_URL}/api/settings/channels/${data.channelId}`, {
        headers: {
          authorization: `Bearer ${data.token}`
        }
      })
        .then(res => {
          this.loading = false;
          this.configured = true;

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
          } else {
            this.loadingError = true;
            this.loading = false;
          }
        });
    });
  },
  methods: {
    updateInfo() {
      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;
      this.saving = true;

      put(
        `${BASE_URL}/api/settings/channels/${this.config.id}`,
        {
          channel: this.config
        },
        {
          headers: {
            authorization: `Bearer ${this.token}`
          }
        }
      )
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
        })
        .then(() => {
          this.saving = false;
        });
    },
    createInfo() {
      this.error = undefined;
      this.validations.username = true;
      this.validations.realm = true;
      this.saving = true;

      post(`${BASE_URL}/api/settings/channels`, this.config, {
        headers: {
          authorization: `Bearer ${this.token}`
        }
      })
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
        })
        .then(() => {
          this.saving = false;
        });
    },
    toggleShip(ship) {
      const newState = !ship.enabled;

      this.error = undefined;

      console.log(this.token);

      put(
        `${BASE_URL}/api/settings/channels/${this.config.id}/ships/${
          ship.id
        }/enabled`,
        { enabled: newState },
        {
          headers: {
            authorization: `Bearer ${this.token}`
          }
        }
      )
        .then(() => {
          ship.enabled = newState;
        })
        .catch(res => {
          this.error = 'could not write ship information';
        });
    }
  },
  computed: {
    enabledShips() {
      return this.config.ships.filter(s => s.enabled === true);
    }
  }
};
export default window.App;
</script>

<style lang='scss'>
@import '../darkmode';
@import '../typography';
@import '../card';

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

.mdc-list .mdc-list-item {
  padding-top: 16px;
}

.fullwidth,
.fullwidth .mdc-textfield {
  width: 100%;
}
</style>
