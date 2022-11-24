window.loadCzbankXibaoList = function(trans_date){
    $.get('/czbank/xibao_list.js', { trans_date: trans_date });
};