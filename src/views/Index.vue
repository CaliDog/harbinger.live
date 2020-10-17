<template>
  <div class="index is-dark">
    <div class="titles container">
      <h1 class="title has-text-white is-1">Harbinger Price Oracle ⚖️</h1>
      <h2 class="subtitle has-text-white">Enabling Defi on the <span class="inline-icon"><img src="../assets/XTZ-USD.png"></span>Tezos Blockchain</h2>
    </div>
    <div class="container is-flex">
      <div class="box ticker-info">
        <h2 class="title is-3 has-text-centered is-marginless">Latest Prices</h2>

        <table class="table is-hoverable is-fullwidth">
          <tbody>
            <tr class="pair-info" :key="pair[0]" v-for="pair in sorted($store.prices)">
              <td class="">
                <span><img :src="iconURL(pair[0])" /></span>
              </td>
              <td>
                <p class="ticker">{{pair[0]}}</p>
              </td>
              <td>
                <p class="price">${{ numberWithCommas((pair[1].close / 1000000).toFixed(2)) }}</p>
              </td>
            </tr>
          </tbody>
        </table>
        <h2 class="subtitle is-6 has-text-centered links">
          <a target="_blank" href="https://better-call.dev/mainnet/KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9/operations">View Contract</a>
          <a target="_blank" href="https://better-call.dev/mainnet/KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9/storage">Contract Data</a>
          <a target="_blank" href="https://github.com/tacoinfra/harbinger-contracts">Harbinger Github</a>
        </h2>
        <p :title="$store.prices['XTZ-USD'].end" class="has-text-centered">Contract Updated ~{{ humanFormat($store.prices['XTZ-USD'].end) }} Ago</p>
      </div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import moment from 'moment'

export default {
  name: 'Index',
  components: {
  },
  data() {
    return {
      currentTime: new Date(),
    }
  },
  mounted() {
    setInterval(() => {
      this.currentTime = new Date()
    }, 1000)
  },
  methods: {
    humanFormat(date) {
      const age = moment.duration(moment(this.currentTime) - moment(date))
      return age.humanize()
    },
    numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    },
    sorted(payload) {
      return _(payload)
        .toPairs()
        .sortBy(1, (item) => item[1].close)
        .reverse()
        .value()
    },
    iconURL(ticker) {
      const images = require.context('../assets/', false, /\.png$/)
      return images(`./${ticker}.png`)
    },
  },
};
</script>

<style lang="scss">
  @import '../../node_modules/bulma/sass/utilities/_all';
  $blue: #123262;
  .index{
    min-height: 100vh;
    background: $blue;
    padding: 3rem;
    .titles{
      max-width: 50vw;
      margin-bottom: 2rem;
    }
    .container.is-flex{
      justify-content: center;
    }
    .links a{
      padding: 1rem;
    }
    .inline-icon img{
      max-width: 1rem;
      margin-right: .15rem;
      margin-bottom: -1px;
    }
    .ticker-info{
      min-width: 30rem;
      .pair-info{
        vertical-align: middle;
        td{
          padding: 0.5rem;
          vertical-align: middle;
          img{
            vertical-align: middle;
          }
        }
        .ticker{
          width: 100%;
        }
        .price{
          min-width: 3rem;
        }
        img{
          width: 2rem;
        }
      }
    }
  }
</style>
