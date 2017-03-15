

$(document).ready(function(){
	
	//显示登录的弹出框
	$('#login').modal({
		keyboard:false,
		backdrop:false,
		show:true,
	});

	//添加用户的事件
	$("#addUser").click(function(){
		 $("#center_tab").html("添加用户");
	});

	$("#userManager").click(function(){
		$("#center_tab").html("用户管理");	
	});

	//注册页显示提示框
	var tooltips = $( "[title]" ).tooltip({"placement":"right"});

	//flexigrid 表格
	$("#flex1").flexigrid({
			url: 'index.html',
			dataType: 'json',
			colModel : [
				{display: 'id', name : 'id', width : 40, sortable : true, align: 'center'},
				{display: 'username', name : 'username', width : 180, sortable : true, align: 'left'},
				{display: 'nickname', name : 'nickname', width : 120, sortable : true, align: 'left'},
				{display: 'email', name : 'email', width : 130, sortable : true, align: 'left', hide: true},
				{display: 'sex', name : 'sex', width : 90, sortable : true, align: 'left'}
			],
			buttons : [
				{name: '添加', bclass: 'add',onpress:test},
				{name: '删除', bclass: 'delete',onpress:test},
				{name: '编辑', bclass: 'edit'},
				{separator: true}
			],
			searchitems : [
				{display: 'id', name : 'id'},
				{display: 'name', name : 'name', isdefault: true}
			],
			sortname: "id",
			sortorder: "asc",
			usepager: true,
			title: '用户列表',
			useRp: true,
			rp: 15,
			showTableToggleBtn: true,
			width: "auto",
			height: 300
	}); 


});

function test(com, grid) {
    if (com == '删除') {
        confirm('Delete ' + $('.trSelected', grid).length + ' items?')
    } else if (com == '添加') {
        alert('Add New Item');
    }
}