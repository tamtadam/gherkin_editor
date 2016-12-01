function init_page_DB() {
    var processed_data = new Object();

    push_cmd("get_feature_list", JSON.stringify({'get': 1 }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({'get': 1 }));
    processed_data = processor(send_cmd());

    FEATURE_SELECT_LIST  = processed_data['get_feature_list'];
    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
}


function fill_feature_list()
{
	var TestType = new Array();
	var SortedLists = new Array();
    var feature_list = create_select_list('feature_list_name', 'feature_list', FEATURE_SELECT_LIST, null, FEATURE_PREFIX);

    document.getElementById("feature_list_container").innerHTML = "";
    document.getElementById("feature_list_container").appendChild(feature_list);
    set_features_to_empty();
    set_css_for_none_empty_feature_list();

    var delete_item_from_feature_list_btn  = create_button_as_img('delete_item_from_feature_list_btn', Are_you_sure_you_want_to_delete_feature, "Add sentence", "img/clear.png");
    var add_item_to_feature_list_btn       = create_button_as_img('add_item_to_feature_list_btn', add_new_feature_to_feature_list, "Add item", "img/add.png");

}

function create_feature_dialog() {
	$( "#Feature_list" ).tabs();
    var feature_input;
    var feature_list_title = "";
    feature_list_title = "Feature list";

    $("#Feature_list").dialog({
        width: 500,
        height: 400,
        autoOpen: false,
        position: [0, 100],
		buttons:
        {
            "new_feature_input": {
                id: 'add_new_feature_input_btn',
            },
        }
    }).dialog("open");

	feature_input = create_input("add_new_feature_input");
	document.getElementById("add_new_feature_input_btn").appendChild(feature_input);
	
	document.getElementById("add_new_feature_input_btn").childNodes[0].className = "";
}

function set_css_for_none_empty_feature_list() {
    for (var item in FEATURE_SCENARIO_IDS) {
        var fea_selectlist = document.getElementById(FEATURE_PREFIX + FEATURE_SCENARIO_IDS[item]['FeatureID']);
        fea_selectlist.setAttribute('class', 'not_empty');
    }
}

function set_features_to_empty() {
    var fea_selectlist;
    var id;

    for (var item in FEATURE_SELECT_LIST) {
        id = FEATURE_PREFIX + FEATURE_SELECT_LIST[item]['FeatureID'];
        fea_selectlist = document.getElementById(id);
        fea_selectlist.setAttribute('class', 'empty');
    }
}

function add_new_feature_to_feature_list() {
    var typed_text = document.getElementById('add_new_feature_input');
    var feature_name = typed_text.value;

    $('#add_new_feature_input').val('');

    push_cmd("add_new_fea_to_fealist", JSON.stringify({
        'Title': feature_name
    }));
    processor(send_cmd());

    update_feature_list();
}

function Are_you_sure_you_want_to_delete_feature() {
    var feature_name = get_feature_name_by_id( document.getElementById("feature_list").value );

    var are_you_sure_title = "";
    are_you_sure_title = "Are you sure do you want" + "\n" + "to delete: " + feature_name + " feature?";

    $("#Are_you_sure").dialog({
        width: 800,
        height: 200,
        position: [600, 600],
        buttons:
        {
            "Delete scenarios": {
                text: 'Delete feature',
                click: function() {
                    $(this).dialog("close");
                    var feature_id = document.getElementById("feature_list").value;
                    delete_item_from_feature_list( feature_id );
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

    $('#Are_you_sure').dialog('option', 'title', are_you_sure_title);
}

function delete_item_from_feature_list( feature_id ) {
    clear_feature( feature_id );
    update_feature_list();
}

function clear_feature(selected_fea_id) {
    clear_feature_HTML();
    push_cmd("empty_feature", JSON.stringify({
        'FeatureID': selected_fea_id
    }));
    processor(send_cmd());
}

function update_feature_list() {
    var processed_data = new Object();

    push_cmd("get_feature_list", JSON.stringify({
        'get': 1
    }));
    push_cmd("get_feature_scenario_datas", JSON.stringify({
        'get': 1
    }));
    processed_data = processor(send_cmd());

    FEATURE_SCENARIO_IDS = processed_data['get_feature_scenario_datas'];
    FEATURE_SELECT_LIST  = processed_data['get_feature_list'];

    fill_feature_list();
}

function get_feature_name_by_id(selected_fea_id) {
    for (var item in FEATURE_SELECT_LIST) {
        if (FEATURE_SELECT_LIST[item]['FeatureID'] == selected_fea_id) {
        	return FEATURE_SELECT_LIST[item]['Title'];
        }
    }
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

function init_page()
{
	var feature_id, feature_name;
	
    init_page_DB();
    fill_feature_list();
    create_feature_dialog();

    $("#Test").show();
    $("#locked_status").show();

    $(function() {
        $("#edit_scena_with_feature").tabs();
    });

    sortable_li();

    document.getElementById('feature_list').ondblclick = function() {
    	feature_id = document.getElementById("feature_list").value;
    	feature_name = get_feature_name(feature_id);
    	
    	check_dialog_is_open("Feature-input");
    	progress_bar( "Get scenarios to " + feature_name + " feature - D O W N L O A D !!!");
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
    	setTimeout( modify_feature, 50 );
    	
        $("#picture_viewer").dialog("close");
    };

    setInterval(function() {
        get_locked_status();
    }, 10000);
}

function get_feature_name() {
    for (var item in FEATURE_SELECT_LIST) {
        if (FEATURE_SELECT_LIST[item]['FeatureID'] == ACTUAL_FEATURE) {
            return FEATURE_SELECT_LIST[item]['Title'];
        }
    }
}

function check_dialog_is_open(id){
	if( $('#Feature-input').hasClass('ui-dialog-content') ){
		if ($('#Feature-input').dialog('isOpen') === true) {
			$('#Feature-input').dialog('close')
		} else {
            // DO NOTHING
		}
	}else{
		// DO NOTHING
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
        ret_val = processor(send_cmd(async), ret_val);
    }
    return ret_val['get_feature_locked_status'];
}

function modify_feature() {
    open_dialog_for_scenarios_in_feauture();
    update_scenario_list_in_feature();
    $("#dialog").dialog("close");
}

function open_dialog_for_scenarios_in_feauture() {
	alert('open_dialog_for_scenarios_in_feauture');
}


function update_scenario_list_in_feature() {
	alert('update_scenario_list_in_feature');
}
