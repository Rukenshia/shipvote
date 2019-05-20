<template>
  <section>
    <div class="section-title">
      <div class="section-title--caption">
        <span class="mdc-typography">{{nation}}</span>
      </div>
      <div class="section-title--line">
      </div>
    </div>
    <div class="ships">
      <template v-for="ship in ships">
        <Ship
          v-bind:key="ship.id"
          :image="ship.image"
          :name="ship.name"
          :votes="ship.votes"
          @vote="vote(ship)"
          :canBeVoted="enableVoting && !voted"
          :totalVotes="totalVotes"
        />
      </template>
    </div>
  </section>
</template>

<script>
import Ship from '../video_overlay/Ship';

export default {
  props: ['ships', 'nation', 'enableVoting', 'voted', 'totalVotes'],
  components: { Ship },
  data() {
    return {};
  },
  methods: {
    vote(ship) {
      this.$emit('vote', ship);
    },
  },
};
</script>

<style lang="scss">
.section-title {
  padding-bottom: 0.3em;
  padding-top: 0.3em;
  display: flex;

  .section-title--caption {
    text-transform: uppercase;
    font-size: 0.9rem;
    color: rgba(32, 33, 36, 0.7);
  }

  .section-title--line {
    flex-align: center;
    border-bottom: 2px solid rgba(32, 33, 36, 0.7);
    width: 100%;
    margin-left: 8px;
    margin-right: 4px;
    margin-bottom: 0.45rem;
  }
}

.ships {
  display: flex;
  flex-flow: row wrap;
}
</style>
