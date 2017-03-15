<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jstl/core_rt" prefix="c" %>
<%@ taglib prefix="s" uri="http://www.springframework.org/tags/form"%> 
<!DOCTYPE html>
<html lang="en">
	<head>
		<title>用户登录</title>
		<meta charset="UTF-8" />
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<meta content="IE=edge,chrome=1" http-equiv="X-UA-Compatible">
    	<meta name="viewport" content="width=device-width, initial-scale=1.0">
    	<meta name="description" content="">
    	<meta name="author" content="">
		<link rel="stylesheet" href="<%=request.getContextPath()%>/resources/css/bootstrap/bootstrap.css"/>
		<script type="text/javascript" src="<%=request.getContextPath()%>/resources/js/jquery-1.7.2.js"></script>
		<script type="text/javascript" src="<%=request.getContextPath()%>/resources/js/bootstrap.min.js"></script>
		<script type="text/javascript" src="<%=request.getContextPath()%>/resources/js/login.js"></script>
		
		<!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    	<!--[if lt IE 9]>
      		<script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    	<![endif]-->
    	<script type="text/javascript">
				$(function(){
					$("#logins").click(function(){
						document.loginform.submit();
					});
				});
    	</script>
	</head>
	<body class="">
		<div class="navbar">
				<div class="navbar-inner">
					<a href="#" class="brand">Content Manager System</a>
					<ul class="nav pull-right">
						<li class=""><a href="#" id="regist">注册</a></li>
						<li class="divider-vertical"></li>
						<li class=""><a href="#">忘记密码</a></li>
					</ul>
				</div>
		</div>
		<div class="container">
			<div class="modal hide fade" id="login">
				<div class="modal-header">
					<h4>用户登录</h4>
				</div>
				<div class="modal-body">
					<s:form class="form-horizontal" method="post" action="login.do" modelAttribute="users" name="loginform">
							<div class="control-group">
									<label class="control-label">用户名</label>
									<div class="controls">
										<div class="input-prepend">
											<span class="add-on"><i class="icon-user"></i></span>
											<s:input path="loginname" placeholder="loginname" title="请输入您的登录名"/>
										</div>
									</div>
							</div>
							<div class="control-group">
									<label class="control-label">密码</label>
									<div class="controls">
										<div class="input-prepend">
											<span class="add-on"><i class="icon-lock"></i></span>
											<s:password path="password" placeholder="password" title="请输入您的登录名"/>
										</div>
									</div>
							</div>
							<div class="control-group">
									<div class="controls">
										<label class="remember-me"><input type="checkbox"><small>记住用户名</small></label>
									</div>
							</div>
					 </s:form>
				</div>
				<div class="modal-footer">
					<button type="button" class="btn btn-primary" id="logins">登录</button>
				</div>
			</div>
		</div>
	</body>
</html>