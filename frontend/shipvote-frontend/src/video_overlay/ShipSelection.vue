<template>
<div class="card raised" :style="{height: `${maxHeight}px`}">
		    <span class="typography--headline1">Pick a Ship</span>
			<div class="card__divider"></div>

			<div class="ships">
				<template v-for="ship in ships">
					<Ship :key="ship.id" :image="ship.image" :name="ship.name" :votes="ship.votes" @vote="vote(ship)" :canBeVoted="enableVoting && !voted" :totalVotes="totalVotes" />
				</template>
			</div>
		</div>
</template>

<script>
import Ship from './Ship';

export default {
  props: ['ships', 'enableVoting', 'voted', 'maxHeight', 'totalVotes'],
  components: { Ship },
  data() {
    return {};
  },
  methods: {
    vote(ship) {
      this.$emit('vote', ship);
    }
  }
};
</script>

<style lang="scss">
@import '../card';

.ships {
  display: flex;
  flex-flow: row wrap;
  margin-right: -12px;
}
</style>
