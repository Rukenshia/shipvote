<template>
  <div class="vote-progress" v-if="sortedShips.length > 0">
    <div class="progress-ship" v-for="ship in sortedShips" :key="ship.id">
      {{ship.name}} ({{ship.votes}} vote{{ship.votes === 1 ? '' : 's'}})
      <mdc-linear-progress
        accent
        :progress="ship.votes / totalVotes > 1.0 ? 1.0 : ship.votes / totalVotes"
      ></mdc-linear-progress>
    </div>
  </div>
</template>

<script>
export default {
  props: ['ships', 'voting', 'totalVotes'],
  data() {
    return {};
  },
  computed: {
    sortedShips() {
      if (this.ships.length === 0) {
        return [];
      }
      const sorted = JSON.parse(JSON.stringify(this.ships));

      sorted.sort((a, b) => {
        const av = a.votes || 0;
        const bv = b.votes || 0;

        if (av < bv) {
          return 1;
        } else if (av === bv) {
          return 0;
        }
        return -1;
      });

      return sorted.slice(0, 5).filter(s => s.votes > 0);
    }
  }
};
</script>

<style lang="scss">
.vote-progress {
  position: absolute;
  left: 0;
  top: 0;

  width: 180px;
  border-bottom-right-radius: 8px;
  background-color: hsla(0, 0, 0, 0.5);
  padding: 4px;

  color: white;
  font-family: Roboto;
}

.mdc-linear-progress {
  border-radius: 8px;
}
</style>
