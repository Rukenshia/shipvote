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

    <a class="button raised" v-if="!voting" @click="openVote">Open vote</a>
    <a class="button raised" v-if="voting" @click="closeVote">Close vote</a>


  </div>
</template>

<script>
import { Socket } from 'phoenix';

export default {
  name: 'app',
  data() {
    return {
      socket: undefined,
      channel: undefined,

      connecting: true,
      connected: false,
      voting: false
    };
  },
  created() {
    window.Twitch.ext.onAuthorized(data => {
      if (this.socket) {
        this.socket.disconnect();
      }

      console.log(data);

      this.socket = new Socket('ws://localhost:4000/socket', {
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
      });
    });
  },
  methods: {
    openVote() {
      if (this.channel) {
        this.channel.push('open_vote');
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
