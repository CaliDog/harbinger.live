<template>
  <div class="index is-dark">
    <div class="titles container">
      <h1 class="title has-text-white is-1">Harbinger Price Oracle <span class="scale">⚖️</span></h1>
      <h2 class="subtitle has-text-white">Enabling Defi on the <span class="inline-icon"><img src="../assets/XTZ-USD.png"></span>Tezos Blockchain</h2>
    </div>
    <div class="container is-flex">
      <div class="box ticker-info">
        <h2 class="title is-3 has-text-centered is-marginless">Latest Prices</h2>
        <h2 class="subtitle has-text-centered is-marginless">Coinbase Pro</h2>

        <div class="contract-refresh has-text-centered">
          <progress class="progress is-marginless is-success" :value="900 - Math.floor(timeDelta() / 1000)" max="900">{{ numberWithCommas(900 - Math.floor(timeDelta() / 1000)) }} sec</progress>
          <p class="help">Contract Data Refreshes In {{ contractRefresh() }} <span v-if="Math.floor(timeDelta() / 1000) > 1">(~{{ Math.floor(timeDelta() / 1000) }} seconds)</span></p>
        </div>

        <table class="table is-hoverable is-fullwidth">
          <tbody>
            <tr class="pair-info" :key="pair[0]" v-for="pair in sorted($store.prices['Coinbase Pro'])">
              <td class="">
                <span><img :src="iconURL(pair[0])" /></span>
              </td>
              <td class="has-text-centered">
                <p class="ticker">{{pair[0]}}</p>
              </td>
              <td class="has-text-centered">
                <p class="price">${{ numberWithCommas((pair[1].computedPrice / 1000000).toFixed(2)) }}</p>
              </td>
              <td>
                <sparkline :tooltipProps="tooltipProps">
                  <sparklineCurve :styles="{stroke: strokeColor(pair[1])}" :refLineType="false" :refLineStyles="{}" :data="sparkData(pair[1])" :limit="pair[1].priceHistory.length" />
                </sparkline>
              </td>
            </tr>
          </tbody>
        </table>
        <h2 class="subtitle is-6 has-text-centered links">
          <a target="_blank" href="https://better-call.dev/mainnet/KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9/operations">View Contract</a>
          <a target="_blank" href="https://better-call.dev/mainnet/KT1Jr5t9UvGiqkvvsuUbPJHaYx24NzdUwNW9/storage">Contract Data</a>
          <a target="_blank" href="https://github.com/tacoinfra/harbinger">Harbinger Github</a>
        </h2>
        <p :title="$store.prices['Coinbase Pro']['XTZ-USD'].lastUpdate" class="has-text-centered">Contract Updated ~{{ humanFormat($store.prices['Coinbase Pro']['XTZ-USD'].lastUpdate) }} Ago</p>
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
      currentTime: moment(new Date()),
      refreshTime: moment(this.$store.prices['Coinbase Pro']['XTZ-USD'].lastUpdate).add(15, 'minutes'),
      tooltipProps: {
        formatter(val) {
          const value = (val.value / 1000000)
          return `$${Math.trunc(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',')}.${(value % 1).toString().substr(2,4)}`
        },
      },
    }
  },
  mounted() {
    setInterval(() => {
      this.currentTime = moment(new Date())
    }, 1000)

    this.$bus.$on('message', (messageData) => {
      const payload = JSON.parse(messageData)
      if (payload.type === 'oracleDataUpdate') {
        this.$set(this.$store, 'prices', payload.state)
        this.refreshTime = moment(this.$store.prices['Coinbase Pro']['XTZ-USD'].lastUpdate).add(15, 'minutes')
      }
    })
  },
  methods: {
    strokeColor(pair) {
      const previousPrices = this.previousPrices(pair)
      if (previousPrices[0] < previousPrices[previousPrices.length - 1]) {
        return '#00d1b2'
      }
      return '#ff3860'
    },
    sparkData(pair) {
      return this.previousPrices(pair)
    },
    previousPrices(pair) {
      return pair.priceHistory.map((price, index) => price / pair.volumeHistory[index])
    },
    contractRefresh() {
      const delta = this.timeDelta()

      if (delta < 0) {
        return 'A Few Moments'
      }

      const humanDuration = moment
        .duration(delta)
        .humanize()
        .replace(/\b\w/g, (l) => l.toUpperCase())

      return `Roughly ${humanDuration}`
    },
    timeDelta() {
      return this.refreshTime - this.currentTime
    },
    humanFormat(date) {
      const age = moment.duration(this.currentTime - moment(date))
      return age.humanize()
    },
    numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    },
    sorted(payload) {
      return _(payload)
        .toPairs()
        .sortBy(1, (item) => item[1].computedPrice)
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
    @include until($desktop) {
      padding: 0;
      .titles{
        max-width: 90vw !important;
        padding: 1rem;
      }
      .ticker-info{
        min-width: 0 !important;
      }
    }
    @include until($tablet){
      .scale{
        display: none;
      }
    }
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
    .contract-refresh{
      margin-bottom: .5rem;
      margin-top: .5rem;
      progress{

      }
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
