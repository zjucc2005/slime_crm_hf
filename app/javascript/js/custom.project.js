// mode: 0 - redirect, 1 - stay
window.addUserToProject = function(mode, uid){
    //if(uid){
    //    window.location.href = '/projects/add_users?uids[]=' + uid;
    //}else{
    //    var uids = $("input[name='uids[]']:checked");
    //    if(uids.length === 0){
    //        alert('请至少选择一位用户');
    //    }else{
    //        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
    //        var project_id = $('#project_id').val();
    //        if(project_id){
    //            params = params + '&project_id=' + project_id;
    //        }
    //        window.location.href = '/projects/add_users?' + params;
    //    }
    //}
    mode = mode || 0;
    var uids = uid ? [uid] : $("input[name='uids[]']:checked").map(function(){ return this.value }).get();
    var project_id = $('#project_id').val();
    if(uids.length === 0){
        alert('请至少选择一位用户');
    }else if(project_id === undefined || project_id === ''){
        alert('请选择一个项目');
    }else{
        var params = uids.map(function(uid){ return 'uids[]=' + uid }).join('&');
        params = params + '&project_id=' + project_id;
        params = params + '&mode=' + mode;
        window.location.href = '/projects/add_users?' + params;
    }
};

// mode: 0 - redirect, 1 - stay
window.addExpertToProject = function(mode, uid){
    //if(uid){
    //    window.location.href = '/projects/add_experts?uids[]=' + uid;
    //}else{
    //    var uids = $("input[name='uids[]']:checked");
    //    if(uids.length === 0){
    //        alert('请至少选择一位专家');
    //    }else{
    //        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
    //        var project_id = $('#project_id').val();
    //        if(project_id){
    //            params = params + '&project_id=' + project_id;
    //        }
    //        window.location.href = '/projects/add_experts?' + params;
    //    }
    //}

    mode = mode || 0;
    var uids = uid ? [uid] : $("input[name='uids[]']:checked").map(function(){ return this.value }).get();
    var project_id = $('#project_id').val();
    if(uids.length === 0){
        alert('请至少选择一位专家');
    }else if(project_id === undefined || project_id === ''){
        alert('请选择一个项目');
    }else{
        var params = uids.map(function(uid){ return 'uids[]=' + uid }).join('&');
        params = params + '&project_id=' + project_id;
        params = params + '&mode=' + mode;
        if(mode === 0){
            window.location.href = '/projects/add_experts?' + params;
        }else{
            $.get('/projects/add_experts.js?' + params);
        }
    }
};

window.batchUpdateProjectStatus = function(s){
    var uids = $("input[name='uids[]']:checked");
    if(uids.length === 0){
        alert('请至少选择一个条目');
    }else{
        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
        params = params + '&status=' + s;
        window.location.href = '/projects/batch_update_status?' + params;
    }
};

window.batchUpdateChargeStatus = function(s){
    var uids = $("input[name='uids[]']:checked");
    if(uids.length === 0){
        alert('请至少选择一个条目');
    }else{
        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
        params = params + '&status=' + s;
        window.location.href = '/finance/batch_update_charge_status?' + params;
    }
};

window.batchUpdatePaymentStatus = function(s){
    var uids = $("input[name='uids[]']:checked");
    if(uids.length === 0){
        alert('请至少选择一个条目');
    }else{
        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
        params = params + '&status=' + s;
        window.location.href = '/finance/batch_update_payment_status?' + params;
    }
};

window.exportFinanceExcel = function(mode){
    var uids = $("input[name='uids[]']:checked");
    if(!['en', 'cn', 'expert_fee', 'bda', 'iqvia_info'].includes(mode)){
        alert('参数错误');
        return false;
    }
    if(uids.length === 0){
        alert('请至少选择一个条目');
    }else{
        var params = uids.map(function(){ return 'uids[]=' + this.value }).get().join('&');
        params = params + '&mode=' + mode;
        window.location.href = '/finance/export_finance_excel?' + params;
    }
};

window.loadProjectCallRecords = function(project_id){
    $.get('/call_records/remote_index.js', { project_id: project_id });
};

window.loadProjectRequirements = function(project_id){
    $.get('/projects/load_project_requirements.js', { project_id: project_id });
};

// remote update silent - CallRecord work board
window.rusCallRecord = function(ele){
    var attr = {};
    attr[ele.dataset.attr] = ele.value;
    console.log('remote update silent:', { model: 'CallRecord', data: attr });
    $.ajax({
        type: 'POST',
        url: '/call_records/' + ele.dataset.id + '/remote_update_silent.js',
        data: { call_record: attr },
        dataType: 'json',
        success: function(data){
            if(data.status === 0){
                console.log('remote update silent:ok!');
            } else {
                console.log('remote update silent:', data.msg);
                alert(data.msg);
            }
        }
    });
};

// js filter - CallRecord  work board
window.rfsCallRecord = (project_id) => {
    const cond = {
        'projectRequirementId': [],
        'operatorId': []
    };
    for(let k in cond) {
        $(`input[type=checkbox][name=${k}_${project_id}]`).map((index, item) => item.checked ? cond[k].push(item.value) : '')
    }
    $(`tr[data-project-id=${project_id}]`).map((index, item) => {
        let show = true;
        for(let k in cond) {
            if(cond[k].indexOf(item.dataset[k]) === -1) {
                show = false;
                break
            }
        }
        item.hidden = !show
    })
};