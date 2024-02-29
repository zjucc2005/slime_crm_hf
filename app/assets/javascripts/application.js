//= require jquery-ui.min
//= require select2.min
//= require echarts.min
//= require echarts-gl.min
//= require jquery.datetimepicker.full
//= require clipboard.min
//= require vue
//= require element-ui

const toFormData = (data) => {
    let formData = new FormData()
    Object.keys(data).map(k => formData.append(k, data[k]))
    return formData
}