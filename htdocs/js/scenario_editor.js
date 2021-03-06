function init_page_DB() {
    var processed_data = new Object();

    push_cmd("get_feature_list", JSON.stringify({'get': 1 }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({'get': 1 }));
	push_cmd("get_scen_list", JSON.stringify({'get': 1 }));
	push_cmd("get_project_list", JSON.stringify({'get': 1 }));
	
    processed_data = processor(send_cmd());

    FEATURE_SELECT_LIST  = processed_data['get_feature_list'];
    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
	SCENARIO_SELECT_LIST = processed_data['get_scen_list'];
	PROJECT_LIST         = processed_data['get_project_list'];
	get_locked_status();
}

function fill_feature_list() {
    $("feature_list").html('');

    create_list_group('feature_list', FEATURE_SELECT_LIST, select_feature, {}, {
    	class : 'list-group-item',
    	href  : '#'
    });

    create_button('delete_item_from_feature_list_btn', Are_you_sure_you_want_to_delete_feature,{}, "bootstrap");
    create_button('add_item_to_feature_list_btn', add_new_feature_to_feature_list,{}, "bootstrap");
    create_button('open_feature_btn', open_feature, {}, "bootstrap");

}

function select_feature() {
	$(this).parent().children().removeClass('selected')
	$(this).parent().children().removeClass('active');

	$(this).addClass('selected');
    $(this).addClass('active');

    $('#add_new_feature_input').val($(this).html());
}


function fill_template_list(template_list) {
	$('#template_list').html('');

    create_list_group('template_list', template_list, select_template, {}, {
    	class : 'list-group-item',
    	href  : '#'
    });

	create_button('rename_item_from_template_list_btn', rename_template,{}, "bootstrap");
    create_button('add_item_to_template_list_btn', add_new_template_to_template_list,{}, "bootstrap");	
}

function fill_project_list() {
	$('#project_list').html('');

    create_list_group('project_list', PROJECT_LIST, select_project, {}, {
    	class : 'list-group-item',
    	href  : '#'
    });

	create_button('rename_item_from_project_list_btn', rename_project,{}, "bootstrap");
	create_button('delete_item_from_project_list_btn', Are_you_sure_you_want_to_delete_project,{}, "bootstrap");
    create_button('add_item_to_project_list_btn', add_new_project_to_project_list,{}, "bootstrap");
}

function rename_project() {
    push_cmd("rename_project", JSON.stringify({
        'ProjectID': $('#project_list .selected ').data('data').ProjectID,
        'Title'    : $("#add_new_project_input").val()
    }), function (){
    	$("#project_list .selected").html($("#add_new_project_input").val());
    });
    processor(send_cmd());	
}

function rename_template() {
    push_cmd("rename_template", JSON.stringify({
        'TemplateID': $('#template_list .selected ').data('data').TemplateID,
        'Title'    : $("#add_new_template_input").val()
    }), function (){
    	$("#template_list .selected").html($("#add_new_template_input").val());
    });
    processor(send_cmd());		
}

function Are_you_sure_you_want_to_delete_project() {
    if(!$('#project_list .selected ').length ) {
    	return;
    }
    var project_data = $('#project_list .selected ').data('data');
    $("#Delete_project_from_project_list").dialog({
        width: 800,
        height: 200,
        position: [600, 600],
        title: "Are you sure do you want" + "\n" + "to delete: " + project_data.Title + " project?",
        buttons:
        {
            "Delete project": {
                text: 'Ok',
                id: 'delete_project_dialog_btn',
                click: function() {
                    push_cmd("delete_project", JSON.stringify({
                        'ProjectID': project_data.ProjectID
                    }), function (){
                    	$("#Delete_project_from_project_list").dialog("close");
                    	$("#project_list .selected").remove();
                    	$("add_new_project_input").val("");
                    });
                    processor(send_cmd());
                }
            },
            "Cancel": {
                text: 'Not now',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    })	
	
}

function select_project() {		
	$('.list-group').find('a').removeClass('active');
	$('.list-group').find('a').removeClass('selected');

	$(this).addClass('active');
	$(this).addClass('selected');
	$("#add_new_project_input").val($(this).data("data").Title);
}

function select_template() {
	$('.list-group').find('a').removeClass('active');
	$('.list-group').find('a').removeClass('selected');

	$(this).addClass('active');
	$(this).addClass('selected');
	$("#add_new_template_input").val($(this).data("data").Title);	
}

function fill_scenario_list() {
    $("#scenario_list").html('');

    create_list_group('scenario_list', SCENARIO_SELECT_LIST, add_scenario_to_feature, {}, {
    	class : 'list-group-item',
    	href  : '#'
    });
	
    create_button('delete_item_from_scenario_list_btn', Are_you_sure_you_want_to_delete_scenario, {}, "bootstrap");
    create_button('add_item_to_scenario_list_btn', add_new_scenario_to_scenario_list, {}, "bootstrap");	
}

function add_new_scenario_to_scenario_list() {
    push_cmd("add_new_scen_to_scenlist", JSON.stringify({
        'Title' : $("add_new_scenario_input").val() || '',
    }));
    processor(send_cmd());
    $('#add_new_scenario_input').val('');
    update_scenario_list();
}

function add_new_project_to_project_list() {
    push_cmd("add_new_proj_to_projlist", JSON.stringify({
        'Title': $("#add_new_project_input").val() || ''
    }), function() {
    	$('#add_new_project_input').val('');
        update_project_list();	
    });
    processor(send_cmd());
}

function add_new_template_to_template_list() {
	if( $("#add_new_template_input").val() === "" ) {
    	return;
    }
	push_cmd("add_new_template_to_template", JSON.stringify({
        'Title': $("#add_new_template_input").val(),
        'ProjectID': $("#project_list .selected").data("data").ProjectID
    }), function() {
    	var a = create_a({
    		class : "list-group-item disabled ui-sortable-handle",
    		href  : "#"
    	});
    	$(a).html( $('#add_new_template_input').val() );
    	$("#template_list").append(a);
    	$('#add_new_template_input').val('');
    });
    processor(send_cmd());
}

function add_new_feature_to_feature_list() {
    push_cmd("add_new_fea_to_fealist", JSON.stringify({
        'Title': $('add_new_feature_input').val() || ''
    }));
    processor(send_cmd());
    $('add_new_feature_input').val('');
    update_feature_and_scenario_list();
}

function Are_you_sure_you_want_to_delete_feature() {
    if(!$('#feature_list .selected ').length ) {
    	return;
    }
    var feature_data = $('#feature_list .selected ').data('data');
    $("#Delete_feature_from_feature_list").dialog({
        width: 800,
        height: 200,
        position: [600, 600],
        title: "Are you sure do you want" + "\n" + "to delete: " + feature_data.Title + " feature?",
        buttons:
        {
            "Delete scenarios": {
                text: 'Delete feature',
                id: 'delete_feature_dialog_btn',
                click: function() {
                    $(this).dialog("close");
                    if ( ACTUAL_FEATURE  == feature_data.FeatureID ) {
                    	close_feature();
                    }
                    delete_item_from_feature_list( feature_data.FeatureID );
                }
            },
            "Cancel": {
                text: 'Not now',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    });
}

function delete_item_from_feature_list( feature_id ) {
    delete_feature( feature_id );
    update_feature_and_scenario_list();
}

function delete_feature(selected_fea_id) {
	$("#Scenarios_in_Feature").children().remove();
    push_cmd("delete_feature", JSON.stringify({
        'FeatureID': selected_fea_id
    }));
    processor(send_cmd());
}

function update_feature_and_scenario_list() {
    push_cmd("get_feature_list", JSON.stringify({
        'get': 1
    }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({
        'get': 1
    }));
    var processed_data = processor(send_cmd());

    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
	FEATURE_SELECT_LIST  = processed_data['get_feature_list'];

    fill_feature_list();
}

function update_project_list() {
    push_cmd("get_project_list", JSON.stringify({
        'get': 1
    }));

    var processed_data = processor(send_cmd());
    PROJECT_LIST  = processed_data['get_project_list'];
    fill_project_list();	
}

function update_scenario_list() {
    var processed_data = {};

    push_cmd("get_scen_list", JSON.stringify({
        'get': 1
    }));

    processed_data = processor(send_cmd());

    SCENARIO_SELECT_LIST  = processed_data['get_scen_list'];

    fill_scenario_list();	
	
}

function get_featext() {
	alert( 'get_featext' );
	
}

function get_locked_status() {
    Feature_status(true);
    Scenario_status(true);
}

function Scenario_status(async) {
    var ret_val = new Object();
    push_cmd("get_scenario_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);
    } else {
        ret_val = processor(send_cmd(async), ret_val);
    }
    return ret_val['get_scenario_locked_status'];
}

function Feature_status(async) {
    var ret_val = new Object();
    push_cmd("get_feature_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);

    } else {
        ret_val = processor(send_cmd(async), ret_val);
    }
    return ret_val['get_feature_locked_status'];
}


function locked_status(table) {
    if (table['table'] == "FeatureID") {
        if (feature_is_locked(table['id'])) {
            FEATURE_LOCKED_BY_ME = false;
            $("a[href='#select_sentence']").css('display', 'none');
        } else {
            FEATURE_LOCKED_BY_ME = true;
            set_Feature_locked(table['id']);
            $("a[href='#select_sentence']").css('display', 'inline');
        }
    } else if (table['table'] == "ScenarioID") {
        if (scenario_is_locked(table['id'])) {
            SCENARIO_LOCKED_BY_ME = false;
            $("a[href='#select_sentence']").css('display', 'none');
        } else {
            SCENARIO_LOCKED_BY_ME = true;
            set_Scenario_locked(table['id']);
            $("a[href='#select_sentence']").css('display', 'inline');
        }
    }
}

function init_onclick() {
	var project_name,
	    proj,
		datas_from_server;
		
	$("#save_projects").click(function () {
		project_name = "Selected project: " + $("ul#project_list a.active").text();
		$("#act_project").text(project_name);
		push_cmd("get_template_list_by_projectid", JSON.stringify({'ProjectID': $("#project_list .selected").data("data").ProjectID }), fill_template_list);
		processor(send_cmd());
	});	
}

function get_template_projectname(project_name) {
	var processed_data = new Object();
	push_cmd("get_template_list_by_projectid", JSON.stringify({'ProjectName': project_name }));

    processed_data = processor(send_cmd());

	return processed_data['get_template_list_by_projectid'];		
}

function init_page() {
	var feature_id,
	    feature_name,
		login;

	init_resizable();
	init_onclick();
	
	if ( session ) {
	    $.each(['Scenario_list', 'Feature_list', 'Sentence_editor'], function(i, n){
	    	$('#' + n).show();
	    });
	
	    $.each(['Scenarios_in_Feature-cont'], function(i, n){
	    	$('#' + n).hide();
	    });
	
    	login_html( GetCookie('username') );
    	init_page_DB();
	    fill_feature_list();
		fill_scenario_list();
		fill_project_list();
	    sortable_li();
	
	    setInterval(function() {
	        get_locked_status();
	    }, 45000);
    } else {
    	login = create_button('login', login_, {}, "bootstrap");
        $.each(['Scenarios_in_Feature-cont', 'Scenario_list', 'Feature_list', 'Sentence_editor'], function(i, n){
        	$('#' + n).hide();
        });
    }
}

function open_feature () {
	feature_id = $('#feature_list a.selected').data('data').FeatureID;
	feature_name = $('#feature_list a.selected').data('data').Title;
	    	
	if (-1 == ACTUAL_FEATURE) {
        ACTUAL_FEATURE = feature_id;
        locked_status({
            'table': 'FeatureID',
            'id': ACTUAL_FEATURE
        });

    } else {

        if (FEATURE_LOCKED_BY_ME == true) {
            set_Feature_unlocked(ACTUAL_FEATURE);
            ACTUAL_FEATURE = feature_id;
            locked_status({
                'table': 'FeatureID',
                'id': ACTUAL_FEATURE
            });
        } else {
            ACTUAL_FEATURE = feature_id;
            locked_status({
                'table': 'FeatureID',
                'id': ACTUAL_FEATURE
            });
        }
    }
	modify_feature(this);    	
}

function add_scenario_to_feature() {
    var selected_scen_id   = $(this).data("data").ScenarioID;
    var li_number          = get_li_number_from_id("Scenarios_in_Feature");
    var selected_scen_name = $(this).data("data").Title;
    var li_id              = "scenario_in_feature" + li_number;

    $(this).toggleClass('selected');
    $(this).toggleClass('active');

	if ( ACTUAL_FEATURE == -1 || ( FEATURE_LOCKED_BY_ME == false ) ) {
		if( $(this).attr('class').match(/selected/) ) {
	        $('#add_new_scenario_input').val( selected_scen_name );
		
		} else {
			$('#add_new_scenario_input').val( '' );
		}

        $('#Alert_dialog').dialog({
	        width: 500,
	        title: 'Feature is locked or not selected!',
	        height: 150,
	        position: [600, 600],
	        buttons:
	        {
	            "Close": {
	            	text: 'Close',
	                click: function() {
	                    $(this).dialog("close");
	                }
	            }
	        }
	    });

	} else {
        add_new_scenario_to_feature({
            'feature_id'   : ACTUAL_FEATURE,
            'scenario_id'  : selected_scen_id,
            'scenario_data': selected_scen_name,
            'scen_infea_id': li_id,
            'position'     : li_number,
        });

        update_scenario_list_in_feature();
    }
}

function add_new_scenario_to_feature(ids) {
    push_cmd("add_scen_to_fea", JSON.stringify({
        'FeatureID' : ids['feature_id'],
        'ScenarioID': ids['scenario_id'],
        'Position'  : ids['position'],
    }));
    processor(send_cmd());
}

function get_li_number_from_id(id) {
    return document.getElementById(id).childNodes.length;
}

function get_feature_name() {
    for (var item in FEATURE_SELECT_LIST) {
        if (FEATURE_SELECT_LIST[item]['FeatureID'] == ACTUAL_FEATURE) {
            return FEATURE_SELECT_LIST[item]['Title'];
        }
    }
}

function set_Feature_locked(feature_id) {
    if (feature_id != -1) {
        push_cmd("Feature_is_locked", JSON.stringify({
            'FeatureID': feature_id
        }));
        processor(send_cmd());
    }
}

function set_Feature_unlocked(feature_id) {
    if (feature_id != -1) {
        push_cmd("Feature_is_unlocked", JSON.stringify({
            'FeatureID': feature_id
        }));
        processor(send_cmd())
    }
}

function sortable_li() {
    $(function() {
        $("ul.droptrue").sortable({
            connectWith: "ul",
            dropOnEmpty: true
        }).disableSelection();

        $("#recycle_for_sentences, #selected_sentence_sortable").sortable({
            connectWith: "ul",
            dropOnEmpty: true,
            stop: function(event, ui) {
                recycler(event, ui);
            }
        }).disableSelection();
    });

    $(function() {
        $("#selected_sentence_sortable_without_fea, #scenario_text_without_fea").sortable({
            connectWith: ".connectedSortable"
        }).disableSelection();
    });

    $(function() {
        $("#Scenarios_in_Feature").sortable();
        $("#Scenarios_in_Feature").disableSelection();
    });
}

function feature_is_locked(feature_id) {
    $("a[href='#select_sentence']").css('display', 'inline');
    var fea_ids = Feature_status(false);

    for (var item in fea_ids) {
        if (fea_ids[item]['FeatureID'] == feature_id) {
            return fea_ids[item]['LockedStatus'];
        }
    }
}

function Feature_status(async) {
    var ret_val = new Object();
    push_cmd("get_feature_locked_status", JSON.stringify({
        'get': '1'
    }));

    if (async) {
        send_cmd(async);

    } else {
        ret_val = processor(send_cmd(async));
    }
    return ret_val['get_feature_locked_status'];
}

function modify_feature(dom) {
    open_dialog_for_scenarios_in_feauture();
    update_scenario_list_in_feature();
}

function open_dialog_for_scenarios_in_feauture() {
	//delete_scen_from_fea_btn1 = create_button_as_img("del_scen_from_fea_btn_" + li_id, delete_scenario_from_fea_dialog, "Add scenario", "img/clear.png");
	
	if ( FEATURE_LOCKED_BY_ME == false ) {
		$('#Alert_dialog').dialog({
	        width: 500,
	        title: 'Feature is locked!',
	        height: 150,
	        position: [600, 600],
	        buttons:
	        {
	            "Close": {
	            	text: 'Close',
	                click: function() {
	                    $(this).dialog("close");
	                }
	            }
	        }
	    });

	} else {
		create_button('save_scenarios_to_feature', save_scenarios_to_feature, {}, "bootstrap");
	    //$('#get_feature_text').hide();

	    var ret_val = save_feature_file();
	    //create_link_for_DownloadFile( ret_val['Save_Feature'], 'get_feature_text');
	}
    document.getElementById("Scenarios_in_Feature_title").innerHTML = "Selected feature: " + $('#feature_list .selected').data('data').Title;
	create_button('close_feature', close_feature, {}, "bootstrap").onclick = close_feature;

}


function close_feature () {
    if (FEATURE_LOCKED_BY_ME == true) {
        set_Feature_unlocked(ACTUAL_FEATURE);
    }
    ACTUAL_FEATURE = -1;
    $("#Scenarios_in_Feature li").remove();
    $("#Scenarios_in_Feature-cont").hide();
    $('#feature_list .selected ').removeClass('selected');
    $('#feature_list .active ').removeClass('active');
}

//TODO: refactor
function update_scenario_list_in_feature() {
	var scenario_list_in_fea,
	    li_id,
		scenario_in_feature,
	    modify_scen,
	    scenario_id,
		scenario_name,
		scenario_data;
	if( $('#feature_list .selected').length == 0 ) {
		return;
	}
	
    scenario_list_in_fea = get_scen_list_by_feature();
    delete_scenariolist_in_feature_HTML();
	$('#Scenarios_in_Feature-cont').show();
    if (scenario_list_in_fea == null) {
		return 0;

    } else {
        for (var i = 0; i < scenario_list_in_fea.length; i++) {
        	scenario_list_in_fea[i].Position = i;
            li_id               = "scenario_in_feature" + i;
            scenario_in_feature = "scenario_in_feature" + i;

            $("#Scenarios_in_Feature").append(create_li({
                "id"    : li_id,
                'value' : scenario_list_in_fea[i]['ScenarioID'],
                'class' : "list-group-item"
            }));

            $("#" + li_id).append( create_span({ text :  scenario_list_in_fea[i]['ScenarioName'] }) );

            if ( FEATURE_LOCKED_BY_ME ) {
                delete_scen_from_fea_btn1 = create_button_as_img("del_scen_from_fea_btn_" + li_id, delete_scenario_from_fea_dialog, "Add scenario", "img/clear.png");
                edit_scen_from_fea_btn1 = create_button_as_img("edit_scen_from_fea_btn_" + li_id, edit_scenario, "Add scenario", "img/Edit-Document-icon.png");
                modify_scen = create_button_as_img("edit_scen_from_fea_btn_" + li_id, rename_scenario_HTML, "Add scenario", "img/update.png");

                $("#" + li_id).append(delete_scen_from_fea_btn1);
                $("#" + li_id).append(edit_scen_from_fea_btn1);
                $("#" + li_id).append(modify_scen);
                $("#" + li_id).data('data', scenario_list_in_fea[i]);
            }

        }
        $( "#Scenarios_in_Feature" ).sortable();
        $( "#Scenarios_in_Feature" ).disableSelection();
    }
}

function edit_scenario(DIALOG_WITHOUT_FEATURE) {
	alert('edit_scenario');
}

function rename_scenario_HTML() {
    $('#new_scenario_name').val( $('#' + this.id ).parent().find('span').html() );

    $('#RenameScenarioDialog').dialog({
        width: 500,
        title: "Please enter new, changed ScenarioName",
        height: 150,
        position: [600, 600],
        buttons:
        {
            "Confirm": {
            	text: 'Confirm',
                click: function() {
                    rename_scenario( $('#new_scenario_name').val(), this.id );
                    $('#'+this.id ).parent().find('span').html( $('#new_scenario_name').val() );
                    $(this).dialog("close");
                }
            },
            "Close": {
            	text: 'Close',
                click: function() {
                    $(this).dialog("close");
                }
            },
        }
    });
}

function rename_scenario(new_scenario_name, old_scenario_id) {
    push_cmd("rename_scenario", JSON.stringify({
        'ScenarioID': old_scenario_id,
        'NewScenarioName' : new_scenario_name
    }));
    processor(send_cmd());
}

function delete_scenariolist_in_feature_HTML() {
    $("#Scenarios_in_Feature li").remove();
}

function get_scen_list_by_feature() {
    push_cmd("get_scen_list_by_fea", JSON.stringify({
        'FeatureID': ACTUAL_FEATURE
    }));
    var ret_val = processor(send_cmd());
    return ret_val['get_scen_list_by_fea'];
}

/*
function create_link_for_DownloadFile () {
	alert('create_link_for_DownloadFile');
}
*/

function Are_you_sure_you_want_to_delete_scenario() {
    var selected_scen_id,
	    scenario_name,
	    num_of_feas;
	
	selected_scen_id = $('#scenario_list .active').data('data').ScenarioID;
    scenario_name    = $('#scenario_list .active').data('data').Title;
	num_of_feas      = get_feature_number_by_scen_id(selected_scen_id);
	
    if (num_of_feas > 0) {
		create_used_fealist();
        $("#Delete_scenario_from_features").dialog({
            width: 400,
            height: 400,
            position: [600, 600],
            buttons: {
                "Delete scenarios": {
                    text: 'Delete scenario',
                    click: function() {
                        delete_item_from_scenario_list(selected_scen_id);
						$(this).dialog("close");
                    }

                },

                "Cancel": {
                    text: 'Not now',
                    click: function() {
                        $(this).dialog("close");
                    }
                }
            }
        });
    } else {
        $("#Delete_scenario").dialog({
            width: 250,
            height: 50,
            position: [600, 600],
            buttons: {
                "Delete scenarios": {
                    text: 'Delete scenario',
                    click: function() {
                        delete_scenario();
                    }

                },

                "Cancel": {
                    text: 'Not now',
                    click: function() {
                        $(this).dialog("close");
                    }
                }
            }
        });
    }
}

function get_feature_number_by_scen_id(scenId) {
    push_cmd("get_feature_number_by_scen_id", JSON.stringify({
        'ScenarioID': scenId
    }));
    var ret_val = processor(send_cmd());

    return ret_val['get_feature_number_by_scen_id'][0].cnt;
}

function delete_item_from_scenario_list(scen_id) {
    push_cmd("delete_scen_from_fea", JSON.stringify({
        'ScenarioID': scen_id,
        'FeatureID' : $('#feas_by_scen .selected').map(function(i,j){return $(j).data('data').FeatureID}).get()
    }));
    processor(send_cmd());
    update_scenario_list_in_feature();
    $('#Delete_scenario_from_features').dialog("close");
}

function create_used_fealist() {
	push_cmd("get_features_by_scenario_id", JSON.stringify({
        'ScenarioID': $('#scenario_list .active').data('data').ScenarioID
    }));

	var ret_val      = processor(send_cmd());
    create_list_group('feas_by_scen', ret_val['get_features_by_scenario_id'], function(){
    	$(this).toggleClass('active');
    	$(this).toggleClass('selected');
    }, {}, {
    	class : 'list-group-item',
    	href  : '#'
    });

}

function delete_scenario() {
    push_cmd("clear_scen", JSON.stringify({
        'ScenarioID': $('#scenario_list .active').data('data').ScenarioID
    }));
    processor(send_cmd());

    //create_scen_list();
    update_scenario_list();
    update_scenario_list_in_feature();

    $("#Delete_scenario").dialog("close");
}

function save_scenarios_to_feature() {
    var scenarios = $("#Scenarios_in_Feature").find('li').map(function(i,j){return j.value;}).get();

    save_scenarios_in_feature({
        'feature_id': ACTUAL_FEATURE,
        'scenlist': scenarios,
    });
}

function save_scenarios_in_feature(Scenario_datas) {
    push_cmd("save_scenarios_to_feature", JSON.stringify({
        'FeatureID': Scenario_datas['feature_id'],
        'ScenarioList': Scenario_datas['scenlist']
    }));
    processor(send_cmd());
}

function check_selected_scenarios_for_database_saving() {
    var sentence_number = $("#Scenarios_in_Feature").children().length;
    var li_gherkin_list = $("#Scenarios_in_Feature").children();
    var scenario_in_feature = [];

    for (var i = 0; i < sentence_number; i++) {
        scenario_in_feature[i] = li_gherkin_list[i].value;
    }

    return scenario_in_feature;
}

function clear_feature_HTML() {
    var li_list = $("#Scenarios_in_Feature").children();
    li_list.remove();
}

function save_feature_file() {
    push_cmd("Save_Feature", JSON.stringify(  {
			'FeatureName'   : get_feature_name( ACTUAL_FEATURE )  ,
			'FeatureText'   : get_gherkin_text_by_feature()   ,
    } ) ) ;

    return processor( send_cmd() );
}

function get_gherkin_text_by_feature() {
	//alert('get_gherkin_text_by_feature');
}

function delete_scenario_from_fea_dialog() {
    var scenario_data = $('#' + this.id).parent().data('data');
    var row = $('#' + this.id).parent();
    $("#Are_you_sure").dialog({
        width: 500,
        height: 150,
        position: [600, 600],
        buttons:
        {
            "Delete scenario": {
                text: 'Delete scenario',
                click: function() {
                    $(this).dialog("close");
                    row.remove();
                    save_scenarios_to_feature();
                }
            },

            "Cancel": {
                text: 'Cancel',
                click: function() {
                    $(this).dialog("close");
                }
            }
        }
    });
    var scenario_name = scenario_data.ScenarioName;
    var selecte_fea_name = scenario_data.FeatureName;
    var delete_scenario_from_fea = " Are you sure you want to delete: " + scenario_data.ScenarioName + "scenario from" + scenario_data.FeatureName + "feature";
    document.getElementById("Are_you_sure").innerHTML = delete_scenario_from_fea;
}

function login_() {
    var username,
	    password,
		login;

    username= document.getElementById("username").value;
	password= document.getElementById("password").value;

	if (username && password) {
		var processed_data = {};

		push_cmd("LoginForm", JSON.stringify({
			'acc': username,
			'pwd': MD5(password),
		}));
	
     	processed_data = processor(send_cmd());
        login = processed_data['LoginForm'];
	    session = login.session;
		
		if ( login !== undefined ) {
			AddCookie("session", login.session);
			AddCookie("username", login.username);
			init_page();
		} else {
			$('#Alert_dialog').dialog({
		        width: 500,
		        title: 'Wrong user params',
		        height: 150,
		        position: [600, 600],
		        buttons:
		        {
		            "Close": {
		            	text: 'Close',
		                click: function() {
		                    $(this).dialog("close");
		                }
		            }
		        }
		    });
		};			
		
	}
	else {
	  $('div#loginResult').text("enter username and password");
	  $('div#loginResult').addClass("error");
	}
	$('div#loginResult').fadeIn();
	return false;
	
}

function login_html(username) {
	var header,
	    text,
		user,
		logout;
		
		text = "logged in as " + username;
	
	hide_login();
	
	user = document.getElementById("loggedin_user");
	$("#loggedin_user").show();
	$("#loggedin_user").text(text);
    logout = create_button_as_img("logout", logout_, "logout", "img/clear.png", document.getElementById("loggedin_user"));
    user.appendChild(logout);
}

function hide_login () {
	$(".wrapper").css("top", "0px");
    $(".right.pane").css("top", "0px");	

    $.each(['Scenario_list', 'Feature_list', 'Sentence_editor'], function(i, n){
    	$('#' + n).show();
    });
}

function show_login () {
	$(".wrapper").css("top", "110px");
    $(".right.pane").css("top", "110px");	

    $.each(['Scenarios_in_Feature-cont', 'Scenario_list', 'Feature_list', 'Sentence_editor'], function(i, n){
    	$('#' + n).hide();
    });
}

function logout_(node) {
	var logout,
	    myNode;
    var processed_data = {};
	
	push_cmd("Logout", JSON.stringify({
		'session_id': session,
	}));
	processed_data = processor(send_cmd());
	logout = processed_data['Logout'];		

	DeleteCookie( 'session' );
	
	$("#loggedin_user").hide();

	show_login();
	
	DeleteCookie( 'session' );
	session = null;
}

function init_resizable () {
		$(function () {
			$(".left.pane").resizable({
				handles: "n, s, e, w"
			});
			$(".right.pane").resizable({
				handles: "n, s, e, w"
			});
			$(".center.pane .inner .top").resizable({
				handles: "n, s, e, w"
			});				
			$(".center.pane .inner .bottom").resizable({
				handles: "n, s, e, w"
			});
			$('.modal-content').resizable({
				//alsoResize: ".modal-dialog",
				minHeight: 300,
				minWidth: 300
			});
			$('.modal-dialog').draggable();

			$('#myModal').on('show.bs.modal', function () {
				$(this).find('.modal-body').css({
					'max-height':'100%'
				});
			});		
		});			
}