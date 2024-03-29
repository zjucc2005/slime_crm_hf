//window.cardTemplate = function(){
//    var uids = $("input[name='uids[]']:checked");
//    if(uids.length === 0){
//        alert('请至少选择一位专家');
//    }else{
//        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
//        //window.location.href = '/candidates/card_template?' + params;
//        window.open('/candidates/card_template?' + params);
//    }
//};

window.cardTemplate = function(card_template_id, uid){
    if(card_template_id){
        if(uid){
            var params = 'uids[]=' + uid;
        }else{
            var uids = $("input[name='uids[]']:checked");
            if(uids.length === 0){
                alert('请至少选择一位专家');
                return
            }else{
                var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
            }
        }
        params += '&card_template_id=' + card_template_id;
        window.location.href = '/candidates/gen_card?' + params;
        //window.open('/candidates/gen_card?' + params);
    }else{
        alert('参数错误');
    }
};

window.expertTemplate = function(project_id, template){
    var uids = $("input[name='uids[]']:checked");
    if(uids.length === 0){
        alert('请至少选择一位专家');
    }else{
        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
        params += '&template=' + template;
        if(project_id){
            params += '&project_id=' + project_id;
        }
        window.location.href = '/candidates/expert_template?' + params;
    }
};

window.showPhoneLocation = function(obj_id){
    var obj = $('#' + obj_id);
    if(obj.val()){
        $.ajax({
            url: '/location_data/show_phone_location?',
            type: 'get',
            data: { phone: obj.val() },
            dataType: 'json',
            success: function(res){
                console.log(res);
                if(res.status === '0'){
                    $('#' + obj_id + '_location').text([res.city, res.type].join(', '));
                    var city = $('#candidate_city');
                    if(!city.val()){
                        city.val(res.city);
                    }
                }
            }
        })
    }
};

window.showRecommenderName = function(obj_id){
    obj_id = obj_id || 'candidate_recommender_id';
    var recommender_id = $('#' + obj_id).val();
    $.ajax({
        url: '/candidates/recommender_info?recommender_id=' + recommender_id,
        type: 'get',
        dataType: 'json',
        success: function(res){
            console.log(res);
            if(res.status === '0'){
                $('#recommender_name').text(res.name);
            }else{
                $('#recommender_name').text('');
            }
        }
    })
};

window.loadingModal = function(category, reference_id, return_to=''){
    // $.get('/candidates/loading_modal.js?category=' + category + '&reference_id=' + reference_id );
    $.get(`/candidates/loading_modal.js?category=${category}&reference_id=${reference_id}&return_to=${return_to}`);
};

window.loadChildrenForProvince = function(ld_province_id, ld_city_id){
    if(ld_province_id){
        $.get('/location_data/load_children.js?ld_province_id=' + ld_province_id + '&ld_city_id=' + (ld_city_id || ''));
    } else {
        // $('select#ld_city_id').html('<option value>Please select</option>');
        $.get('/location_data/load_children.js?ld_city_id=' + (ld_city_id || ''));
    }
};

// window.loadHospitalOptions = function(hospital_id) {
//     $.get('/hospitals/load_hospital_options.js?hospital_id=' + (hospital_id || ''));
// };

window.loadChildrenForHospital = function(hospital_id, hospital_department_id) {
    if(hospital_id){
        $.get('/hospitals/' + hospital_id + '/load_children.js?hospital_department_id=' + (hospital_department_id || ''));
    } else {
        $('select#hospital_department_id').html('<option value>Please select</option>');
    }
};

window.loadWorkExperiencesForProjectTask = (candidate_id) => {
    if (candidate_id) {
        $.get(`/candidates/${candidate_id}/load_work_experiences_for_project_task.js`);
    } else {
        $('select#project_task_candidate_experience_id').html('<option value>Please select</option>');
    }
}

window.clipboard = function(element){
    selectText(element);
    document.execCommand('copy');
};

// select text from tag
function selectText(element) {
    var text = document.getElementById(element);
    if (document.body.createTextRange) {
        var range = document.body.createTextRange();
        range.moveToElementText(text);
        range.select();
    } else if (window.getSelection) {
        var selection = window.getSelection();
        var range = document.createRange();
        range.selectNodeContents(text);
        selection.removeAllRanges();
        selection.addRange(range);
        /*if(selection.setBaseAndExtent){
         selection.setBaseAndExtent(text, 0, text, 1);
         }*/
    } else {
        alert("none");
    }
};