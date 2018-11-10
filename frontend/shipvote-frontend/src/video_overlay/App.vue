<template>
  <div>
    <div class="selection" v-bind:data-active="selecting">
      <ShipSelection @vote="vote" :ships="ships" :enableVoting="true" :voted="voted" />
    </div>

    <div class="vote-notice" v-bind:data-active="voting && !selecting" v-bind:data-initial="voteStarted" v-bind:data-dismissed="selecting">
			<div class="cta raised" @click="selecting = true">
				<i class="material-icons">error_outline</i>
				<span>Vote for a Ship now!</span>
      </div>
    </div>
  </div>
</template>

<script>
import { Socket } from 'phoenix';
import { get } from 'axios';
import ShipSelection from './ShipSelection';

const mockSocket = false;

let SocketImpl = Socket;
let onAuthorized = window.Twitch.ext.onAuthorized;

if (mockSocket) {
  onAuthorized = fn => {
    fn({ token: 'foo', channel_id: 'bar' });
  };
  const Channel = class MockChannel {
    constructor() {
      this.evs = new Map();
    }

    join() {
      return this;
    }
    receive(act, fn) {
      if (act !== 'ok') {
        return this;
      }

      setTimeout(() => fn(), 100);

      return this;
    }

    trigger(e, p) {
      if (this.evs.has(e)) {
        this.evs.get(e).forEach(a => a(p));
      }
    }

    on(e, a) {
      if (!this.evs.has(e)) {
        this.evs.set(e, [a]);
      } else {
        this.evs.get(e).push(a);
      }

      return this;
    }

    push(e, p) {
      switch (e) {
        case 'get_status':
          this.trigger('status', { voting: true });
        default:
          break;
      }

      return this;
    }
  };

  SocketImpl = class MockSocket {
    connect() {}
    channel() {
      return new Channel();
    }
  };
}

export default {
  name: 'app',
  components: { ShipSelection },
  data() {
    return {
      socket: undefined,
      channel: undefined,

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

      // Ships available to vote
      ships: []
    };
  },
  created() {
    onAuthorized(data => {
      if (this.socket) {
        this.socket.disconnect();
      }

      this.socket = new SocketImpl('ws://localhost:4000/socket', {
        params: { token: data.token }
      });
      this.socket.connect();
      // Now that you are connected, you can join channels with a topic:
      const channel = (this.channel = this.socket.channel(
        `stream:${data.channelId}`,
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
          get('http://localhost:4000/api/warships', {
            headers: { 'Content-Type': 'application/json' }
          }).then(res => {
            let ships = res.data['data'];

            if (data.ships) {
              ships = ships.filter(s => data['ships'].find(s.id) !== null);
            }

            if (data.votes) {
              ships = ships.map(s => {
                if (typeof data['votes'][s.id] === 'undefined') {
                  return { ...s, votes: 0 };
                }
                return { ...s, votes: data['votes'][s.id] };
              });
            } else {
              ships = ships.map(s => {
                return { ...s, votes: 0 };
              });
            }

            this.ships = ships;
          });
          this.noteDismissed = false;

          setTimeout(() => {
            this.voteStarted = false;
          }, 5000);
        } else {
          this.voted = false;
          this.selecting = false;
        }
      });

      channel.on('new_vote', data => {
        const ship = this.ships.find(s => s.id === data['ship_id']);

        ship.votes += 1;
      });
    });
  },
  methods: {
    vote(ship) {
      if (this.voted) {
        return;
      }

      this.voted = true;

      if (this.channel) {
        this.channel.push('vote', { ship_id: ship.id });
      }
    }
  }
};
</script>

<style lang="scss">
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
  top: 110px;
  width: 386px;

  .card {
    height: 0;
    max-height: 0;
    opacity: 0;
    visibility: hidden;
    overflow-y: scroll;

    transition: visibility 0s linear 0.5s, max-height 0.5s, height 0.5s,
      opacity 0.45s;
  }

  &[data-active='true'] {
    .card {
      visibility: visible;
      height: 20%;
      max-height: 260px;
      transition-delay: 0s;
      opacity: 1;
    }
  }
}
</style>
