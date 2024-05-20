//= require jquery-ui.min
//= require select2.min
//= require echarts.min
//= require echarts-gl.min
//= require jquery.datetimepicker.full
//= require clipboard.min
//= require vue
//= require element-ui

Vue.config.productionTip = false
Vue.prototype.$echarts = echarts
Vue.filter('truncate', function(val, length) {
    if (!val) return ''
    val = val.toString()
    if (val.length > length) {
        return val.substring(0, length) + '...'
    } else {
        return val
    }
})