<template>
  <div class="card raised" :style="{height: `${maxHeight}px`}">
    <mdc-layout-grid style="padding: 0">
      <mdc-layout-cell span=12>
        <span class="mdc-typography--headline6">Pick a Ship </span>
        <mdc-button @click="toggleFilters"><i class="material-icons">filter_list</i> Filter</mdc-button>
        <mdc-button v-if="filtered" @click="resetFilters" :unelevated="true"><i class="material-icons">clear</i> Reset</mdc-button>
      </mdc-layout-cell>
    </mdc-layout-grid>
    <div class="card__divider"></div>

    <div v-show="filtering" class="filters">
      <Filters ref="refFilter" :tiers="availableTiers" :nations="availableNations" @updateFilter="updateFilter"></Filters>
    </div>

    <div class="ships">
      <template v-for="ship in filteredShips">
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
  </div>
</template>

<script>
import Ship from './Ship';
import Filters from '../shared/Filters';

const shipTypePriority = ['Destroyer', 'Cruiser', 'Battleship', 'AirCarrier'];

export default {
  props: ['ships', 'enableVoting', 'voted', 'maxHeight', 'totalVotes'],
  components: { Ship, Filters },
  data() {
    return {
      filtering: false,
      filters: {},
    };
  },
  computed: {
    filtered() {
      return typeof this.filters['tier'] !== 'undefined' && this.filters.tier !== 'any' || typeof this.filters['nation'] !== 'undefined' && this.filters.nation !== 'any';
    },
    availableTiers() {
      const tiers = new Set();
      this.ships.forEach(s => tiers.add(s.tier));

      return [...tiers].sort((a, b) => a - b);
    },
    availableNations() {
      const nations = new Set();
      this.ships.forEach(s => nations.add(s.nation));

      return [...nations].sort((a, b) => a - b);
    },
    filteredShips() {
      return this.ships.filter(s => {
        if (typeof this.filters.tier === 'undefined' || this.filters.tier === 'any') {
          return true;
        }

        return s.tier === this.filters.tier;
      }).filter(s => {
        if (typeof this.filters.nation === 'undefined' || this.filters.nation === 'any') {
          return true;
        }

        return s.nation === this.filters.nation;
      }).sort((a, b) => {
        if (a.tier < b.tier) {
          return 1;
        } else if (a.tier > b.tier) {
          return -1;
        } else {
          // sort by type
          const aTypePrio = shipTypePriority.indexOf(a.type);
          const bTypePrio = shipTypePriority.indexOf(b.type);

          if (aTypePrio < bTypePrio) {
            return  -1;
          } else if (aTypePrio > bTypePrio) {
            return 1;
          } else {
            // sort alphabetically
            if (a.name < b.name) {
              return -1;
            } else if (a.name == b.name) {
              return 0;
            } else {
              return 1;
            }
          }
        }
      });
    },
  },
  methods: {
    vote(ship) {
      this.$emit('vote', ship);
    },
    toggleFilters() {
      this.filtering = !this.filtering;
    },
    resetFilters() {
      this.$refs.refFilter.reset();
    },
    updateFilter({name, value}) {
      this.filters = {
        ...this.filters,
        [name]: value,
      };
    },
  },
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
