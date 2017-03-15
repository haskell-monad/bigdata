<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c"%>
<%@ taglib prefix="s" uri="http://www.springframework.org/tags/form"%>
<!DOCTYPE html>
<html lang="en">
<head>
<title>安装页面</title>
<meta charset="UTF-8" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta content="IE=edge,chrome=1" http-equiv="X-UA-Compatible">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="">
<meta name="author" content="">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/bootstrap.min.css" />
<link href="<%=request.getContextPath()%>/css/smart_wizard.css" rel="stylesheet" type="text/css">
<link href="<%=request.getContextPath()%>/css/select2.css" rel="stylesheet"/>
<link href="<%=request.getContextPath()%>/css/grumble.min.css" rel="stylesheet"/>    

<script type="text/javascript" src="<%=request.getContextPath()%>/js/jquery-1.7.2.js"></script>
<script type="text/javascript" src="<%=request.getContextPath()%>/js/bootstrap.min.js"></script>
<script type="text/javascript" src="<%=request.getContextPath()%>/js/jquery.smartWizard-2.0.min.js"></script>
<script src="<%=request.getContextPath()%>/js/select2.js"></script>
<script src="<%=request.getContextPath()%>/js/select2_locale_zh-CN.js"></script>
<script src="<%=request.getContextPath()%>/js/Bubble.js"></script>
<script src="<%=request.getContextPath()%>/js/jquery.grumble.min.js"></script>
<script src="<%=request.getContextPath()%>/js/jtopo-0.4.8-min.js"></script>



<!-- Le HTML5 shim, for IE6-8 support of HTML5 elements 
http://memory.blog.51cto.com/6054201/1030049
-->
<!--[if lt IE 9]>
      		<script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    	<![endif]-->
<script type="text/javascript">
	$(document).ready(function() {
		
		$('#wizard').smartWizard({
			transitionEffect:'slideleft',
			onLeaveStep:leaveStepCallback,
			onFinish:onFinishCallback,
			onShowStep:showStepCallback,
			enableFinishButton:true
		});
		
		//进入到某个步骤时的回调函数
		function showStepCallback(obj){
			var step_num= obj.attr('rel');
			$("a.buttonFinish").addClass("buttonDisabled");
			switch (step_num) {
				case '1':
					break;
				case '2':
					$.ajax({
						   type: "get",
						   url: "<%=request.getContextPath()%>/install/show.do",
						   dataType:"text",
						   data: "",
						   success: function(returnData){
							  var data = eval("("+returnData+")");
							  if(data.rtState==0){
								   $("#table").find("tr:gt(0)").remove();
								   for(var i =0;i<data.rtData.length;i++){
									   	var html = "<tr><td>"+data.rtData[i].ip+"</td><td>"+data.rtData[i].port+"</td><td>"+data.rtData[i].user+"</td><td>"+data.rtData[i].nodetype+"</td><td>"+data.rtData[i].nodename+"</td><td id=tr_del value="+data.rtData[i].id+" style='cursor:pointer;'>删除</td></tr>";
									   	$("#nodename").append("<option value="+data.rtData[i].id+">"+data.rtData[i].name+"</option>");
									   	$("#table").append(html);
								   }
							  }
						   }
					});	
					break;
				case '3':
					var src = "<%=request.getContextPath()%>/install/step.do";
					$("#step3_iframe").attr("src",src);
					$("div.actionBar").append('<a href="<%=request.getContextPath()%>/install/step.do"  target="_blank" class="buttonNext showbig">全屏展示</a>');
					break;
				case '4':
					$("#install_state").text("开始安装...");
					start_install();
					break;
				default:
					break;
			}
		}
		
		//离开当前步骤时的回调函数
		function leaveStepCallback(obj){
			var step_num= obj.attr('rel'); 
			switch (step_num) {
				case '1':
					return true;
				case '2':
					if($("#table").find("tr").length < 2){
						alert("请添加配置信息!");
						return false;
					}	
					return true;
				case '3':
					$("div.actionBar").find("a.showbig").remove();
					return true;
				case '4':
					$("#install_state").text("正在安装中...");
					return true;
				default:
					return true;
			}
		}
		
		function onFinishCallback() {
			var $msg = $("#install_state").text();
			if($msg == '安装成功'){
				$('#wizard').smartWizard('showMessage', '安装成功');
				//window.location.href = "";
			}else if($msg == '安装失败'){
				window.location.href = "<%=request.getContextPath()%>/install/index.do";
			}
			//$('#wizard').smartWizard('showMessage', 'Finish Clicked');
		}
		
		//开始安装
		function start_install(){
			$.ajax({
   				 type: "get",
   				 url: "<%=request.getContextPath()%>/install/install.do",
   				 dataType: "text",
   				 data: {},
   				 success: function(returnData){
   					var data = eval("("+returnData+")");
   					$("#step-4_div").find("p").remove();
   					for(var i = 0;i<data.rtData.length;i++){
   						$("#step-4_div").append("<p>"+data.rtData[i].datas+"</p>");
   					}
   					//如果是-1说明hadoop安装还没有结束 0为执行成功 其他为失败
   					if(data.rtMsg == 'RUNNING'){
   						setTimeout('start_install()', 10000);    //10秒更新
   					}else if(data.rtMsg=='INSTALL_SUCCESS'){
   						$("#install_state").text("安装成功");
   						//$('#wizard').smartWizard('showMessage', '安装成功');
   						$("a.buttonFinish").removeClass("buttonDisabled");
   					}else if(data.rtMsg=='INSTALL_FAIL'){
   						$("#install_state").text("安装失败");
   						//$('#wizard').smartWizard('showMessage', '安装失败');
   						$("a.buttonFinish").removeClass("buttonDisabled");
   					}
   				 }
   			})
		}
		
		$("#nodetype").select2({
			 placeholder: "请选择应用名称",
			 allowClear: true
		});
		$("#nodename").select2({
			 placeholder: "请选择服务名称",
			 allowClear: true
		});

		$("#nodetype").change(function(){
			var pid = $("#nodetype").val();
			if(pid != null && pid != ''){
				 $.ajax({
					   type: "get",
					   url: "<%=request.getContextPath()%>/install/findNodeType.do",
					   dataType:"text",
					   data: {pid:pid},
					   success: function(returnData){
						   var data=eval("("+returnData+")");
						   $("#nodename").find("option:gt(0)").remove();
						   if(data.rtState==0){
							   for(var i =0;i<data.rtData.length;i++){
								   $("#nodename").append("<option value="+data.rtData[i].id+">"+data.rtData[i].name+"</option>");
							   }
						    }
					   }
				 });
			}else{
				$("#nodename").find("option:gt(0)").remove();
			}
		})
		
		$("#add").click(function(){
			var ip = $("#ip").val();
			var port = $("#port").val();
			var user = $("#user").val();
			var pass = $("#pass").val();
			var pid = $("#nodetype").val();
			var id = $("#nodename").val();
			var nodetype = $("#nodetype option:selected").text();
			var nodename = $("#nodename option:selected").text();
			if(ip == null || ip ==""){
				$("#ip").focus();
				return false;
			}else if(port == null || port ==""){
				$("#port").focus();
				return false;
			}else if(user == null || user ==""){
				$("#user").focus();
				return false;
			}else if(pass == null || pass ==""){
				$("#pass").focus();
				return false;
			}else if(pid == null || pid ==""){
				alert("请选择应用名称");
				return false;
			}else if(id == null || id ==""){
				alert("请选择服务名称");
				return false;
			}else{
				 $.ajax({
					   type: "post",
					   url: "<%=request.getContextPath()%>/install/add.do",
					   dataType:"text",
					   data: {ip:ip,port:port,user:user,pass:pass,id:id,pid:pid,nodetype:nodetype,nodename:nodename},
					   success: function(returnData){
						    var data = eval("("+returnData+")");
						    if(data.rtState==0){
						       var html = "";
						       $("#table").find("tr:gt(0)").remove();
							   for(var i =0;i<data.rtData.length;i++){
								   html = "<tr><td>"+data.rtData[i].ip+"</td><td>"+data.rtData[i].port+"</td><td>"+data.rtData[i].user+"</td><td>"+data.rtData[i].nodetype+"</td><td>"+data.rtData[i].nodename+"</td><td id=tr_del value="+data.rtData[i].id+" style='cursor:pointer;'>删除</td></tr>";
								   $("#table").append(html);
							   }
						    }
					   		$("#ip").val("");
							$("#port").val("");
							$("#user").val("");
							$("#pass").val("");
							$("#nodetype").find("option:eq(0)").attr("selected",true);
							$("#nodename").find("option:gt(0)").remove();
					   }
				});
			}
		})
		 //删除tr事件
		 $("td[id=tr_del]").live('click',function(){
			 var id = $(this).attr("value");
			 $.ajax({
				   type: "POST",
				   url: "<%=request.getContextPath()%>/install/del.do",
				   dataType:"text",
				   data: {id:id},
				   success: function(returnData){
					  var data = eval("("+returnData+")");
					  if(data.rtState==0){
						   $("#table").find("tr:gt(0)").remove();
						   for(var i =0;i<data.rtData.length;i++){
							   	var html = "<tr><td>"+data.rtData[i].ip+"</td><td>"+data.rtData[i].port+"</td><td>"+data.rtData[i].user+"</td><td>"+data.rtData[i].nodetype+"</td><td>"+data.rtData[i].nodename+"</td><td id=tr_del value="+data.rtData[i].id+" style='cursor:pointer;'>删除</td></tr>";
							   	$("#nodename").append("<option value="+data.rtData[i].id+">"+data.rtData[i].name+"</option>");
							   	$("#table").append(html);
						   }
					  }
				   }
			});
		 })
		 $('#ip').focus(function(e){
				var $me = $(this), interval;
				
				e.preventDefault();
				
				$me.grumble(
					{
						angle: 130,
						text: 'www[1-10].baidu.com - www2.baidu.com',
						type: 'alt-', 
						distance: 50,
						hideOnClick: true,
						onShow: function(){
							var angle = 130, dir = 1;
							interval = setInterval(function(){
								(angle > 220 ? (dir=-1, angle--) : ( angle < 130 ? (dir=1, angle++) : angle+=dir));
								$me.grumble('adjust',{angle: angle});
							},25);
						},
						onHide: function(){
							clearInterval(interval);
						}
					}
				);
			});
	});
</script>
</head>
<body class="">
	<div class="container-fluid">
		<div class="row-fluid">
			<div class="span12">
			
			</div>
			<div class="span12">
				<div id="wizard" class="swMain">
					<ul>
						<li>
							<a href="#step-1">
								<span class="stepNumber">1</span>
								<span class="stepDesc">
									步骤一<br /> 
									<small>安装许可协议</small>
								</span>
							</a>
						</li>
						<li><a href="#step-2"><span class="stepNumber">2</span><span
								class="stepDesc">步骤二<br /> <small>安装信息配置</small></span></a></li>
						<li><a href="#step-3"><span class="stepNumber">3</span><span
								class="stepDesc">步骤三<br /> <small>安装信息拓扑</small></span></a></li>
						<li><a href="#step-4"><span class="stepNumber">4</span><span
								class="stepDesc">步骤四<br /> <small id="install_state">开始安装</small></span></a></li>
					</ul>
					<div id="step-1" style="height:470px">
						<h2 class="StepTitle">欢迎使用BigData！</h2>
						<p>请务必认真阅读和理解本《软件许可使用协议》（以下简称《协议》）中规定的所有权利和限制。除非您接受本《协议》条款，否则您无权下载、安装或使用本"软件"及其相关服务。您一旦安装、复制、下载、访问或以其它方式使用本软件产品，将视为对本《协议》的接受，即表示您同意接受本《协议》各项条款的约束。如果您不同意本《协议》中的条款，请不要安装、复制或使用本软件。
                         </p>
						<p>1.权利声明</p>
						<p>		1.1本“软件”的一切知识产权，以及与"软件"相关的所有信息内容，包括但不限于：文字表述及其组合、图标、图饰、图像、图表、色彩、界面设计、版面框架、有关数据、附加程序、印刷材料或电子文档等均为XX公司和McAfee公司所有，受著作权法和国际著作权条约以及其他知识产权法律法规的保护。</p>
						<p>2.许可范围</p>
                        <p>		2.1下载、安装和使用：本软件为免费软件，用户可以非商业性、无限制数量地下载、安装及使用本软件。</p>
                        <p>		2.2复制、分发和传播：用户可以非商业性、无限制数量地复制、分发和传播本软件产品。但必须保证每一份复制、分发和传播都是完整和真实的,包括所有有关本软件产品的软件、电子文档,版权和商标，亦包括本协议。</p>
                        <p>3.权利限制</p>
                        <p>		3.1禁止反向工程、反向编译和反向汇编：用户不得对本软件产品进行反向工程（ReverseEngineer）、反向编译（Decompile）或反向汇编（Disassemble），同时不得改动编译在程序文件内部的任何资源。除法律、法规明文规定允许上述活动外，用户必须遵守此协议限制。</p>
                        <p>		3.2组件分割:本软件产品是作为一个单一产品而被授予许可使用,用户不得将各个部分拆分用于其它目的。</p>
                        <p>		3.3个别授权:如需进行商业性的销售、复制、分发，包括但不限于软件销售、预装、捆绑等，必须获得XX的书面授权和许可。</p>
                        <p>		3.4保留权利：本协议未明示授权的其他一切权利仍归XX所有，用户使用其他权利时必须获得XX的书面同意。</p>
                        <p>4.用户使用须知</p>
                        <p>5.其他条款
                        5.1如果本协议中的任何条款无论因何种原因完全或部分无效或不具有执行力，或违反任何适用的法律，则该条款被视为删除，但本协议的其余条款仍应有效并且有约束力。
                        5.2XX有权随时根据有关法律、法规的变化以及公司经营状况和经营策略的调整等修改本协议。修改后的协议会在XX网站上公布，并随附于新版本软件。当发生有关争议时，以最新的协议文本为准。如果不同意改动的内容，用户可以自行删除本软件。如果用户继续使用本软件，则视为您接受本协议的变动。
                        5.3本协议的一切解释权与修改权归XX。</p>
					</div>
					<div id="step-2" style="height:470px">
						  <h2 class="StepTitle">Step 2 Content</h2>
						  <div class="container">
								<!--左侧菜单start-->
								<div class="span12">
									<div class="container">
										<div class="span4">
											<label for="ip">IP</label> 
											<input type="text" id="ip" value="192.168.0.0" placeholder="192.168.0.0" class="form-control input-hg" /> 
											<label for="user">User</label>
											<input type="text" id="user" value="root" placeholder="root" class="form-control" /> 
										</div>
										<div class="span4">
											<label for="port">PORT</label>
											<input type="text" id="port" value="22" placeholder="22" class="form-control" /> 
											<label for="pass">Pass</label> 
											<input type="password" id="pass" value="" placeholder="password" class="form-control" /> 
										</div>
										<div class="span4">
											<label for="nodetype">NodeType</label>
											<select id="nodetype" class="populate placeholder select2-offscreen" style="width:200px" tabindex="-1" title="Placeholders">
											    <option></option>
											    <c:forEach items="${nodeTypes}" var="obj">
											    	<option value="${obj.id}">${obj.name}</option>
											    </c:forEach>
											</select>	
											<br/><br/>
											<label for="nodename">NodeName</label>
											<select id="nodename" class="populate placeholder select2-offscreen" style="width:200px" tabindex="-1" title="Placeholders">
											    <option></option>
											</select>
											<button id="add" class="btn btn-primary btn-wide">
											  添加
											</button>
										</div>
									</div>
								</div>
								<!--ssss-->
						  		<div class="span12" style="height:310px; overflow:scroll;">
						  			<table id="table" class="table table-hover" align="center">
						  				<tr class="info">
						  					<td>IP</td>
						  					<td>PORT</td>
						  					<td>User</td>
						  					<td>NodeType</td>
						  					<td>NodeName</td>
						  					<td>Operation</td>
						  				</tr>
									</table>	
						  		</div>
						  </div>
					</div>
					<div id="step-3" style="height:470px">
						<h2 class="StepTitle">Step 3 Content</h2>
						<div style="overflow-x:hidden;overflow-y:scroll;width:960px;height:440px;">
							<iframe id="step3_iframe" width="2000px" height="1000px"></iframe>
						</div>
					</div>
					<div id="step-4" style="height:470px">
						<h2 class="StepTitle">Step 4 Content</h2>
						<div style="overflow-x:hidden;overflow-y:scroll;width:960px;height:440px;" id="step-4_div">
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>

</body>
</html>