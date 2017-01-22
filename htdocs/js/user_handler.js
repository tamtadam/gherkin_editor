UserHandler = function(){
	var _this = new Object();

	$.each(['email', 'name', 'username', 'password'], function(i, v){
		_this[v] = $('#' + v ).val();
	});

	return {
		checkParams : function(){
			return check_params([{
				value  : _this.email,
				regExp : /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
				tip    : '',
				id     : 'email',
			},{
				value  : _this.name,
				regExp : /.+/,
				tip    : '',
				id     : 'name',
			},{
				value  : _this.username,
				regExp : /.+/,
				tip    : '',
				id     : 'username',
			},{
				value  : _this.password,
				regExp : /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$/,
				tip    : '',
				id     : 'password',
			}]);
		},
		
		saveNewUser : function (){
			if( this.checkParams() ) {
			    push_cmd("saveNewUser", JSON.stringify({
			    	email    : _this.email,
			    	name     : _this.name,
			    	username : _this.username,
			    	password : MD5(_this.password),
			    }));
			    var res = processor(send_cmd());
			    if( res[ 'saveNewUser' ] ) {
			    	var new_url = $(location)[0].href.replace('reg.html', 'index.html');
			    	$(location)[0].replace( new_url + '?' + 'username=' + _this.username + '&password=' + _this.password );
			    }
			}
		},
	};
};

function userHandlerBtn () {
	var userhandler = new UserHandler();
	userhandler.saveNewUser();
}

function check_params( formDatas ){
    var bValid  = true ;

    $.each(formDatas, function(i, v){
    	var check_res = checkRegexp(v.value, v.regExp, v.id);
    	bValid = bValid && check_res;
    });

    return bValid ;
}

function checkRegexp( o, regexp, id ) {
    if ( !( regexp.test( o ) ) ) {
        $('#' + id).parent().addClass( "has-error" );
        setTimeout(function() {
        	$('#' + id).parent().removeClass( "has-error", 2000 );
        }, 500 );
        return false;
    } else {
        return true;
    }
}

function updateTips( t ) {
    tips.text( tips.val() + t );
    tips.addClass( "ui-state-error" );
    setTimeout(function() {
        tips.removeClass( "ui-state-error", 600 );
    }, 500 );
}
