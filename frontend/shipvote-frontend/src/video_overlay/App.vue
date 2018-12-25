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
      socket: undefined,
      channel: undefined,
      theme: 'light',
      api: undefined,

      // Active vote
      vote: undefined,

      // Channel features
      enableRestApi: false,

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
    window.Twitch.ext.onContext(data => {
      this.theme = data.theme;

      this.maxHeight =
        parseInt(
          data['displayResolution'].slice(
            data['displayResolution'].indexOf('x') + 1
          ),
          10
        ) - 160;
    });
    window.Twitch.ext.onAuthorized(authData => {
      this.api = new ShipvoteApi(BASE_URL, authData.token, authData.channelId);

      this.api.getChannelInfo().then(info => {
        this.enableRestApi = info.enable_rest_api;

        if (this.enableRestApi) {
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
              setTimeout(() => updateVotes(voteId), 1000);
            });
          };

          const checkOpenVote = () => {
            this.api.getOpenVote().then(vote => {
              this.vote = vote;
              if (vote) {
                if (!this.voting) {
                  this.voteStarted = true;
                }
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

                setTimeout(() => checkOpenVote(), 2000);
              }
            });
          };

          checkOpenVote();
        } else {
          if (this.socket) {
            this.socket.disconnect();
          }

          this.socket = new Socket(`${BASE_WS_URL}/socket`, {
            params: { token: authData.token }
          });
          this.socket.connect();
          // Now that you are connected, you can join channels with a topic:
          const channel = (this.channel = this.socket.channel(
            `stream:${authData.channelId}`,
            {}
          ));
          channel
            .join()
            .receive('ok', resp => {
              this.connected = true;

              channel.push('get_status');
            })
            .receive('error', resp => {
              console.log('Unable to join', resp);
            });

          channel.on('status', data => {
            this.voting = data.voting;
            this.voteStarted = data.voting;

            if (this.voting) {
              get(`${BASE_URL}/api/warships`, {
                params: { ids: data.ships },
                headers: { 'Content-Type': 'application/json' }
              }).then(res => {
                let ships = res.data['data'];

                if (data.ships) {
                  ships = ships.filter(
                    s => data['ships'].find(v => v === s.id) !== undefined
                  );
                }

                if (data.votes) {
                  ships = ships.map(s => {
                    if (typeof data['votes'][s.id] === 'undefined') {
                      return { ...s, votes: 0 };
                    }
                    return { ...s, votes: data['votes'][s.id] };
                  });

                  this.totalVotes = Object.values(data['votes']).reduce(
                    (p, c) => p + c,
                    0
                  );
                } else {
                  ships = ships.map(s => {
                    return { ...s, votes: 0 };
                  });
                }

                // Sort the incoming ships alphabetically
                this.ships = ships.sort((a, b) => {
                  if (a.name < b.name) {
                    return -1;
                  } else if (a.name > b.name) {
                    return 1;
                  }
                  return 0;
                });

                this.ships.forEach((s, i) => {
                  s.order = i;
                });
              });
              this.noteDismissed = false;

              setTimeout(() => {
                this.voteStarted = false;
              }, 5000);
            } else {
              this.voted = false;
              this.selecting = false;
              this.totalVotes = 0;
              this.ships = [];
            }
          });

          channel.on('new_vote', data => {
            const ship = this.ships.findIndex(s => s.id === data['ship_id']);

            Vue.set(this.ships, ship, {
              ...this.ships[ship],
              votes: this.ships[ship].votes + 1
            });
            this.totalVotes++;
          });
        }
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

      if (this.enableRestApi) {
        this.api.voteForShip(this.vote.id, ship.id);
      } else {
        if (this.channel) {
          this.channel.push('vote', { ship_id: ship.id });
        }
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
